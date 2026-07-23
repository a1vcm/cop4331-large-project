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
  final double quality;
  final int difficulty;
  final int? workload;
  final int? gradingFairness;
  final int? professorRating;
  final int? attendance;
  final String? grade;
  final String? comment;
  final List<String> tags;
  final int voteHelpful;
  final int voteNotHelpful;
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
    this.workload,
    this.gradingFairness,
    this.professorRating,
    this.attendance,
    this.grade,
    this.comment,
    this.tags = const [],
    this.voteHelpful = 0,
    this.voteNotHelpful = 0,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final rawCourse = json['courseId'];
    final rawUser = json['userId'];
    final voteScore = json['voteScore'] as Map<String, dynamic>?;

    return Review(
      id: json['_id'] as String,
      courseId: rawCourse is Map ? rawCourse['_id'] as String : rawCourse as String,
      courseCode: rawCourse is Map ? rawCourse['course_code'] as String? : null,
      courseTitle: rawCourse is Map ? rawCourse['title'] as String? : null,
      userId: rawUser is Map ? rawUser['_id'] as String : rawUser as String,
      authorUsername: rawUser is Map ? rawUser['username'] as String? : null,
      instructor: json['instructor'] as String?,
      term: json['term'] as String?,
      quality: (json['quality'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toInt(),
      workload: (json['workload'] as num?)?.toInt(),
      gradingFairness: (json['gradingFairness'] as num?)?.toInt(),
      professorRating: (json['professorRating'] as num?)?.toInt(),
      attendance: (json['attendance'] as num?)?.toInt(),
      grade: json['grade'] as String?,
      comment: json['comment'] as String?,
      tags: (json['tags'] as List?)?.map((t) => t as String).toList() ?? const [],
      voteHelpful: (voteScore?['helpful'] as num?)?.toInt() ?? 0,
      voteNotHelpful: (voteScore?['notHelpful'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
