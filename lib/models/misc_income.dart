class MiscIncomeRecord {
  final String id;
  final String description;
  final int amount;
  final DateTime date;

  MiscIncomeRecord({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
  });

  factory MiscIncomeRecord.fromJson(Map<String, dynamic> json) {
    return MiscIncomeRecord(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: json['amount'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
