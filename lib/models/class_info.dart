class ClassInfo {
  final String id;
  final String name;
  final String slug;
  final int weeklyFee;
  final DateTime semesterStartDate;
  final String academicYear;
  final int semester;

  final String? qrisUrl;

  ClassInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.weeklyFee,
    required this.semesterStartDate,
    required this.academicYear,
    required this.semester,
    this.qrisUrl,
  });

  ClassInfo copyWith({
    String? id,
    String? name,
    String? slug,
    int? weeklyFee,
    DateTime? semesterStartDate,
    String? academicYear,
    int? semester,
    String? qrisUrl,
  }) {
    return ClassInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      weeklyFee: weeklyFee ?? this.weeklyFee,
      semesterStartDate: semesterStartDate ?? this.semesterStartDate,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      qrisUrl: qrisUrl ?? this.qrisUrl,
    );
  }
}
