class PaymentRecord {
  final String id;
  final String studentId;
  final int amount;
  final DateTime date;

  PaymentRecord({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.date,
  });
}
