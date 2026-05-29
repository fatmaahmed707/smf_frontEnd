import '../models/event_log.dart';
import 'api_service.dart';
import 'auth_service.dart';

class EventsService {
  EventsService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<EventLog>> getEvents({int? since}) async {
    final path =
        since == null ? '/events/client' : '/events/client?since=$since';
    final response = await _apiService.get(
      path,
      headers: await AuthService.instance.authHeaders(),
    );

    final rawData = response.data;
    final rawEvents = rawData is List
        ? rawData
        : rawData is Map<String, dynamic>
            ? rawData['events'] as List<dynamic>? ??
                rawData['items'] as List<dynamic>? ??
                rawData['content'] as List<dynamic>? ??
                const []
            : const <dynamic>[];
    return rawEvents
        .whereType<Map<String, dynamic>>()
        .map(EventLog.fromJson)
        .toList();
  }

  Future<void> submitDeviceEvent({
    required String macAddress,
    required String event,
  }) async {
    await _apiService.post(
      '/events/device',
      body: {
        'macAddress': macAddress,
        'event': event,
      },
    );
  }
}
