class SpecialCollection {
  final String id;
  final String classId;
  final String? academicYearId;
  final String name;
  final int amount;
  final String? description;
  final DateTime createdAt;
  final List<String> paidStudentIds; // IDs of students who have paid

  SpecialCollection({
    required this.id,
    required this.classId,
    this.academicYearId,
    required this.name,
    required this.amount,
    this.description,
    required this.createdAt,
    required this.paidStudentIds,
  });

  SpecialCollection copyWith({
    String? id,
    String? classId,
    String? academicYearId,
    String? name,
    int? amount,
    String? description,
    DateTime? createdAt,
    List<String>? paidStudentIds,
  }) {
    return SpecialCollection(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      academicYearId: academicYearId ?? this.academicYearId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      paidStudentIds: paidStudentIds ?? this.paidStudentIds,
    );
  }

  /// Number of students who have paid
  int get paidCount => paidStudentIds.length;

  /// Check if a specific student has paid
  bool hasPaid(String studentId) => paidStudentIds.contains(studentId);

  /// Factory from Supabase JSON (without payments - call withPayments to add them)
  factory SpecialCollection.fromJson(Map<String, dynamic> json) {
    return SpecialCollection(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      academicYearId: json['academic_year_id'] as String?,
      name: json['name'] as String,
      amount: json['amount'] as int,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidStudentIds: const [],
    );
  }

  SpecialCollection withPayments(List<String> studentIds) {
    return copyWith(paidStudentIds: studentIds);
  }
}
