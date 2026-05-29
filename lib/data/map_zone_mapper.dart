import 'dart:math' as math;
import 'dart:ui';

import '../models/device_record.dart';
import '../models/event_log.dart';
import '../models/map_worker_marker.dart';
import '../models/map_zone_view_model.dart';
import '../models/user.dart';
import '../models/zone_layout_slot.dart';
import '../models/zone_summary.dart';
import 'zone_layout_registry.dart';

class MapZoneMapper {
  const MapZoneMapper();

  List<MapZoneViewModel> build({
    required List<ZoneSummary> zones,
    required List<User> users,
    required List<DeviceRecord> devices,
    required List<EventLog> events,
    required Brightness brightness,
  }) {
    final usedSlots = <String>{};
    final deviceByMac = {
      for (final device in devices) device.macAddress.toLowerCase(): device,
    };
    final userById = {for (final user in users) user.id: user};

    return zones.asMap().entries.map<MapZoneViewModel>((entry) {
      final index = entry.key;
      final zone = entry.value;
      final slot = _resolveSlot(zone, index, usedSlots);
      final zoneEvents = _eventsForZone(zone, events);
      final workers = _buildWorkersForZone(
        zone: zone,
        slot: slot,
        userById: userById,
        deviceByMac: deviceByMac,
      );

      final totalWorkers = workers.length;
      final emergencyCount = workers
          .where((worker) => worker.status.toLowerCase() == 'emergency')
          .length;
      final warningCount = workers
          .where((worker) => worker.status.toLowerCase() == 'warning')
          .length;
      final safeCount = workers
          .where((worker) => worker.status.toLowerCase() == 'safe')
          .length;
      final status =
          _statusForZone(zone.status, safeCount, warningCount, emergencyCount);
      final statusColor = _statusColor(status, brightness);
      final latestEvent = zoneEvents.isEmpty ? null : zoneEvents.first;

      return MapZoneViewModel(
        id: zone.id,
        name: zone.name,
        type: zone.type ?? slot.defaultType,
        area: zone.area ?? slot.defaultArea,
        workersCount: math.max(totalWorkers, workers.length),
        safeCount: safeCount,
        warningCount: warningCount,
        emergencyCount: emergencyCount,
        status: status,
        statusColor: statusColor,
        layoutSlot: slot,
        latestEvent: latestEvent,
        workers: workers,
      );
    }).toList();
  }

  ZoneLayoutSlot _resolveSlot(
    ZoneSummary zone,
    int index,
    Set<String> usedSlots,
  ) {
    final directSlot = ZoneLayoutRegistry.findByZoneName(zone.name);
    if (directSlot != null && usedSlots.add(directSlot.key)) {
      return _overrideWithApiPosition(zone, directSlot);
    }

    for (final slot in ZoneLayoutRegistry.primarySlots) {
      if (usedSlots.add(slot.key)) {
        return _overrideWithApiPosition(zone, slot);
      }
    }

    final fallback = ZoneLayoutRegistry.fallbackAt(index);
    return _overrideWithApiPosition(zone, fallback);
  }

  ZoneLayoutSlot _overrideWithApiPosition(
    ZoneSummary zone,
    ZoneLayoutSlot base,
  ) {
    // حقن حدود الـ 10 نقط بتوعك لـ Zone A جوه الـ Slot
    if (zone.name == 'Zone A') {
      // أقل وأعلى قيم لـ X و Y حسب نقطك عشان نرسم المستطيل المحيط بيها بالظبط
      const minX = 0.739;
      const maxX = 0.880;
      const minY = 0.024;
      const maxY = 0.294;

      const footprint = Rect.fromLTRB(minX, minY, maxX, maxY);

      final workerField = Rect.fromLTWH(
        footprint.left + footprint.width * 0.15,
        footprint.top + footprint.height * 0.15,
        footprint.width * 0.7,
        footprint.height * 0.7,
      );

      // السنتر المحسوب لنص المبنى
      const labelAnchor = Offset(0.821, 0.190);

      return ZoneLayoutSlot(
        key: base.key,
        visualType: base.visualType,
        footprint: footprint,
        workerField: workerField,
        labelAnchor: labelAnchor,
        labelOnLeft: true,
        elevation: base.elevation,
        defaultType: base.defaultType,
        defaultArea: base.defaultArea,
      );
    }

    // حقن حدود نقط Zone B جوه الـ Slot
    if (zone.name == 'Zone B') {
      const minX = 0.650;
      const maxX = 0.783;
      const minY = 0.147;
      const maxY = 0.380;

      const footprint = Rect.fromLTRB(minX, minY, maxX, maxY);

      final workerField = Rect.fromLTWH(
        footprint.left + footprint.width * 0.15,
        footprint.top + footprint.height * 0.15,
        footprint.width * 0.7,
        footprint.height * 0.7,
      );

      const labelAnchor = Offset(0.710, 0.230);

      return ZoneLayoutSlot(
        key: base.key,
        visualType: base.visualType,
        footprint: footprint,
        workerField: workerField,
        labelAnchor: labelAnchor,
        labelOnLeft: false,
        elevation: base.elevation,
        defaultType: base.defaultType,
        defaultArea: base.defaultArea,
      );
    }

    // حقن حدود نقط Zone C جوه الـ Slot
    if (zone.name == 'Zone C') {
      const minX = 0.556;
      const maxX = 0.694;
      const minY = 0.190;
      const maxY = 0.422;

      const footprint = Rect.fromLTRB(minX, minY, maxX, maxY);

      final workerField = Rect.fromLTWH(
        footprint.left + footprint.width * 0.15,
        footprint.top + footprint.height * 0.15,
        footprint.width * 0.7,
        footprint.height * 0.7,
      );

      const labelAnchor = Offset(0.617, 0.284);

      return ZoneLayoutSlot(
        key: base.key,
        visualType: base.visualType,
        footprint: footprint,
        workerField: workerField,
        labelAnchor: labelAnchor,
        labelOnLeft: false,
        elevation: base.elevation,
        defaultType: base.defaultType,
        defaultArea: base.defaultArea,
      );
    }

    if (zone.positionX == null && zone.positionY == null) {
      return base;
    }

    final left =
        ((zone.positionX ?? base.footprint.left).clamp(0.02, 0.92) as num)
            .toDouble();
    final top =
        ((zone.positionY ?? base.footprint.top).clamp(0.02, 0.92) as num)
            .toDouble();
    final width = math.min(base.footprint.width, 0.22);
    final height = math.min(base.footprint.height, 0.20);
    final footprint = Rect.fromLTWH(
      math.min(left, 0.98 - width),
      math.min(top, 0.98 - height),
      width,
      height,
    );
    final workerField = Rect.fromLTWH(
      footprint.left + width * 0.18,
      footprint.top + height * 0.16,
      width * 0.58,
      height * 0.36,
    );
    final labelAnchor = Offset(
      footprint.left + (base.labelOnLeft ? -0.08 : width + 0.05),
      footprint.top - 0.06,
    );

    return ZoneLayoutSlot(
      key: base.key,
      visualType: base.visualType,
      footprint: footprint,
      workerField: workerField,
      labelAnchor: labelAnchor,
      labelOnLeft: base.labelOnLeft,
      elevation: base.elevation,
      defaultType: base.defaultType,
      defaultArea: base.defaultArea,
    );
  }

  List<EventLog> _eventsForZone(ZoneSummary zone, List<EventLog> events) {
    final zoneName = _normalize(zone.name);
    final related = events.where((event) {
      final candidate = _normalize(event.zoneName ?? '');
      return candidate.isNotEmpty &&
          (candidate == zoneName ||
              candidate.contains(zoneName) ||
              zoneName.contains(candidate));
    }).toList();

    related.sort((a, b) => (b.createdAt ?? DateTime(1970))
        .compareTo(a.createdAt ?? DateTime(1970)));
    return related;
  }

  List<MapWorkerMarker> _buildWorkersForZone({
    required ZoneSummary zone,
    required ZoneLayoutSlot slot,
    required Map<String, User> userById,
    required Map<String, DeviceRecord> deviceByMac,
  }) {
    final markers = <MapWorkerMarker>[];
    final seen = <String>{};

    void addWorker({
      required String id,
      required String name,
      String? avatarUrl,
      String? role,
      String? locationLabel,
      String? deviceLabel,
      required String status,
    }) {
      final workerId = id.isEmpty ? name : id;
      if (!seen.add(workerId)) return;
      final generated = _workerOffset(
        workerId,
        slot.workerField,
      );
      markers.add(
        MapWorkerMarker(
          id: workerId,
          name: name,
          status: status,
          avatarUrl: avatarUrl,
          role: role,
          locationLabel: locationLabel,
          offsetDx: generated.dx,
          offsetDy: generated.dy,
          deviceLabel: deviceLabel,
        ),
      );
    }

    for (final device in deviceByMac.values) {
      final matchesById = device.zoneId != null &&
          device.zoneId!.isNotEmpty &&
          device.zoneId == zone.id;
      final matchesByName = _matchesZone(device.zoneName, zone.name);
      if (!matchesById && !matchesByName) continue;

      final user = userById[device.ownerId];
      if (user == null) continue;

      addWorker(
        id: user.id.isNotEmpty ? user.id : device.id,
        name: user.name.isNotEmpty
            ? user.name
            : device.label.trim().isNotEmpty
                ? device.label
                : 'Monitored device',
        avatarUrl: user.pictureUrl,
        role: user.role,
        locationLabel: device.zoneName ?? zone.name,
        deviceLabel: device.label,
        status: _statusFromDeviceStatus(device.status),
      );
    }

    return markers;
  }

  Offset _workerOffset(
    String seed,
    Rect field, {
    double? preferredX,
    double? preferredY,
  }) {
    final left = field.left;
    final top = field.top;
    final width = field.width;
    final height = field.height;

    if (preferredX != null && preferredY != null) {
      return Offset(
        left + preferredX.clamp(0, 1) * width,
        top + preferredY.clamp(0, 1) * height,
      );
    }

    final hash = seed.runes.fold<int>(0, (sum, char) => sum + char);
    final dx = ((hash % 11) / 10) * width;
    final dy = (((hash ~/ 11) % 7) / 6) * height;
    return Offset(left + dx, top + dy);
  }

  bool _matchesZone(String? location, String zoneName) {
    if (location == null || location.trim().isEmpty) return false;
    final normalizedLocation = _normalize(location);
    final normalizedZone = _normalize(zoneName);
    return normalizedLocation.contains(normalizedZone) ||
        normalizedZone.contains(normalizedLocation);
  }

  String _statusForZone(
    String? explicitStatus,
    int safeCount,
    int warningCount,
    int emergencyCount,
  ) {
    final normalized = explicitStatus?.trim().toLowerCase();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    if (emergencyCount > 0) return 'emergency';
    if (warningCount > 0) return 'warning';
    if (safeCount > 0) return 'safe';
    return 'offline';
  }

  Color _statusColor(String status, Brightness brightness) {
    switch (status) {
      case 'emergency':
        return brightness == Brightness.dark
            ? const Color(0xFFFF4343)
            : const Color(0xFFF04438);
      case 'warning':
        return brightness == Brightness.dark
            ? const Color(0xFFFFA320)
            : const Color(0xFFF79009);
      case 'offline':
        return brightness == Brightness.dark
            ? const Color(0xFF9AA4B2)
            : const Color(0xFF98A2B3);
      default:
        return brightness == Brightness.dark
            ? const Color(0xFF22D96B)
            : const Color(0xFF16A34A);
    }
  }

  String _statusFromDeviceStatus(String status) {
    switch (status.toUpperCase()) {
      case 'SOS':
      case 'EMERGENCY':
      case 'ACCESS_DENIED':
        return 'emergency';
      case 'OFFLINE':
        return 'offline';
      case 'WARNING':
        return 'warning';
      default:
        return 'safe';
    }
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
