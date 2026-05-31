import 'package:flutter/material.dart';

import '../models/map_zone_view_model.dart';
import '../models/zone_layout_slot.dart';
import 'campus_map_canvas.dart';
import 'worker_marker_chip.dart';

class CampusZoneOverlay extends StatelessWidget {
  final MapZoneViewModel zone;
  final CampusMapPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const CampusZoneOverlay({
    super.key,
    required this.zone,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final slot = zone.layoutSlot;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final footprint = Rect.fromLTWH(
            slot.footprint.left * width,
            slot.footprint.top * height,
            slot.footprint.width * width,
            slot.footprint.height * height,
          );

          final labelPosition = Offset(
            slot.labelAnchor.dx * width,
            slot.labelAnchor.dy * height,
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: footprint.left,
                top: footprint.top,
                width: footprint.width,
                height: footprint.height,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: Size(footprint.width, footprint.height),
                          painter: _ZonePainter(
                            zone: zone,
                            palette: palette,
                            selected: selected,
                          ),
                        ),
                        ...zone.workers.take(12).map((worker) {
                          return Positioned(
                            left:
                                (worker.offsetDx - slot.footprint.left) * width,
                            top:
                                (worker.offsetDy - slot.footprint.top) * height,
                            child: WorkerMarkerChip(
                              worker: worker,
                              palette: palette,
                              size: worker.id == zone.workers.firstOrNull?.id
                                  ? 22
                                  : 16,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: slot.labelOnLeft
                    ? labelPosition.dx
                    : labelPosition.dx - 152,
                top: labelPosition.dy,
                width: 152,
                child: _ZoneLabelCard(
                  zone: zone,
                  palette: palette,
                  selected: selected,
                  alignLeft: slot.labelOnLeft,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ZoneLabelCard extends StatelessWidget {
  final MapZoneViewModel zone;
  final CampusMapPalette palette;
  final bool selected;
  final bool alignLeft;

  const _ZoneLabelCard({
    required this.zone,
    required this.palette,
    required this.selected,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ZoneConnectorPainter(
        color: zone.statusColor,
        alignLeft: alignLeft,
      ),
      child: Container(
        margin: EdgeInsets.only(
          left: alignLeft ? 0 : 12,
          right: alignLeft ? 12 : 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.panelBackground.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? zone.statusColor
                : zone.statusColor.withValues(alpha: 0.36),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: zone.statusColor.withValues(alpha: selected ? 0.18 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              zone.name.toUpperCase(),
              textAlign: alignLeft ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: zone.statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 11.8,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              zone.area,
              textAlign: alignLeft ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${zone.workersCount} Workers',
              textAlign: alignLeft ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneConnectorPainter extends CustomPainter {
  final Color color;
  final bool alignLeft;

  const _ZoneConnectorPainter({
    required this.color,
    required this.alignLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final start = alignLeft
        ? Offset(size.width - 6, size.height * 0.36)
        : Offset(6, size.height * 0.36);
    final bend = alignLeft
        ? Offset(size.width + 18, size.height * 0.36)
        : Offset(-18, size.height * 0.36);
    final end = alignLeft
        ? Offset(size.width + 18, size.height * 0.66)
        : Offset(-18, size.height * 0.66);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(bend.dx, bend.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
    canvas.drawCircle(end, 3.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ZoneConnectorPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.alignLeft != alignLeft;
  }
}

class _ZonePainter extends CustomPainter {
  final MapZoneViewModel zone;
  final CampusMapPalette palette;
  final bool selected;

  const _ZonePainter({
    required this.zone,
    required this.palette,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Flat 2D zone rendering (no isometric/3D geometry).
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    final fill = Paint()
      ..color = zone.statusColor.withValues(alpha: selected ? 0.22 : 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fill);

    final stroke = Paint()
      ..color = zone.statusColor.withValues(alpha: selected ? 0.95 : 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.6 : 1.6;
    canvas.drawRRect(rrect, stroke);

    // Minimal interior marker based on visual type.
    final iconPaint = Paint()
      ..color = palette.accentBlue.withValues(alpha: selected ? 0.95 : 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (zone.layoutSlot.visualType) {
      case ZoneVisualType.court:
        canvas.drawLine(Offset(size.width * 0.25, size.height * 0.35),
            Offset(size.width * 0.75, size.height * 0.65), iconPaint);
        break;
      case ZoneVisualType.gate:
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.3, size.height * 0.38, size.width * 0.4,
              size.height * 0.24),
          iconPaint,
        );
        break;
      case ZoneVisualType.restricted:
        canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5),
            size.width * 0.12, iconPaint);
        break;
      case ZoneVisualType.assembly:
        canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5),
            size.width * 0.16, iconPaint);
        break;
      case ZoneVisualType.utility:
        final p = Path()
          ..moveTo(size.width * 0.45, size.height * 0.45)
          ..lineTo(size.width * 0.55, size.height * 0.55)
          ..lineTo(size.width * 0.48, size.height * 0.55)
          ..lineTo(size.width * 0.55, size.height * 0.68);
        canvas.drawPath(p, iconPaint);
        break;
      case ZoneVisualType.generic:
      case ZoneVisualType.building:
        // default interior: two diagonals.
        canvas.drawLine(Offset(size.width * 0.25, size.height * 0.25),
            Offset(size.width * 0.75, size.height * 0.75), iconPaint);
        canvas.drawLine(Offset(size.width * 0.75, size.height * 0.25),
            Offset(size.width * 0.25, size.height * 0.75), iconPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ZonePainter oldDelegate) {
    return oldDelegate.zone != zone ||
        oldDelegate.palette != palette ||
        oldDelegate.selected != selected;
  }
}
