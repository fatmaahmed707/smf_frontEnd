import '../models/worker_profile.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WorkersService {
  WorkersService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<WorkerProfile> getWorker(String id) async {
    final response = await _apiService.get(
      '/workers/$id',
      headers: await AuthService.instance.authHeaders(),
    );

    return WorkerProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkerProfile> createWorker({
    required String userId,
    required Map<String, String> fields,
  }) async {
    final response = await _apiService.post(
      '/workers',
      headers: await AuthService.instance.authHeaders(),
      body: {
        'user_id': userId,
        ...fields,
      },
    );

    return WorkerProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkerProfile> updateWorker({
    required String id,
    required Map<String, String> fields,
  }) async {
    final response = await _apiService.patch(
      '/workers/$id',
      headers: await AuthService.instance.authHeaders(),
      body: {
        'user_id': id,
        ...fields,
      },
    );

    return WorkerProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteWorker(String id) async {
    await _apiService.delete(
      '/workers/$id',
      headers: await AuthService.instance.authHeaders(),
    );
  }
}
