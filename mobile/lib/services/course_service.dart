import '../models/course.dart';
import 'api_client.dart';

/// Mirrors frontend/src/api/courses.js.
class CourseService {
  static Future<List<Course>> getCourses([String? q]) async {
    final res = await ApiClient.get('/courses', query: (q != null && q.isNotEmpty) ? {'q': q} : null);
    return (res as List).map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Course> getCourseById(String id) async {
    final res = await ApiClient.get('/courses/$id');
    return Course.fromJson(res as Map<String, dynamic>);
  }
}
