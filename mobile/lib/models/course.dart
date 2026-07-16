class Course {
  final String id;
  final String courseCode;
  final String title;
  final String? department;
  final int? credits;
  final double avgRating;
  final double avgDifficulty;
  final int numRatings;

  Course({
    required this.id,
    required this.courseCode,
    required this.title,
    this.department,
    this.credits,
    required this.avgRating,
    required this.avgDifficulty,
    required this.numRatings,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] as String,
      courseCode: json['course_code'] as String,
      title: json['title'] as String,
      department: json['department'] as String?,
      credits: (json['credits'] as num?)?.toInt(),
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      avgDifficulty: (json['avgDifficulty'] as num?)?.toDouble() ?? 0,
      numRatings: (json['numRatings'] as num?)?.toInt() ?? 0,
    );
  }

  /// Buckets difficulty into the same 4 tiers as the web frontend's
  /// getDifficultyKey() in CourseSearchPage.jsx.
  String get difficultyKey {
    if (numRatings == 0) return 'unrated';
    if (avgDifficulty <= 2) return 'easy';
    if (avgDifficulty <= 3.5) return 'medium';
    return 'hard';
  }
}
