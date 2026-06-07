import 'payment.dart';

class Student {
  final String id;
  final String name;
  final String nis;
  final String classId;
  final int totalPaid;
  final List<PaymentRecord> payments;

  Student({
    required this.id,
    required this.name,
    required this.nis,
    required this.classId,
    required this.totalPaid,
    required this.payments,
  });

  Student copyWith({
    String? id,
    String? name,
    String? nis,
    String? classId,
    int? totalPaid,
    List<PaymentRecord>? payments,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      nis: nis ?? this.nis,
      classId: classId ?? this.classId,
      totalPaid: totalPaid ?? this.totalPaid,
      payments: payments ?? this.payments,
    );
  }
}
