import 'dart:ui';

import '../models/zone_layout_slot.dart';

class ZoneLayoutRegistry {
  const ZoneLayoutRegistry._();

  static const List<ZoneLayoutSlot> _primarySlots = [
    ZoneLayoutSlot(
      key: 'building_a',
      visualType: ZoneVisualType.building,
      footprint: Rect.fromLTWH(0.39, 0.14, 0.21, 0.21),
      workerField: Rect.fromLTWH(0.42, 0.16, 0.16, 0.13),
      labelAnchor: Offset(0.40, 0.05),
      labelOnLeft: true,
      elevation: 0.22,
      defaultType: 'Building A',
      defaultArea: 'Production Area',
    ),
    ZoneLayoutSlot(
      key: 'building_b',
      visualType: ZoneVisualType.building,
      footprint: Rect.fromLTWH(0.63, 0.17, 0.21, 0.20),
      workerField: Rect.fromLTWH(0.66, 0.19, 0.16, 0.12),
      labelAnchor: Offset(0.73, 0.07),
      labelOnLeft: false,
      elevation: 0.21,
      defaultType: 'Building B',
      defaultArea: 'Assembly Area',
    ),
    ZoneLayoutSlot(
      key: 'building_c',
      visualType: ZoneVisualType.building,
      footprint: Rect.fromLTWH(0.57, 0.40, 0.23, 0.18),
      workerField: Rect.fromLTWH(0.61, 0.42, 0.16, 0.11),
      labelAnchor: Offset(0.88, 0.41),
      labelOnLeft: false,
      elevation: 0.18,
      defaultType: 'Building C',
      defaultArea: 'Maintenance Area',
    ),
    ZoneLayoutSlot(
      key: 'padel_court',
      visualType: ZoneVisualType.court,
      footprint: Rect.fromLTWH(0.20, 0.28, 0.17, 0.13),
      workerField: Rect.fromLTWH(0.23, 0.29, 0.10, 0.08),
      labelAnchor: Offset(0.09, 0.22),
      labelOnLeft: true,
      elevation: 0.04,
      defaultType: 'Padel Court',
      defaultArea: 'Outdoor Area',
    ),
    ZoneLayoutSlot(
      key: 'tennis_court',
      visualType: ZoneVisualType.court,
      footprint: Rect.fromLTWH(0.14, 0.43, 0.21, 0.14),
      workerField: Rect.fromLTWH(0.17, 0.45, 0.14, 0.08),
      labelAnchor: Offset(0.03, 0.46),
      labelOnLeft: true,
      elevation: 0.04,
      defaultType: 'Tennis Court',
      defaultArea: 'Outdoor Area',
    ),
    ZoneLayoutSlot(
      key: 'basketball_court',
      visualType: ZoneVisualType.court,
      footprint: Rect.fromLTWH(0.13, 0.58, 0.21, 0.14),
      workerField: Rect.fromLTWH(0.16, 0.60, 0.13, 0.08),
      labelAnchor: Offset(0.04, 0.67),
      labelOnLeft: true,
      elevation: 0.04,
      defaultType: 'Basketball Court',
      defaultArea: 'Outdoor Area',
    ),
    ZoneLayoutSlot(
      key: 'main_gate',
      visualType: ZoneVisualType.gate,
      footprint: Rect.fromLTWH(0.46, 0.60, 0.18, 0.13),
      workerField: Rect.fromLTWH(0.50, 0.61, 0.10, 0.07),
      labelAnchor: Offset(0.45, 0.52),
      labelOnLeft: true,
      elevation: 0.11,
      defaultType: 'Main Gate',
      defaultArea: 'Security Area',
    ),
    ZoneLayoutSlot(
      key: 'restricted_area',
      visualType: ZoneVisualType.restricted,
      footprint: Rect.fromLTWH(0.68, 0.60, 0.20, 0.15),
      workerField: Rect.fromLTWH(0.71, 0.62, 0.13, 0.09),
      labelAnchor: Offset(0.86, 0.63),
      labelOnLeft: false,
      elevation: 0.05,
      defaultType: 'Restricted Area',
      defaultArea: 'High Security Area',
    ),
    ZoneLayoutSlot(
      key: 'assembly_point',
      visualType: ZoneVisualType.assembly,
      footprint: Rect.fromLTWH(0.47, 0.79, 0.14, 0.12),
      workerField: Rect.fromLTWH(0.50, 0.81, 0.08, 0.06),
      labelAnchor: Offset(0.59, 0.83),
      labelOnLeft: false,
      elevation: 0.03,
      defaultType: 'Assembly Point',
      defaultArea: 'Evacuation Area',
    ),
    ZoneLayoutSlot(
      key: 'utility_building',
      visualType: ZoneVisualType.utility,
      footprint: Rect.fromLTWH(0.72, 0.82, 0.15, 0.11),
      workerField: Rect.fromLTWH(0.75, 0.84, 0.09, 0.05),
      labelAnchor: Offset(0.85, 0.88),
      labelOnLeft: false,
      elevation: 0.10,
      defaultType: 'Utility Building',
      defaultArea: 'Utility Area',
    ),
  ];

  static const List<ZoneLayoutSlot> _fallbackSlots = [
    ZoneLayoutSlot(
      key: 'fallback_north',
      visualType: ZoneVisualType.generic,
      footprint: Rect.fromLTWH(0.31, 0.09, 0.12, 0.09),
      workerField: Rect.fromLTWH(0.33, 0.10, 0.07, 0.04),
      labelAnchor: Offset(0.24, 0.05),
      labelOnLeft: true,
      elevation: 0.08,
      defaultType: 'North Block',
      defaultArea: 'Facility Area',
    ),
    ZoneLayoutSlot(
      key: 'fallback_west',
      visualType: ZoneVisualType.generic,
      footprint: Rect.fromLTWH(0.07, 0.76, 0.15, 0.10),
      workerField: Rect.fromLTWH(0.10, 0.78, 0.08, 0.04),
      labelAnchor: Offset(0.05, 0.87),
      labelOnLeft: true,
      elevation: 0.07,
      defaultType: 'West Block',
      defaultArea: 'Facility Area',
    ),
    ZoneLayoutSlot(
      key: 'fallback_south',
      visualType: ZoneVisualType.generic,
      footprint: Rect.fromLTWH(0.33, 0.86, 0.14, 0.09),
      workerField: Rect.fromLTWH(0.36, 0.88, 0.07, 0.04),
      labelAnchor: Offset(0.28, 0.93),
      labelOnLeft: true,
      elevation: 0.06,
      defaultType: 'South Block',
      defaultArea: 'Facility Area',
    ),
    ZoneLayoutSlot(
      key: 'fallback_east',
      visualType: ZoneVisualType.generic,
      footprint: Rect.fromLTWH(0.86, 0.43, 0.11, 0.10),
      workerField: Rect.fromLTWH(0.88, 0.45, 0.06, 0.04),
      labelAnchor: Offset(0.86, 0.53),
      labelOnLeft: false,
      elevation: 0.08,
      defaultType: 'East Block',
      defaultArea: 'Facility Area',
    ),
  ];

  static final Map<String, String> _aliases = {
    'building a': 'building_a',
    'building b': 'building_b',
    'building c': 'building_c',
    'production area': 'building_a',
    'assembly area': 'building_b',
    'maintenance area': 'building_c',
    'padel court': 'padel_court',
    'tennis court': 'tennis_court',
    'basketball court': 'basketball_court',
    'main gate': 'main_gate',
    'gate': 'main_gate',
    'restricted area': 'restricted_area',
    'assembly point': 'assembly_point',
    'utility building': 'utility_building',
  };

  static List<ZoneLayoutSlot> get primarySlots => _primarySlots;

  static ZoneLayoutSlot? findByZoneName(String name) {
    final normalized = _normalize(name);
    final key = _aliases[normalized];
    if (key == null) return null;
    for (final slot in _primarySlots) {
      if (slot.key == key) return slot;
    }
    return null;
  }

  static ZoneLayoutSlot fallbackAt(int index) {
    return _fallbackSlots[index % _fallbackSlots.length];
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
