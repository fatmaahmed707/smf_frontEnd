import '../models/role_summary.dart';
import 'api_service.dart';
import 'auth_service.dart';

class RolesService {
  RolesService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<RoleSummary>> getRoles() async {
    final response = await _apiService.get(
      '/roles/',
      headers: await AuthService.instance.authHeaders(),
    );

    final rawData = response.data;
    final rawRoles = rawData is List
        ? rawData
        : rawData is Map<String, dynamic>
            ? rawData['roles'] as List<dynamic>? ??
                rawData['items'] as List<dynamic>? ??
                rawData['content'] as List<dynamic>? ??
                const []
            : const <dynamic>[];
    return rawRoles
        .whereType<Map<String, dynamic>>()
        .map(RoleSummary.fromJson)
        .toList();
  }

  Future<RoleSummary> getRole(int id) async {
    final response = await _apiService.get(
      '/roles/$id',
      headers: await AuthService.instance.authHeaders(),
    );

    return RoleSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoleSummary> createRole(String roleName) async {
    final response = await _apiService.post(
      '/roles/',
      headers: await AuthService.instance.authHeaders(),
      body: {'roleName': roleName},
    );

    return RoleSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RoleSummary> updateRole({
    required int id,
    required String roleName,
  }) async {
    final response = await _apiService.put(
      '/roles/$id',
      headers: await AuthService.instance.authHeaders(),
      body: {'roleName': roleName},
    );

    return RoleSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRole(int id) async {
    await _apiService.delete(
      '/roles/$id',
      headers: await AuthService.instance.authHeaders(),
    );
  }
}
