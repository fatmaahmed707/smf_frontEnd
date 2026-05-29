class DeviceRecord {
  final String id;
  final String label;
  final String displayLabel;
  final String macAddress;
  final String ownerId;
  final String? zoneId;
  final String? zoneName;
  final double lastLocationLat;
  final double lastLocationLon;
  final DateTime? lastSeenTimestamp;
  final String status;
  final int violationCount;

  const DeviceRecord({
    required this.id,
    required this.label,
    this.displayLabel = '',
    required this.macAddress,
    required this.ownerId,
    this.zoneId,
    this.zoneName,
    required this.lastLocationLat,
    required this.lastLocationLon,
    required this.lastSeenTimestamp,
    required this.status,
    required this.violationCount,
  });

  factory DeviceRecord.fromJson(Map<String, dynamic> json) {
    final smfDevice = json['smfDevice'] is Map<String, dynamic>
        ? json['smfDevice'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final owner = json['owner'] is Map<String, dynamic>
        ? json['owner'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final location = json['lastLocation'] is Map<String, dynamic>
        ? json['lastLocation'] as Map<String, dynamic>
        : json['location'] is Map<String, dynamic>
            ? json['location'] as Map<String, dynamic>
            : const <String, dynamic>{};

    return DeviceRecord(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ??
              json['smfDeviceLabel'] ??
              json['deviceLabel'] ??
              smfDevice['label'] ??
              '')
          .toString(),
      displayLabel: (json['displayLabel'] ?? '').toString(),
      macAddress:
          (json['macAddress'] ?? smfDevice['macAddress'] ?? '').toString(),
      ownerId:
          (json['ownerId'] ?? json['userId'] ?? owner['id'] ?? '').toString(),
      zoneId: json['zoneId']?.toString(),
      zoneName: json['zoneName']?.toString(),
      lastLocationLat: (json['lastLocationLat'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble() ??
          (location['lat'] as num?)?.toDouble() ??
          (location['latitude'] as num?)?.toDouble() ??
          0,
      lastLocationLon: (json['lastLocationLon'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble() ??
          (location['lon'] as num?)?.toDouble() ??
          (location['lng'] as num?)?.toDouble() ??
          (location['longitude'] as num?)?.toDouble() ??
          0,
      lastSeenTimestamp: (json['lastSeenTimestamp'] ??
                  json['lastSeen'] ??
                  json['timestamp'] ??
                  json['updatedAt']) ==
              null
          ? null
          : DateTime.tryParse((json['lastSeenTimestamp'] ??
                  json['lastSeen'] ??
                  json['timestamp'] ??
                  json['updatedAt'])
              .toString()),
      status: (json['status'] ?? 'OFFLINE').toString(),
      violationCount: (json['violationCount'] as num?)?.toInt() ??
          (json['violationsCount'] as num?)?.toInt() ??
          0,
    );
  }

  DeviceRecord copyWithDisplayLabel(String value) {
    return DeviceRecord(
      id: id,
      label: label,
      displayLabel: value,
      macAddress: macAddress,
      ownerId: ownerId,
      zoneId: zoneId,
      zoneName: zoneName,
      lastLocationLat: lastLocationLat,
      lastLocationLon: lastLocationLon,
      lastSeenTimestamp: lastSeenTimestamp,
      status: status,
      violationCount: violationCount,
    );
  }
}
