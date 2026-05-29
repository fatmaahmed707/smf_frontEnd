import 'dart:math' as math;

import 'package:flutter/material.dart';


import '../models/map_worker_marker.dart';
import 'campus_map_canvas.dart';

class WorkerMarkerChip extends StatelessWidget {
  final MapWorkerMarker worker;
  final CampusMapPalette palette;
  final double size;

  const WorkerMarkerChip({
    super.key,
    required this.worker,
    required this.palette,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (worker.status) {
      'emergency' => palette.metricEmergency,
      'warning' => palette.metricWarning,
      'offline' => palette.metricOffline,
      _ => palette.metricSafe,
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer glass ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.panelBackground.withValues(alpha: 0.35),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.95),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.18),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          // Inner avatar / monogram (slightly smaller)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: worker.avatarUrl != null && worker.avatarUrl!.isNotEmpty
                    ? Image.network(
                        worker.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _MonogramAvatar(
                          name: worker.name,
                          color: statusColor,
                          textColor: palette.textPrimary,
                          size: size,
                        ),
                      )
                    : _MonogramAvatar(
                        name: worker.name,
                        color: statusColor,
                        textColor: palette.textPrimary,
                        size: size,
                      ),
              ),
            ),
          ),
          // Status dot (SOC-style)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: math.max(8, size * 0.18),
              height: math.max(8, size * 0.18),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.pageBackground,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonogramAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final Color textColor;
  final double size;


  const _MonogramAvatar({
    required this.name,
    required this.color,
    required this.textColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? 'W'
        : parts
            .take(2)
            .map((part) => part.substring(0, 1))
            .join()
            .toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}
