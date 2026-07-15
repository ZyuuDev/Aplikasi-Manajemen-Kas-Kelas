class OffWeek {
  final String id;
  final String classId;
  final String academicYearId;
  final DateTime startDate;
  final String? description;

  OffWeek({
    required this.id,
    required this.classId,
    required this.academicYearId,
    required this.startDate,
    this.description,
  });

  factory OffWeek.fromJson(Map<String, dynamic> json) {
    return OffWeek(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      description: json['description'] as String?,
    );
  }
}
