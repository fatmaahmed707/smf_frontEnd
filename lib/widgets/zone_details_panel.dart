import 'package:flutter/material.dart';

import '../models/map_zone_view_model.dart';
import 'campus_map_canvas.dart';
import 'worker_marker_chip.dart';

class ZoneDetailsPanel extends StatelessWidget {
  final MapZoneViewModel zone;
  final CampusMapPalette palette;

  const ZoneDetailsPanel({
    super.key,
    required this.zone,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Workers', zone.workersCount.toString(), palette.accentBlue),
      ('Safe', zone.safeCount.toString(), palette.metricSafe),
      ('Warning', zone.warningCount.toString(), palette.metricWarning),
      ('Emergency', zone.emergencyCount.toString(), palette.metricEmergency),
    ];

    return Container(
      width: 380,
      constraints: const BoxConstraints(maxHeight: 640),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.panelBorder),
        boxShadow: [
          BoxShadow(
            color: palette.panelShadow.withValues(alpha: 0.22),
            blurRadius: 36,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      zone.area,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: zone.statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  zone.status.toUpperCase(),
                  style: TextStyle(
                    color: zone.statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map(
                  (metric) => Container(
                    width: 150,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: metric.$3.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: metric.$3.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.$1,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          metric.$2,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          if (zone.latestEvent != null) ...[
            Text(
              'Latest Event',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.track,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.panelBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.latestEvent!.eventType,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    zone.latestEvent!.message ?? zone.latestEvent!.macAddress,
                    style: TextStyle(
                      color: palette.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            'Workers',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: zone.workers.isEmpty
                ? Center(
                    child: Text(
                      'No workers mapped to this zone yet.',
                      style: TextStyle(color: palette.textMuted),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: zone.workers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final worker = zone.workers[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.track,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: palette.panelBorder),
                        ),
                        child: Row(
                          children: [
                            WorkerMarkerChip(
                              worker: worker,
                              palette: palette,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    worker.name,
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    worker.locationLabel ??
                                        worker.role ??
                                        'On-site worker',
                                    style: TextStyle(
                                      color: palette.textMuted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _workerStatusColor(worker.status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                worker.status.toUpperCase(),
                                style: TextStyle(
                                  color: _workerStatusColor(worker.status),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _workerStatusColor(String status) {
    switch (status) {
      case 'emergency':
        return palette.metricEmergency;
      case 'warning':
        return palette.metricWarning;
      case 'offline':
        return palette.metricOffline;
      default:
        return palette.metricSafe;
    }
  }
}
