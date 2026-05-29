class ZoneSummary {
  final String id;
  final String name;
  final String? type;
  final String? area;
  final int? workersCount;
  final int? safeCount;
  final int? warningCount;
  final int? emergencyCount;
  final String? status;
  final double? positionX;
  final double? positionY;
  final List<ZoneWorkerSnapshot> workers;

  const ZoneSummary({
    required this.id,
    required this.name,
    this.type,
    this.area,
    this.workersCount,
    this.safeCount,
    this.warningCount,
    this.emergencyCount,
    this.status,
    this.positionX,
    this.positionY,
    this.workers = const [],
  });

  factory ZoneSummary.fromJson(Map<String, dynamic> json) {
    final rawWorkers = json['workers'];
    return ZoneSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: json['type']?.toString(),
      area: json['area']?.toString(),
      workersCount: (json['workersCount'] as num?)?.toInt(),
      safeCount: (json['safeCount'] as num?)?.toInt(),
      warningCount: (json['warningCount'] as num?)?.toInt(),
      emergencyCount: (json['emergencyCount'] as num?)?.toInt(),
      status: json['status']?.toString(),
      positionX: (json['positionX'] as num?)?.toDouble(),
      positionY: (json['positionY'] as num?)?.toDouble(),
      workers: rawWorkers is List
          ? rawWorkers
              .whereType<Map<String, dynamic>>()
              .map(ZoneWorkerSnapshot.fromJson)
              .toList()
          : const [],
    );
  }
}

class ZoneWorkerSnapshot {
  final String id;
  final String name;
  final String? status;
  final String? avatarUrl;
  final double? positionX;
  final double? positionY;
  final String? location;

  const ZoneWorkerSnapshot({
    required this.id,
    required this.name,
    this.status,
    this.avatarUrl,
    this.positionX,
    this.positionY,
    this.location,
  });

  factory ZoneWorkerSnapshot.fromJson(Map<String, dynamic> json) {
    return ZoneWorkerSnapshot(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? '').toString(),
      status: json['status']?.toString(),
      avatarUrl:
          json['avatarUrl']?.toString() ?? json['pictureUrl']?.toString(),
      positionX: (json['positionX'] as num?)?.toDouble(),
      positionY: (json['positionY'] as num?)?.toDouble(),
      location: json['location']?.toString(),
    );
  }
}
