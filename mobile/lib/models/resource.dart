/// Mirrors backend/collections/Resource.js. userId comes back populated
/// with just `username` on both list (GET /resources/course/:id) and
/// create (POST /resources) responses.
class Resource {
  final String id;
  final String courseId;
  final String userId;
  final String? authorUsername;
  final String title;
  final String url;
  final DateTime? createdAt;

  Resource({
    required this.id,
    required this.courseId,
    required this.userId,
    this.authorUsername,
    required this.title,
    required this.url,
    this.createdAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    final rawUser = json['userId'];
    return Resource(
      id: json['_id'] as String,
      courseId: json['courseId'] as String,
      userId: rawUser is Map ? rawUser['_id'] as String : rawUser as String,
      authorUsername: rawUser is Map ? rawUser['username'] as String? : null,
      title: json['title'] as String,
      url: json['url'] as String,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
