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
  final List<int> roleIds;
  final List<String> roleNames;
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
    this.roleIds = const [],
    this.roleNames = const [],
    this.workers = const [],
  });

  factory ZoneSummary.fromJson(Map<String, dynamic> json) {
    final rawWorkers = json['workers'];
    final parsedRoles = _parseRoles(json);
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
      roleIds: parsedRoles.ids,
      roleNames: parsedRoles.names,
      workers: rawWorkers is List
          ? rawWorkers
              .whereType<Map<String, dynamic>>()
              .map(ZoneWorkerSnapshot.fromJson)
              .toList()
          : const [],
    );
  }

  static _ParsedZoneRoles _parseRoles(Map<String, dynamic> json) {
    final ids = <int>{};
    final names = <String>{};

    void addId(dynamic value) {
      final id = value is num ? value.toInt() : int.tryParse(value.toString());
      if (id != null && id > 0) ids.add(id);
    }

    void addName(dynamic value) {
      final name = value?.toString().trim();
      if (name != null && name.isNotEmpty) names.add(name);
    }

    void parseList(dynamic raw) {
      if (raw is! List) return;
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          addId(item['id'] ?? item['roleId']);
          addName(item['roleName'] ?? item['name'] ?? item['authority']);
        } else if (item is num) {
          addId(item);
        } else {
          addName(item);
        }
      }
    }

    parseList(json['roles']);
    parseList(json['assignedRoles']);
    parseList(json['allowedRoles']);
    parseList(json['zoneRoles']);
    parseList(json['roleIds']);
    parseList(json['roleNames']);

    return _ParsedZoneRoles(ids.toList(), names.toList());
  }
}

class _ParsedZoneRoles {
  final List<int> ids;
  final List<String> names;

  const _ParsedZoneRoles(this.ids, this.names);
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
