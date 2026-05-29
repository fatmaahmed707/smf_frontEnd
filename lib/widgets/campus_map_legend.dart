import 'package:flutter/material.dart';

import 'campus_map_canvas.dart';

class CampusMapLegend extends StatelessWidget {
  final CampusMapPalette palette;

  const CampusMapLegend({
    super.key,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Safe', palette.metricSafe),
      ('Warning', palette.metricWarning),
      ('Emergency', palette.metricEmergency),
      ('Offline', palette.metricOffline),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: palette.panelBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.panelBorder),
        boxShadow: [
          BoxShadow(
            color: palette.panelShadow.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: items
            .map(
              (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.$2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.$1,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
