import '../models/zone_summary.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ZonesService {
  ZonesService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<ZoneSummary>> getZones() async {
    final response = await _apiService.get(
      '/zones/',
      headers: await AuthService.instance.authHeaders(),
    );

    final rawData = response.data;
    final rawZones = rawData is List
        ? rawData
        : rawData is Map<String, dynamic>
            ? rawData['items'] as List<dynamic>? ?? const []
            : const <dynamic>[];
    return rawZones
        .whereType<Map<String, dynamic>>()
        .map(ZoneSummary.fromJson)
        .toList();
  }

  Future<ZoneSummary> getZone(String id) async {
    final response = await _apiService.get(
      '/zones/$id',
      headers: await AuthService.instance.authHeaders(),
    );

    return ZoneSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ZoneSummary> createZone(String name) async {
    final response = await _apiService.post(
      '/zones/',
      headers: await AuthService.instance.authHeaders(),
      body: {'name': name},
    );

    return ZoneSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ZoneSummary> updateZone({
    required String id,
    required String name,
  }) async {
    final response = await _apiService.put(
      '/zones/$id',
      headers: await AuthService.instance.authHeaders(),
      body: {'name': name},
    );

    return ZoneSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteZone(String id) async {
    await _apiService.delete(
      '/zones/$id',
      headers: await AuthService.instance.authHeaders(),
    );
  }

  Future<void> assignRoleToZone({
    required String zoneId,
    required int roleId,
  }) async {
    await _apiService.post(
      '/zones/$zoneId/roles/$roleId',
      headers: await AuthService.instance.authHeaders(),
    );
  }

  Future<void> removeRoleFromZone({
    required String zoneId,
    required int roleId,
  }) async {
    await _apiService.delete(
      '/zones/$zoneId/roles/$roleId',
      headers: await AuthService.instance.authHeaders(),
    );
  }
}
