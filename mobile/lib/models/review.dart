/// Mirrors backend/collections/Review.js. `courseId`/`userId` come back as
/// plain ObjectId strings from create/update, but as populated sub-objects
/// from the list endpoints (getCourseReviews populates userId->username,
/// getMyReviews populates courseId->course_code/title/department) — this
/// model handles both shapes.
class Review {
  final String id;
  final String courseId;
  final String? courseCode;
  final String? courseTitle;
  final String userId;
  final String? authorUsername;
  final String? instructor;
  final String? term;
  final int quality;
  final int difficulty;
  final String? grade;
  final String? comment;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.courseId,
    this.courseCode,
    this.courseTitle,
    required this.userId,
    this.authorUsername,
    this.instructor,
    this.term,
    required this.quality,
    required this.difficulty,
    this.grade,
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final rawCourse = json['courseId'];
    final rawUser = json['userId'];

    return Review(
      id: json['_id'] as String,
      courseId: rawCourse is Map ? rawCourse['_id'] as String : rawCourse as String,
      courseCode: rawCourse is Map ? rawCourse['course_code'] as String? : null,
      courseTitle: rawCourse is Map ? rawCourse['title'] as String? : null,
      userId: rawUser is Map ? rawUser['_id'] as String : rawUser as String,
      authorUsername: rawUser is Map ? rawUser['username'] as String? : null,
      instructor: json['instructor'] as String?,
      term: json['term'] as String?,
      quality: (json['quality'] as num).toInt(),
      difficulty: (json['difficulty'] as num).toInt(),
      grade: json['grade'] as String?,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
