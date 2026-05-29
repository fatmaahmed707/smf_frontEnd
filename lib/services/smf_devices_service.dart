import '../models/smf_device.dart';
import 'api_service.dart';
import 'auth_service.dart';

class SmfDevicesService {
  SmfDevicesService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<SmfDevice>> getUnregisteredDevices() async {
    final response = await _apiService.get(
      '/smfdevices/unregistered',
      headers: await AuthService.instance.authHeaders(),
    );

    final rawData = response.data;
    final rawDevices = rawData is List
        ? rawData
        : rawData is Map<String, dynamic>
            ? rawData['devices'] as List<dynamic>? ??
                rawData['items'] as List<dynamic>? ??
                rawData['content'] as List<dynamic>? ??
                const []
            : const <dynamic>[];
    return rawDevices
        .whereType<Map<String, dynamic>>()
        .map(SmfDevice.fromJson)
        .toList();
  }

  Future<List<SmfDevice>> getAllDevices() async {
    final response = await _apiService.get(
      '/smfdevices/',
      headers: await AuthService.instance.authHeaders(),
    );

    final rawData = response.data;
    final rawDevices = rawData is List
        ? rawData
        : rawData is Map<String, dynamic>
            ? rawData['devices'] as List<dynamic>? ??
                rawData['items'] as List<dynamic>? ??
                rawData['content'] as List<dynamic>? ??
                const []
            : const <dynamic>[];
    return rawDevices
        .whereType<Map<String, dynamic>>()
        .map(SmfDevice.fromJson)
        .toList();
  }

  Future<SmfDevice> getDevice(String id) async {
    final response = await _apiService.get(
      '/smfdevices/$id',
      headers: await AuthService.instance.authHeaders(),
    );

    return SmfDevice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SmfDevice> getDeviceByLabel(String label) async {
    final response = await _apiService.get(
      '/smfdevices/label/${Uri.encodeComponent(label)}',
      headers: await AuthService.instance.authHeaders(),
    );

    return SmfDevice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SmfDevice> addDevice({
    required String macAddress,
    required String label,
    required String secret,
  }) async {
    final response = await _apiService.post(
      '/smfdevices/',
      headers: await AuthService.instance.authHeaders(),
      body: {
        'macAddress': macAddress,
        'label': label,
        'secret': secret,
      },
    );

    return SmfDevice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDevice(String id) async {
    await _apiService.delete(
      '/smfdevices/$id',
      headers: await AuthService.instance.authHeaders(),
    );
  }
}
