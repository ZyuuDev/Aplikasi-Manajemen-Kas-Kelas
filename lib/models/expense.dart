class ExpenseRecord {
  final String id;
  final String title;
  final String description;
  final int amount;
  final DateTime date;
  final String category;
  final String? receiptUrl;

  ExpenseRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.receiptUrl,
  });
}
