import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_info.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../models/expense.dart';
import '../models/special_collection.dart';
import '../models/off_week.dart';
import '../models/class_assistant.dart';
import '../models/misc_income.dart';

class ClassState {
  final ClassInfo? classInfo;
  final List<Student> students;
  final List<ExpenseRecord> expenses;
  final List<SpecialCollection> specialCollections;
  final List<OffWeek> offWeeks;
  final List<ClassAssistant> assistants;
  final List<MiscIncomeRecord> miscIncomes;
  final bool isLoading;
  final String? error;

  ClassState({
    this.classInfo,
    this.students = const [],
    this.expenses = const [],
    this.specialCollections = const [],
    this.offWeeks = const [],
    this.assistants = const [],
    this.miscIncomes = const [],
    this.isLoading = false,
    this.error,
  });

  ClassState copyWith({
    ClassInfo? classInfo,
    List<Student>? students,
    List<ExpenseRecord>? expenses,
    List<SpecialCollection>? specialCollections,
    List<OffWeek>? offWeeks,
    List<ClassAssistant>? assistants,
    List<MiscIncomeRecord>? miscIncomes,
    bool? isLoading,
    String? error,
  }) {
    return ClassState(
      classInfo: classInfo ?? this.classInfo,
      students: students ?? this.students,
      expenses: expenses ?? this.expenses,
      specialCollections: specialCollections ?? this.specialCollections,
      offWeeks: offWeeks ?? this.offWeeks,
      assistants: assistants ?? this.assistants,
      miscIncomes: miscIncomes ?? this.miscIncomes,
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
    final rawWeeks = (diffDays / 7).floor() + 1;

    // Count how many UNIQUE offWeeks fall between start and today (inclusive)
    final uniqueDates = offWeeks.map((ow) =>
      "${ow.startDate.year}-${ow.startDate.month.toString().padLeft(2, '0')}-${ow.startDate.day.toString().padLeft(2, '0')}"
    ).toSet();

    int offWeeksCount = 0;
    for (final dateStr in uniqueDates) {
      final parts = dateStr.split('-');
      final owDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if (!owDate.isBefore(start) && !owDate.isAfter(current)) {
        offWeeksCount++;
      }
    }
    final actualWeeks = rawWeeks - offWeeksCount;
    return actualWeeks > 0 ? actualWeeks : 0;
  }

  int get totalIncome {
    final studentIncome = students.fold(0, (sum, std) => sum + std.totalPaid);
    final generalIncome = miscIncomes.fold(0, (sum, misc) => sum + misc.amount);
    return studentIncome + generalIncome;
  }

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
      var classData = await _supabase
          .from('classes')
          .select('*')
          .eq('treasurer_id', user.id)
          .maybeSingle();

      // If the user is not the main treasurer, check if they are an assistant
      if (classData == null) {
        final assistantRecord = await _supabase
            .from('class_assistants')
            .select('class_id')
            .eq('user_id', user.id)
            .maybeSingle();

        if (assistantRecord != null) {
          final classId = assistantRecord['class_id'] as String;
          classData = await _supabase
              .from('classes')
              .select('*')
              .eq('id', classId)
              .maybeSingle();
        }
      }

      if (classData == null) {
        state = state.copyWith(isLoading: false, error: 'Kelas tidak ditemukan untuk bendahara ini.');
        return;
      }

      final classId = classData['id'] as String;

      // 2. Fetch active academic year (all data below is scoped to it)
      final academicData = await _supabase
          .from('academic_years')
          .select('*')
          .eq('class_id', classId)
          .eq('is_active', true)
          .maybeSingle();

      if (academicData == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Tidak ada semester aktif. Buka menu Tutup Buku untuk memulai semester baru.',
        );
        return;
      }

      final academicYearId = academicData['id'] as String;

      // 3. Fetch students (payments are derived from the transactions query below)
      final List<dynamic> studentsData = await _supabase
          .from('students')
          .select('*')
          .eq('class_id', classId)
          .eq('is_active', true);

      // 4. Fetch transactions of the ACTIVE semester only (Tutup Buku = mulai dari Rp0)
      final List<dynamic> transactionsData = await _supabase
          .from('transactions')
          .select('*')
          .eq('class_id', classId)
          .eq('academic_year_id', academicYearId)
          .order('date', ascending: false);

      // 5. Fetch off-week exceptions of the active semester
      final List<dynamic> offWeeksData = await _supabase
          .from('off_weeks')
          .select('*')
          .eq('class_id', classId)
          .eq('academic_year_id', academicYearId)
          .order('start_date', ascending: false);

      // 6. Fetch assistant lists
      final List<dynamic> assistantsData = await _supabase
          .from('class_assistants')
          .select('*')
          .eq('class_id', classId);

      // Partition transactions
      final expensesData = transactionsData.where((tx) => tx['type'] == 'EXPENSE').toList();
      final miscIncomesData = transactionsData.where((tx) => tx['type'] == 'INCOME' && tx['student_id'] == null).toList();

      final classInfo = ClassInfo(
        id: classId,
        name: classData['name'] as String,
        slug: classData['slug'] as String,
        weeklyFee: classData['weekly_fee'] as int,
        // Semester aktif adalah sumber kebenaran titik awal perhitungan
        semesterStartDate: DateTime.parse(
          (academicData['start_date'] ?? classData['semester_start_date']) as String,
        ),
        academicYear: academicData['name'] as String,
        semester: 1, // Default semester representation
        qrisUrl: classData['qris_url'] as String?,
      );

      // Group INCOME transactions of the active semester by student
      final Map<String, List<PaymentRecord>> paymentsByStudent = {};
      for (final tx in transactionsData) {
        if (tx['type'] == 'INCOME' && tx['student_id'] != null) {
          final payment = PaymentRecord(
            id: tx['id'] as String,
            studentId: tx['student_id'] as String,
            amount: tx['amount'] as int,
            date: DateTime.parse(tx['date'] as String),
          );
          paymentsByStudent.putIfAbsent(payment.studentId, () => []).add(payment);
        }
      }

      // Map students
      final students = studentsData.map<Student>((std) {
        final payments = paymentsByStudent[std['id'] as String] ?? [];
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

      // Map off-weeks
      final offWeeks = offWeeksData.map<OffWeek>((ow) => OffWeek.fromJson(ow)).toList();

      // Map assistants
      final assistants = assistantsData.map<ClassAssistant>((ca) => ClassAssistant.fromJson(ca)).toList();

      // Map misc incomes
      final miscIncomes = miscIncomesData.map<MiscIncomeRecord>((mi) => MiscIncomeRecord.fromJson(mi)).toList();

      // 7. Fetch special collections of the active semester
      final List<dynamic> collectionsData = await _supabase
          .from('special_collections')
          .select('*')
          .eq('class_id', classId)
          .eq('academic_year_id', academicYearId)
          .order('created_at', ascending: false);

      // 8. Fetch special collection payments
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
        offWeeks: offWeeks,
        assistants: assistants,
        miscIncomes: miscIncomes,
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
        offWeeks: state.offWeeks,
        assistants: state.assistants,
        miscIncomes: state.miscIncomes,
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
        // Folder per kelas agar kebijakan storage bisa membatasi akses tulis
        final fileName = '$classId/${DateTime.now().millisecondsSinceEpoch}_receipt.jpg';
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

  // Action: Add Miscellaneous Income
  Future<void> addMiscIncome({
    required String description,
    required int amount,
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

      await _supabase.from('transactions').insert({
        'class_id': classId,
        'academic_year_id': academicYearId,
        'type': 'INCOME',
        'amount': amount,
        'description': description,
        'student_id': null, // Non-student income
        'created_by': user?.id,
        'date': DateTime.now().toIso8601String(),
      });

      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Add holiday week exception
  Future<void> addOffWeek({
    required DateTime startDate,
    String? description,
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
      if (academicYearId == null) {
        throw Exception('Tidak ada semester aktif. Silakan buat semester terlebih dahulu.');
      }

      final formattedDate = startDate.toIso8601String().split('T')[0];

      final exists = state.offWeeks.any((ow) =>
        ow.startDate.toIso8601String().split('T')[0] == formattedDate
      );
      if (exists) {
        throw Exception('Minggu libur untuk tanggal ini sudah pernah ditambahkan.');
      }

      await _supabase.from('off_weeks').insert({
        'class_id': classId,
        'academic_year_id': academicYearId,
        'start_date': formattedDate,
        'description': description,
      });

      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Delete holiday week exception
  Future<void> deleteOffWeek(String offWeekId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _supabase.from('off_weeks').delete().eq('id', offWeekId);
      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Add class assistant
  Future<void> addAssistantByEmail(String email) async {
    final classId = state.classInfo?.id;
    if (classId == null) return;

    try {
      state = state.copyWith(isLoading: true);
      await _supabase.rpc('add_class_assistant_by_email', params: {
        'p_class_id': classId,
        'p_email': email.trim(),
      });
      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Remove class assistant
  Future<void> removeAssistant(String assistantId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _supabase.from('class_assistants').delete().eq('id', assistantId);
      await loadClassData();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Action: Upload QRIS Image and update classes URL
  Future<void> uploadQrisImage(File imageFile) async {
    final classId = state.classInfo?.id;
    if (classId == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final fileName = '$classId/qris.jpg';

      await _supabase.storage.from('receipts').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage.from('receipts').getPublicUrl(fileName);

      await _supabase
          .from('classes')
          .update({'qris_url': publicUrl})
          .eq('id', classId);

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
