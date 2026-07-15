class ClassAssistant {
  final String id;
  final String classId;
  final String userId;
  final String email;

  ClassAssistant({
    required this.id,
    required this.classId,
    required this.userId,
    required this.email,
  });

  factory ClassAssistant.fromJson(Map<String, dynamic> json) {
    return ClassAssistant(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String,
    );
  }
}
