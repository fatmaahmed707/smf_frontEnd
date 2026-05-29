import 'dart:ui';

enum ZoneVisualType {
  building,
  court,
  gate,
  restricted,
  assembly,
  utility,
  generic,
}

class ZoneLayoutSlot {
  final String key;
  final ZoneVisualType visualType;
  final Rect footprint;
  final Rect workerField;
  final Offset labelAnchor;
  final bool labelOnLeft;
  final double elevation;
  final String defaultType;
  final String defaultArea;

  const ZoneLayoutSlot({
    required this.key,
    required this.visualType,
    required this.footprint,
    required this.workerField,
    required this.labelAnchor,
    required this.labelOnLeft,
    required this.elevation,
    required this.defaultType,
    required this.defaultArea,
  });
}
