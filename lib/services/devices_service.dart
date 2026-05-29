import '../models/device_record.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DevicesService {
  DevicesService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<DeviceRecord>> getDevices() async {
    final response = await _apiService.get(
      '/devices/',
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
        .map(DeviceRecord.fromJson)
        .toList();
  }

  Future<DeviceRecord> getDevice(String id) async {
    final response = await _apiService.get(
      '/devices/$id',
      headers: await AuthService.instance.authHeaders(),
    );

    return DeviceRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DeviceRecord> registerDevice({
    required String smfDeviceLabel,
    required String ownerId,
    String? zoneId,
  }) async {
    final response = await _apiService.post(
      '/devices/',
      headers: await AuthService.instance.authHeaders(),
      body: {
        'smfDeviceLabel': smfDeviceLabel,
        'ownerId': ownerId,
        if (zoneId != null && zoneId.isNotEmpty) 'zoneId': zoneId,
      },
    );

    return DeviceRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DeviceRecord> updateDevice({
    required String id,
    required String smfDeviceLabel,
    required String ownerId,
    String? zoneId,
  }) async {
    final response = await _apiService.put(
      '/devices/$id',
      headers: await AuthService.instance.authHeaders(),
      body: {
        'smfDeviceLabel': smfDeviceLabel,
        'ownerId': ownerId,
        if (zoneId != null && zoneId.isNotEmpty) 'zoneId': zoneId,
      },
    );

    return DeviceRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDevice(String id) async {
    await _apiService.delete(
      '/devices/$id',
      headers: await AuthService.instance.authHeaders(),
    );
  }

  Future<void> recordZoneEntry({
    required String macAddress,
    required int timestamp,
    required String signature,
    required String zoneId,
  }) async {
    await _apiService.post(
      '/devices/zone-entry',
      headers: {
        'X-Device-Mac': macAddress,
        'X-Device-Timestamp': timestamp.toString(),
        'X-Device-Signature': signature,
      },
      body: {'zoneId': zoneId},
    );
  }
}
