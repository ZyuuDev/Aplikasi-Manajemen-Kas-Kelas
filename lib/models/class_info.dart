class ClassInfo {
  final String id;
  final String name;
  final String slug;
  final int weeklyFee;
  final DateTime semesterStartDate;
  final String academicYear;
  final int semester;

  ClassInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.weeklyFee,
    required this.semesterStartDate,
    required this.academicYear,
    required this.semester,
  });

  ClassInfo copyWith({
    String? id,
    String? name,
    String? slug,
    int? weeklyFee,
    DateTime? semesterStartDate,
    String? academicYear,
    int? semester,
  }) {
    return ClassInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      weeklyFee: weeklyFee ?? this.weeklyFee,
      semesterStartDate: semesterStartDate ?? this.semesterStartDate,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
    );
  }
}
