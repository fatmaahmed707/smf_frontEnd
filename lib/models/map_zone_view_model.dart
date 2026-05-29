import 'dart:ui';

import 'event_log.dart';
import 'map_worker_marker.dart';
import 'zone_layout_slot.dart';

class MapZoneViewModel {
  final String id;
  final String name;
  final String type;
  final String area;
  final int workersCount;
  final int safeCount;
  final int warningCount;
  final int emergencyCount;
  final String status;
  final Color statusColor;
  final ZoneLayoutSlot layoutSlot;
  final EventLog? latestEvent;
  final List<MapWorkerMarker> workers;

  const MapZoneViewModel({
    required this.id,
    required this.name,
    required this.type,
    required this.area,
    required this.workersCount,
    required this.safeCount,
    required this.warningCount,
    required this.emergencyCount,
    required this.status,
    required this.statusColor,
    required this.layoutSlot,
    required this.latestEvent,
    required this.workers,
  });
}
