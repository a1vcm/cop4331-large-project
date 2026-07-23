import '../models/resource.dart';
import 'api_client.dart';

/// Mirrors backend/routes/resource-routes.js and frontend/src/api/
/// resources.js.
class ResourceService {
  static Future<List<Resource>> getForCourse(String courseId) async {
    final res = await ApiClient.get('/resources/course/$courseId');
    return (res as List).map((e) => Resource.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Resource> create({
    required String courseId,
    required String title,
    required String url,
  }) async {
    final res = await ApiClient.post('/resources', body: {
      'courseId': courseId,
      'title': title,
      'url': url,
    });
    return Resource.fromJson(res as Map<String, dynamic>);
  }

  static Future<void> delete(String id) async {
    await ApiClient.delete('/resources/$id');
  }
}
