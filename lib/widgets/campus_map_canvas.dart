import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../models/map_zone_view_model.dart';

class CampusMapPalette {
  final Color pageBackground;
  final Color panelBackground;
  final Color panelBorder;
  final Color panelShadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color track;
  final Color campusGrass;
  final Color campusGround;
  final Color campusRoad;
  final Color campusRoadLine;
  final Color buildingRoof;
  final Color buildingWall;
  final Color buildingAccent;
  final Color glow;
  final Color metricSafe;
  final Color metricWarning;
  final Color metricEmergency;
  final Color metricOffline;
  final Color accentBlue;

  const CampusMapPalette({
    required this.pageBackground,
    required this.panelBackground,
    required this.panelBorder,
    required this.panelShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.track,
    required this.campusGrass,
    required this.campusGround,
    required this.campusRoad,
    required this.campusRoadLine,
    required this.buildingRoof,
    required this.buildingWall,
    required this.buildingAccent,
    required this.glow,
    required this.metricSafe,
    required this.metricWarning,
    required this.metricEmergency,
    required this.metricOffline,
    required this.accentBlue,
  });

  factory CampusMapPalette.fromBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const CampusMapPalette(
        pageBackground: Color(0xFF070D18),
        panelBackground: Color(0xFF0B1220),
        panelBorder: Color(0xFF202A3B),
        panelShadow: Color(0x99000000),
        textPrimary: Color(0xFFF5F7FB),
        textSecondary: Color(0xFFE6EAF2),
        textMuted: Color(0xFF8E99AE),
        track: Color(0xFF0F1728),
        campusGrass: Color(0xFF11281A),
        campusGround: Color(0xFF1B2432),
        campusRoad: Color(0xFF222B39),
        campusRoadLine: Color(0x66FFFFFF),
        buildingRoof: Color(0xFF313845),
        buildingWall: Color(0xFF6D5D4D),
        buildingAccent: Color(0xFFF0C992),
        glow: Color(0xFF0E73FF),
        metricSafe: Color(0xFF22D96B),
        metricWarning: Color(0xFFFFA320),
        metricEmergency: Color(0xFFFF4343),
        metricOffline: Color(0xFF9AA4B2),
        accentBlue: Color(0xFF2E8BFF),
      );
    }

    return const CampusMapPalette(
      pageBackground: Color(0xFFF6F9FF),
      panelBackground: Color(0xFFFFFFFF),
      panelBorder: Color(0xFFDDE5F2),
      panelShadow: Color(0x140F1B2D),
      textPrimary: Color(0xFF101828),
      textSecondary: Color(0xFF0F172A),
      textMuted: Color(0xFF667085),
      track: Color(0xFFF5F7FB),
      campusGrass: Color(0xFFCFE8B5),
      campusGround: Color(0xFFF2F5F7),
      campusRoad: Color(0xFFCBD5E1),
      campusRoadLine: Color(0x99FFFFFF),
      buildingRoof: Color(0xFFB8BEC8),
      buildingWall: Color(0xFFD7C4AB),
      buildingAccent: Color(0xFFE7D8B9),
      glow: Color(0xFF4DA0FF),
      metricSafe: Color(0xFF16A34A),
      metricWarning: Color(0xFFF79009),
      metricEmergency: Color(0xFFF04438),
      metricOffline: Color(0xFF98A2B3),
      accentBlue: Color(0xFF2E8BFF),
    );
  }
}

class CampusMapCanvas extends StatelessWidget {
  final CampusMapPalette palette;
  final List<MapZoneViewModel> zones;
  final Widget child;

  const CampusMapCanvas({
    super.key,
    required this.palette,
    required this.zones,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.42,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.panelBackground,
              palette.pageBackground,
            ],
          ),
          border: Border.all(color: palette.panelBorder),
          boxShadow: [
            BoxShadow(
              color: palette.panelShadow,
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _CampusScenePainter(
            palette: palette,
            zones: zones,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CampusScenePainter extends CustomPainter {
  final CampusMapPalette palette;
  final List<MapZoneViewModel> zones;

  const _CampusScenePainter({
    required this.palette,
    required this.zones,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.track,
          palette.pageBackground,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final haze = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.12, 0.08),
        radius: 0.9,
        colors: [
          palette.glow.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, haze);

    final campus = Path()
      ..moveTo(size.width * 0.12, size.height * 0.68)
      ..lineTo(size.width * 0.33, size.height * 0.16)
      ..lineTo(size.width * 0.87, size.height * 0.26)
      ..lineTo(size.width * 0.74, size.height * 0.90)
      ..close();

    final campusFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.campusGrass.withValues(alpha: 0.82),
          palette.campusGround.withValues(alpha: 0.92),
        ],
      ).createShader(rect);
    canvas.drawPath(campus, campusFill);

    final campusStroke = Paint()
      ..color = palette.panelBorder.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(campus, campusStroke);

    _drawRoads(canvas, size);
    _drawTrees(canvas, size);
    _drawFoundations(canvas, size);
  }

  void _drawRoads(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = palette.campusRoad.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = palette.campusRoadLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final verticalRoad = Path()
      ..moveTo(size.width * 0.54, size.height * 0.16)
      ..lineTo(size.width * 0.57, size.height * 0.17)
      ..lineTo(size.width * 0.48, size.height * 0.86)
      ..lineTo(size.width * 0.44, size.height * 0.84)
      ..close();
    canvas.drawPath(verticalRoad, roadPaint);

    final crossRoad = Path()
      ..moveTo(size.width * 0.16, size.height * 0.58)
      ..lineTo(size.width * 0.73, size.height * 0.72)
      ..lineTo(size.width * 0.75, size.height * 0.79)
      ..lineTo(size.width * 0.14, size.height * 0.65)
      ..close();
    canvas.drawPath(crossRoad, roadPaint);

    for (var step = 0; step < 18; step++) {
      final t = step / 17;
      final x1 = lerpDouble(size.width * 0.55, size.width * 0.46, t)!;
      final y1 = lerpDouble(size.height * 0.18, size.height * 0.84, t)!;
      final x2 = lerpDouble(size.width * 0.57, size.width * 0.48, t)!;
      final y2 = lerpDouble(size.height * 0.18, size.height * 0.85, t)!;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }
  }

  void _drawTrees(Canvas canvas, Size size) {
    final treePaint = Paint()
      ..color = palette.campusGrass.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final treeShadow = Paint()
      ..color = palette.pageBackground.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final random = math.Random(42);
    for (var i = 0; i < 180; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final edgeBias = dx < size.width * 0.15 ||
          dx > size.width * 0.82 ||
          dy < size.height * 0.14 ||
          dy > size.height * 0.88;
      if (!edgeBias) continue;
      final radius = 1.2 + random.nextDouble() * 2.6;
      final center = Offset(dx, dy);
      canvas.drawCircle(center.translate(0, 1.5), radius + 0.6, treeShadow);
      canvas.drawCircle(center, radius, treePaint);
    }
  }

  void _drawFoundations(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = palette.panelShadow.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    for (final zone in zones) {
      final rect = Rect.fromLTWH(
        zone.layoutSlot.footprint.left * size.width,
        zone.layoutSlot.footprint.top * size.height,
        zone.layoutSlot.footprint.width * size.width,
        zone.layoutSlot.footprint.height * size.height,
      );
      final shadow = RRect.fromRectAndRadius(
        rect.shift(Offset(8, 10 + 24 * zone.layoutSlot.elevation)),
        Radius.circular(20 + 12 * zone.layoutSlot.elevation),
      );
      canvas.drawRRect(shadow, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CampusScenePainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.zones != zones;
  }
}
