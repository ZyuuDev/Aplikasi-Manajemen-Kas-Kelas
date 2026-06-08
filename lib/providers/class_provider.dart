import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_info.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../models/expense.dart';
import '../models/special_collection.dart';

class ClassState {
  final ClassInfo? classInfo;
  final List<Student> students;
  final List<ExpenseRecord> expenses;
  final List<SpecialCollection> specialCollections;
  final bool isLoading;
  final String? error;

  ClassState({
    this.classInfo,
    this.students = const [],
    this.expenses = const [],
    this.specialCollections = const [],
    this.isLoading = false,
    this.error,
  });

  ClassState copyWith({
    ClassInfo? classInfo,
    List<Student>? students,
    List<ExpenseRecord>? expenses,
    List<SpecialCollection>? specialCollections,
    bool? isLoading,
    String? error,
  }) {
    return ClassState(
      classInfo: classInfo ?? this.classInfo,
      students: students ?? this.students,
      expenses: expenses ?? this.expenses,
      specialCollections: specialCollections ?? this.specialCollections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Core metrics calculations
  int get elapsedWeeks {
    if (classInfo == null) return 0;
    final start = DateTime(
      classInfo!.semesterStartDate.year,
      classInfo!.semesterStartDate.month,
      classInfo!.semesterStartDate.day,
    );
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);

    if (current.isBefore(start)) return 0;
    final diffDays = current.difference(start).inDays;
    return (diffDays / 7).floor() + 1;
  }

  int get totalIncome => students.fold(0, (sum, std) => sum + std.totalPaid);

  int get totalExpense => expenses.fold(0, (sum, exp) => sum + exp.amount);

  int get liveBalance => totalIncome - totalExpense;

  int get totalDebt {
    if (classInfo == null) return 0;
    final weeks = elapsedWeeks;
    return students.fold(0, (sum, std) {
      final expected = weeks * classInfo!.weeklyFee;
      final debt = expected - std.totalPaid;
      return sum + (debt > 0 ? debt : 0);
    });
  }

  int getStudentDebt(Student student) {
    if (classInfo == null) return 0;
    final expected = elapsedWeeks * classInfo!.weeklyFee;
    final debt = expected - student.totalPaid;
    return debt > 0 ? debt : 0;
  }

  int getStudentDebtWeeks(Student student) {
    if (classInfo == null) return 0;
    final debt = getStudentDebt(student);
    if (debt <= 0) return 0;
    return (debt / classInfo!.weeklyFee).ceil();
  }
}

class ClassNotifier extends StateNotifier<ClassState> {
  ClassNotifier() : super(ClassState(isLoading: false)) {
    // Auto load data if user session exists
    if (_supabase.auth.currentUser != null) {
      loadClassData();
    }
  }

  final _supabase = Supabase.instance.client;

  Future<void> loadClassData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'User tidak masuk.');
        return;
      }

      // 1. Fetch class info
      final classData = await _supabase
          .from('classes')
          .select('*')
          .eq('treasurer_id', user.id)
          .maybeSingle();

      if (classData == null) {
        state = state.copyWith(isLoading: false, error: 'Kelas tidak ditemukan untuk bendahara ini.');
        return;
      }

      final classId = classData['id'] as String;

      // 2. Fetch active academic year
      final academicData = await _supabase
          .from('academic_years')
          .select('*')
          .eq('class_id', classId)
          .eq('is_active', true)
          .maybeSingle();

      // 3. Fetch students with nested transactions
      final List<dynamic> studentsData = await _supabase
          .from('students')
          .select('*, transactions(*)')
          .eq('class_id', classId)
          .eq('is_active', true);

      // 4. Fetch expenses
      final List<dynamic> expensesData = await _supabase
          .from('transactions')
          .select('*')
          .eq('class_id', classId)
          .eq('type', 'EXPENSE')
          .order('date', ascending: false);

      final classInfo = ClassInfo(
        id: classId,
        name: classData['name'] as String,
        slug: classData['slug'] as String,
        weeklyFee: classData['weekly_fee'] as int,
        semesterStartDate: DateTime.parse(classData['semester_start_date'] as String),
        academicYear: academicData != null ? academicData['name'] as String : 'Semester Aktif',
        semester: 1, // Default semester representation
      );

      // Map students
      final students = studentsData.map<Student>((std) {
        final txs = std['transactions'] as List<dynamic>? ?? [];
        final payments = txs
            .where((tx) => tx['type'] == 'INCOME')
            .map<PaymentRecord>((tx) => PaymentRecord(
                  id: tx['id'] as String,
                  studentId: tx['student_id'] as String,
                  amount: tx['amount'] as int,
                  date: DateTime.parse(tx['date'] as String),
                ))
            .toList();

        final totalPaid = payments.fold<int>(0, (sum, p) => sum + p.amount);

        return Student(
          id: std['id'] as String,
          name: std['name'] as String,
          nis: std['nis'] as String,
          classId: classId,
          totalPaid: totalPaid,
          payments: payments,
        );
      }).toList();

      // Map expenses
      final expenses = expensesData.map<ExpenseRecord>((exp) {
        return ExpenseRecord(
          id: exp['id'] as String,
          title: exp['description'] as String,
          description: exp['description'] as String,
          amount: exp['amount'] as int,
          date: DateTime.parse(exp['date'] as String),
          category: exp['category'] as String? ?? 'Lainnya',
          receiptUrl: exp['receipt_url'] as String?,
        );
      }).toList();

      // 5. Fetch special collections
      final List<dynamic> collectionsData = await _supabase
          .from('special_collections')
          .select('*')
          .eq('class_id', classId)
          .order('created_at', ascending: false);

      // 6. Fetch special collection payments
      final List<dynamic> collectionPaymentsData = collectionsData.isNotEmpty
          ? await _supabase
              .from('special_collection_payments')
              .select('collection_id, student_id')
              .inFilter(
                'collection_id',
                collectionsData.map((c) => c['id'] as String).toList(),
              )
          : [];

      // Map collection_id -> list of paid student IDs
      final Map<String, List<String>> paymentsByCollection = {};
      for (final p in collectionPaymentsData) {
        final cid = p['collection_id'] as String;
        final sid = p['student_id'] as String;
        paymentsByCollection.putIfAbsent(cid, () => []).add(sid);
      }

      final specialCollections = collectionsData.map<SpecialCollection>((c) {
        final paidIds = paymentsByCollection[c['id'] as String] ?? [];
        return SpecialCollection.fromJson(c).withPayments(paidIds);
      }).toList();

      state = ClassState(
        classInfo: classInfo,
        students: students,
        expenses: expenses,
        specialCollections: specialCollections,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Special Collections ──────────────────────────────────────────────

  // Action: Create a new special collection
  Future<void> createSpecialCollection({
    required String name,
    required int amount,
    String? description,
  }) async {
    final classId = state.classInfo?.id;
    if (classId == null) return;

    try {
      state = state.copyWith(isLoading: true);

      // Get active academic_year_id
      final academicData = await _supabase
          .from('academic_years')
          .select('id')
          .eq('class_id', classId)
          .eq('is_active', true)
          .maybeSingle();

      await _supabase.from('special_collections').insert({
        'class_id': classId,
        'academic_year_id': academicData?['id'],
        'name': name,
        'amount': amount,
        'description': description,
        'created_by': _supabase.auth.currentUser!.id,
      });

      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Save/sync payment status for a collection (replaces all payments)
  Future<void> updateSpecialCollectionPayments({
    required String collectionId,
    required List<String> paidStudentIds,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      // Delete all existing payments for this collection
      await _supabase
          .from('special_collection_payments')
          .delete()
          .eq('collection_id', collectionId);

      // Insert new payments for all checked students
      if (paidStudentIds.isNotEmpty) {
        final rows = paidStudentIds
            .map((sid) => {
                  'collection_id': collectionId,
                  'student_id': sid,
                  'created_by': _supabase.auth.currentUser!.id,
                })
            .toList();
        await _supabase.from('special_collection_payments').insert(rows);
      }

      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Delete a special collection (and cascade its payments)
  Future<void> deleteSpecialCollection(String collectionId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _supabase
          .from('special_collections')
          .delete()
          .eq('id', collectionId);
      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> addStudent(String name, String nis) async {
    final classId = state.classInfo?.id;
    if (classId == null) return;

    try {
      state = state.copyWith(isLoading: true);
      
      final response = await _supabase
          .from('students')
          .insert({
            'class_id': classId,
            'name': name,
            'nis': nis,
            'is_active': true,
          })
          .select()
          .single();

      final newStudent = Student(
        id: response['id'] as String,
        name: response['name'] as String,
        nis: response['nis'] as String,
        classId: classId,
        totalPaid: 0,
        payments: [],
      );

      state = ClassState(
        classInfo: state.classInfo,
        students: [...state.students, newStudent],
        expenses: state.expenses,
        specialCollections: state.specialCollections,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Add payment batch
  Future<void> addPaymentBatch(List<String> studentIds, int amount) async {
    final classId = state.classInfo?.id;
    if (classId == null) return;

    try {
      state = state.copyWith(isLoading: true);
      
      final activeYear = await _supabase
          .from('academic_years')
          .select('id')
          .eq('class_id', classId)
          .eq('is_active', true)
          .maybeSingle();
      
      final academicYearId = activeYear?['id'] as String?;
      final user = _supabase.auth.currentUser;

      final inserts = studentIds.map((studentId) => {
        'class_id': classId,
        'academic_year_id': academicYearId,
        'type': 'INCOME',
        'amount': amount,
        'description': 'Iuran Kas',
        'student_id': studentId,
        'created_by': user?.id,
        'date': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase.from('transactions').insert(inserts);

      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Add expense with receipt upload
  Future<void> addExpense({
    required String title,
    required String description,
    required int amount,
    required String category,
    String? receiptUrl,
    File? receiptImageFile,
  }) async {
    final classId = state.classInfo?.id;
    if (classId == null) return;

    try {
      state = state.copyWith(isLoading: true);
      
      final activeYear = await _supabase
          .from('academic_years')
          .select('id')
          .eq('class_id', classId)
          .eq('is_active', true)
          .maybeSingle();
      
      final academicYearId = activeYear?['id'] as String?;
      final user = _supabase.auth.currentUser;
      
      String? remoteReceiptUrl = receiptUrl;
      if (receiptImageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_receipt.jpg';
        await _supabase.storage.from('receipts').upload(
              fileName,
              receiptImageFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
        remoteReceiptUrl = fileName;
      }

      await _supabase.from('transactions').insert({
        'class_id': classId,
        'academic_year_id': academicYearId,
        'type': 'EXPENSE',
        'amount': amount,
        'description': title.isNotEmpty ? title : description,
        'category': category,
        'receipt_url': remoteReceiptUrl,
        'created_by': user?.id,
        'date': DateTime.now().toIso8601String(),
      });

      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Update student name/NIS
  Future<void> updateStudent(String studentId, String name, String nis) async {
    try {
      state = state.copyWith(isLoading: true);
      await _supabase
          .from('students')
          .update({'name': name, 'nis': nis})
          .eq('id', studentId);
      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Deactivate student (soft delete)
  Future<void> deactivateStudent(String studentId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _supabase
          .from('students')
          .update({'is_active': false})
          .eq('id', studentId);
      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Tutup Buku (Reset Semester)
  Future<void> resetSemester(String newAcademicYear, int newSemester) async {
    final classId = state.classInfo?.id;
    if (classId == null) return;

    try {
      state = state.copyWith(isLoading: true);
      
      // 1. Deactivate old academic years
      await _supabase
          .from('academic_years')
          .update({'is_active': false})
          .eq('class_id', classId);

      // 2. Insert new active academic year
      await _supabase
          .from('academic_years')
          .insert({
            'class_id': classId,
            'name': newAcademicYear,
            'start_date': DateTime.now().toIso8601String().split('T')[0],
            'is_active': true,
          });

      // 3. Update class semester start date
      await _supabase
          .from('classes')
          .update({
            'semester_start_date': DateTime.now().toIso8601String().split('T')[0],
          })
          .eq('id', classId);

      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// Provider definition
final classProvider = StateNotifierProvider<ClassNotifier, ClassState>((ref) {
  return ClassNotifier();
});

// Shared helper extension for lists
extension IterableExtension<E> on Iterable<E> {
  List<T> flatMap<T>(Iterable<T> Function(E) f) {
    final list = <T>[];
    for (var element in this) {
      list.addAll(f(element));
    }
    return list;
  }
}
