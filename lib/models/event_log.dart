import 'dart:convert';

class EventLog {
  final String id;
  final String eventType;
  final String macAddress;
  final DateTime? createdAt;
  final String rawMetadata;
  final Map<String, dynamic> metadata;

  const EventLog({
    required this.id,
    required this.eventType,
    required this.macAddress,
    required this.createdAt,
    required this.rawMetadata,
    required this.metadata,
  });

  String? get zoneName => metadata['zoneName']?.toString();
  String? get message => metadata['message']?.toString();

  factory EventLog.fromJson(Map<String, dynamic> json) {
    final metadataValue = json['metadata'];
    final rawMetadata = metadataValue is String
        ? metadataValue
        : metadataValue == null
            ? ''
            : jsonEncode(metadataValue);
    Map<String, dynamic> parsedMetadata = const {};

    if (metadataValue is Map<String, dynamic>) {
      parsedMetadata = metadataValue;
    } else if (rawMetadata.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is Map<String, dynamic>) {
          parsedMetadata = decoded;
        }
      } catch (_) {
        parsedMetadata = const {};
      }
    }

    return EventLog(
      id: (json['id'] ?? json['eventId'] ?? '').toString(),
      eventType: (json['eventType'] ?? json['event'] ?? '').toString(),
      macAddress: (json['macAddress'] ?? '').toString(),
      createdAt:
          (json['createdAt'] ?? json['timestamp'] ?? json['time']) == null
              ? null
              : DateTime.tryParse(
                  (json['createdAt'] ?? json['timestamp'] ?? json['time'])
                      .toString(),
                ),
      rawMetadata: rawMetadata,
      metadata: {
        ...parsedMetadata,
        if (json['zoneName'] != null) 'zoneName': json['zoneName'],
        if (json['message'] != null) 'message': json['message'],
        if (json['deviceId'] != null) 'deviceId': json['deviceId'],
      },
    );
  }
}
