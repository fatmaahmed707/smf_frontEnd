import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/device_record.dart';
import '../../models/event_log.dart';
import '../../models/user.dart';
import '../../services/devices_service.dart';
import '../../services/events_service.dart';
import '../../services/users_service.dart';
import '../../services/zones_service.dart';
import '../../theme/app_theme.dart';

class EmergencyDashboardPage extends StatefulWidget {
  const EmergencyDashboardPage({super.key});

  @override
  State<EmergencyDashboardPage> createState() => _EmergencyDashboardPageState();
}

class _EmergencyDashboardPageState extends State<EmergencyDashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final EventsService _eventsService = EventsService();
  final DevicesService _devicesService = DevicesService();
  final UsersService _usersService = UsersService();
  final ZonesService _zonesService = ZonesService();
  List<EventLog> _events = const [];
  List<DeviceRecord> _devices = const [];
  List<User> _users = const [];
  int _zoneCount = 1;
  bool _loadedApiData = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _loadEmergencyData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyData() async {
    try {
      final results = await Future.wait<dynamic>([
        _eventsService.getEvents(since: 3600 * 24),
        _devicesService.getDevices(),
        _usersService.getUsers(),
        _zonesService.getZones(),
      ]);
      if (!mounted) return;
      setState(() {
        _events = results[0] as List<EventLog>;
        _devices = results[1] as List<DeviceRecord>;
        _users = results[2] as List<User>;
        _zoneCount = (results[3] as List).length;
        _loadedApiData = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadedApiData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _EmergencyPalette(
      Theme.of(context).brightness == Brightness.dark,
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.page, palette.pageAlt],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, compact ? 12 : 16, 20, 20),
            child: compact
                ? _CompactEmergencyBody(
                    palette: palette,
                    pulseController: _pulseController,
                    events: _events,
                    devices: _devices,
                    users: _users,
                    zoneCount: _zoneCount,
                    loadedApiData: _loadedApiData,
                  )
                : _DesktopEmergencyBody(
                    palette: palette,
                    pulseController: _pulseController,
                    events: _events,
                    devices: _devices,
                    users: _users,
                    zoneCount: _zoneCount,
                    loadedApiData: _loadedApiData,
                  ),
          );
        },
      ),
    );
  }
}

class _DesktopEmergencyBody extends StatelessWidget {
  final _EmergencyPalette palette;
  final AnimationController pulseController;
  final List<EventLog> events;
  final List<DeviceRecord> devices;
  final List<User> users;
  final int zoneCount;
  final bool loadedApiData;

  const _DesktopEmergencyBody({
    required this.palette,
    required this.pulseController,
    required this.events,
    required this.devices,
    required this.users,
    required this.zoneCount,
    required this.loadedApiData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _EmergencyBanner(
            palette: palette,
            pulseController: pulseController,
          ),
          const SizedBox(height: 18),
          _StatsRow(
            palette: palette,
            events: events,
            devices: devices,
            zoneCount: zoneCount,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 56,
                child: Column(
                  children: [
                    SizedBox(
                      height: 280,
                      child: _LiveMapCard(palette: palette),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 220,
                            child: _PersonnelCard(
                              palette: palette,
                              users: users,
                              devices: devices,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: SizedBox(
                            height: 220,
                            child: _ContactsCard(palette: palette),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 50,
                child: Column(
                  children: [
                    SizedBox(
                      height: 260,
                      child: _ActiveIncidentCard(
                        palette: palette,
                        events: events,
                        loadedApiData: loadedApiData,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 250,
                      child: _IncidentFeedCard(
                        palette: palette,
                        events: events,
                        loadedApiData: loadedApiData,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SystemStrip(
            palette: palette,
            loadedApiData: loadedApiData,
            devices: devices,
          ),
        ],
      ),
    );
  }
}

class _CompactEmergencyBody extends StatelessWidget {
  final _EmergencyPalette palette;
  final AnimationController pulseController;
  final List<EventLog> events;
  final List<DeviceRecord> devices;
  final List<User> users;
  final int zoneCount;
  final bool loadedApiData;

  const _CompactEmergencyBody({
    required this.palette,
    required this.pulseController,
    required this.events,
    required this.devices,
    required this.users,
    required this.zoneCount,
    required this.loadedApiData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _EmergencyBanner(
            palette: palette,
            pulseController: pulseController,
          ),
          const SizedBox(height: 14),
          _StatsRow(
            palette: palette,
            events: events,
            devices: devices,
            zoneCount: zoneCount,
          ),
          const SizedBox(height: 14),
          SizedBox(height: 250, child: _LiveMapCard(palette: palette)),
          const SizedBox(height: 14),
          SizedBox(
            height: 280,
            child: _ActiveIncidentCard(
              palette: palette,
              events: events,
              loadedApiData: loadedApiData,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: _IncidentFeedCard(
              palette: palette,
              events: events,
              loadedApiData: loadedApiData,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: _PersonnelCard(
              palette: palette,
              users: users,
              devices: devices,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 220, child: _ContactsCard(palette: palette)),
          const SizedBox(height: 14),
          _SystemStrip(
            palette: palette,
            loadedApiData: loadedApiData,
            devices: devices,
          ),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  final _EmergencyPalette palette;
  final AnimationController pulseController;

  const _EmergencyBanner({
    required this.palette,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final glow = 0.18 + pulseController.value * 0.18;
        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.redDark.withValues(alpha: 0.45),
                palette.card,
                palette.redDark.withValues(alpha: 0.36),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.red.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: palette.red.withValues(alpha: glow),
                blurRadius: 22,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.red.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: palette.red.withValues(alpha: 0.85)),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: palette.redHot, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMERGENCY MODE ACTIVE',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alert Level 2   •   Teams Notified',
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _BannerAction(
                palette: palette,
                icon: Icons.warning_amber_rounded,
                label: 'ALL UNITS RESPOND',
              ),
              _BannerAction(
                palette: palette,
                icon: Icons.local_fire_department_outlined,
                label: 'EMERGENCY SERVICES DISPATCHED',
              ),
              const SizedBox(width: 18),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Time Elapsed',
                      style: TextStyle(color: palette.muted, fontSize: 10)),
                  Text(
                    '02:34',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              CustomPaint(
                size: const Size(72, 32),
                painter: _HeartbeatPainter(color: palette.redHot),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _EmergencyPalette palette;
  final List<EventLog> events;
  final List<DeviceRecord> devices;
  final int zoneCount;

  const _StatsRow({
    required this.palette,
    required this.events,
    required this.devices,
    required this.zoneCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 520
                ? 2
                : 1;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final activeEvents = events.where(_isEmergencyEvent).length;
        final onlineDevices = devices
            .where((device) => device.status.toLowerCase() == 'online')
            .length;
        final cards = [
          _StatSpec('Zones', zoneCount.toString(), 'Monitored',
              LucideIcons.mapPin, palette.blue),
          _StatSpec('Events', activeEvents.toString(), 'Last 24 hours',
              LucideIcons.clock, activeEvents > 0 ? palette.red : palette.blue),
          _StatSpec('Units Deployed', onlineDevices.toString(), 'Online',
              LucideIcons.users, palette.blue),
          _StatSpec('Status', 'ACTIVE', 'All Systems Operational',
              LucideIcons.radio, palette.red),
        ];
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(
                    width: itemWidth,
                    height: 116,
                    child: _StatCard(palette: palette, spec: card),
                  ))
              .toList(),
        );
      },
    );
  }

  bool _isEmergencyEvent(EventLog event) {
    final normalized = event.eventType.toLowerCase();
    return normalized.contains('alert') ||
        normalized.contains('sos') ||
        normalized.contains('breach') ||
        normalized.contains('violation') ||
        normalized.contains('unauthorized');
  }
}

class _LiveMapCard extends StatelessWidget {
  final _EmergencyPalette palette;

  const _LiveMapCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      palette: palette,
      title: 'Live Situation Map',
      trailing: _MiniButton(palette: palette, label: 'View Full Map'),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  palette.page.withValues(alpha: 0.28),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/images/isometric_factory_map.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _SituationMapPainter(palette: palette),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 10,
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _MapLegendDot('Incident Location', palette.red),
                _MapLegendDot('Units', palette.blue),
                _MapLegendDot('Personnel', palette.green),
                _MapLegendDot('Cameras', palette.gold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveIncidentCard extends StatelessWidget {
  final _EmergencyPalette palette;
  final List<EventLog> events;
  final bool loadedApiData;

  const _ActiveIncidentCard({
    required this.palette,
    required this.events,
    required this.loadedApiData,
  });

  @override
  Widget build(BuildContext context) {
    final incident = _primaryIncident(events);
    return _Panel(
      palette: palette,
      title: 'Active Incident',
      titleIcon: Icons.warning_amber_rounded,
      titleColor: palette.redHot,
      trailing: _PriorityPill(palette: palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: palette.redHot, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.$1,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.$2,
                      style: TextStyle(color: palette.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      incident.$3,
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          _IncidentProgress(palette: palette),
        ],
      ),
    );
  }

  (String, String, String) _primaryIncident(List<EventLog> events) {
    if (events.isEmpty) {
      if (loadedApiData) {
        return (
          'No active incident',
          'Backend event stream is clear',
          'No emergency events reported in the selected window',
        );
      }
      return (
        'Security Breach Detected',
        'Main Entrance - Zone 1',
        'Reported 08:42 AM   -   Incident ID: INC-2025-0017',
      );
    }
    final event = events.firstWhere(
      (item) => _isEmergencyEvent(item),
      orElse: () => events.first,
    );
    final title = event.message ?? _titleFromEventType(event.eventType);
    final location = event.zoneName ??
        (event.macAddress.isNotEmpty ? event.macAddress : 'SMF event stream');
    final timestamp = event.createdAt == null
        ? 'time unavailable'
        : event.createdAt!.toLocal().toString().split('.').first;
    return (
      title,
      location,
      'Reported $timestamp   -   Incident ID: ${event.id}'
    );
  }

  bool _isEmergencyEvent(EventLog event) {
    final normalized = event.eventType.toLowerCase();
    return normalized.contains('alert') ||
        normalized.contains('sos') ||
        normalized.contains('breach') ||
        normalized.contains('violation') ||
        normalized.contains('unauthorized');
  }
}

class _IncidentFeedCard extends StatelessWidget {
  final _EmergencyPalette palette;
  final List<EventLog> events;
  final bool loadedApiData;

  const _IncidentFeedCard({
    required this.palette,
    required this.events,
    required this.loadedApiData,
  });

  @override
  Widget build(BuildContext context) {
    final feedEvents = events.isEmpty && !loadedApiData
        ? [
            (
              '08:42 AM',
              'Security breach detected at Main Entrance',
              'Zone 1',
              palette.red,
              Icons.warning_amber_rounded
            ),
            (
              '08:43 AM',
              'Response team dispatched',
              'Unit 3',
              palette.blue,
              Icons.directions_car_filled_outlined
            ),
            (
              '08:44 AM',
              'Unit 3 en route to incident location',
              '2 min ago',
              palette.green,
              Icons.route_rounded
            ),
            (
              '08:45 AM',
              'CCTV recording initiated',
              'Main Entrance Camera',
              palette.gold,
              Icons.videocam_outlined
            ),
          ]
        : events.take(8).map((event) {
            final normalized = event.eventType.toLowerCase();
            final color = normalized.contains('sos') ||
                    normalized.contains('alert') ||
                    normalized.contains('breach')
                ? palette.red
                : normalized.contains('device')
                    ? palette.gold
                    : palette.blue;
            final icon = normalized.contains('device')
                ? Icons.memory_rounded
                : normalized.contains('zone')
                    ? Icons.place_rounded
                    : Icons.warning_amber_rounded;
            return (
              _timeLabel(event.createdAt),
              event.message ?? _titleFromEventType(event.eventType),
              event.zoneName ??
                  (event.macAddress.isEmpty
                      ? 'SMF event stream'
                      : event.macAddress),
              color,
              icon,
            );
          }).toList();
    return _Panel(
      palette: palette,
      title: 'Incident Feed',
      trailing: _MiniButton(palette: palette, label: 'View All'),
      child: feedEvents.isEmpty
          ? Center(
              child: Text(
                'No backend incidents found',
                style: TextStyle(
                  color: palette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: feedEvents.length,
              separatorBuilder: (_, __) =>
                  Divider(color: palette.line, height: 1),
              itemBuilder: (context, index) {
                final event = feedEvents[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: event.$4.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: event.$4.withValues(alpha: 0.6)),
                        ),
                        child: Icon(event.$5, color: event.$4, size: 17),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 58,
                        child: Text(event.$1,
                            style:
                                TextStyle(color: palette.muted, fontSize: 11)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              event.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(color: palette.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _timeLabel(DateTime? createdAt) {
    if (createdAt == null) return '--:--';
    final local = createdAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _PersonnelCard extends StatelessWidget {
  final _EmergencyPalette palette;
  final List<User> users;
  final List<DeviceRecord> devices;

  const _PersonnelCard({
    required this.palette,
    required this.users,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    final assignedUsers = users.take(2).toList();
    return _Panel(
      palette: palette,
      title: 'Emergency Personnel',
      trailing: _MiniButton(palette: palette, label: 'View All'),
      child: Column(
        children: assignedUsers.isEmpty
            ? [
                _PersonTile(
                  palette: palette,
                  initials: 'JL',
                  name: 'Jessica Lee',
                  meta: 'Zone 1  -  125 BPM',
                  color: palette.red,
                ),
                Divider(color: palette.line, height: 1),
                _PersonTile(
                  palette: palette,
                  initials: 'MS',
                  name: 'Michael Smith',
                  meta: 'Zone 2  -  95 BPM',
                  color: palette.gold,
                ),
              ]
            : [
                for (var i = 0; i < assignedUsers.length; i++) ...[
                  _PersonTile(
                    palette: palette,
                    initials: _initials(assignedUsers[i].name),
                    name: assignedUsers[i].name.isEmpty
                        ? assignedUsers[i].email
                        : assignedUsers[i].name,
                    meta:
                        '${devices.length} devices visible  -  ${assignedUsers[i].role ?? 'USER'}',
                    color: i == 0 ? palette.red : palette.gold,
                  ),
                  if (i != assignedUsers.length - 1)
                    Divider(color: palette.line, height: 1),
                ],
              ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final value = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return value.isEmpty ? 'U' : value;
  }
}

class _ContactsCard extends StatelessWidget {
  final _EmergencyPalette palette;

  const _ContactsCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      palette: palette,
      title: 'Emergency Contacts',
      trailing: _MiniButton(palette: palette, label: 'View All'),
      child: Column(
        children: [
          _ContactTile(
            palette: palette,
            icon: Icons.call_rounded,
            title: 'Emergency Services',
            subtitle: '911',
          ),
          Divider(color: palette.line, height: 1),
          _ContactTile(
            palette: palette,
            icon: Icons.shield_rounded,
            title: 'Security Team',
            subtitle: '+1-555-0123',
          ),
        ],
      ),
    );
  }
}

class _SystemStrip extends StatelessWidget {
  final _EmergencyPalette palette;
  final bool loadedApiData;
  final List<DeviceRecord> devices;

  const _SystemStrip({
    required this.palette,
    required this.loadedApiData,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    final networkStatus = loadedApiData ? 'Synced' : 'Fallback';
    final onlineDevices = devices
        .where((device) => device.status.toLowerCase() == 'online')
        .length;
    final items = [
      (
        'System Status',
        networkStatus,
        Icons.wifi_rounded,
        loadedApiData ? palette.green : palette.gold
      ),
      ('Communication', 'Encrypted', Icons.lock_outline_rounded, palette.muted),
      ('Devices', '$onlineDevices online', Icons.memory_rounded, palette.blue),
      (
        'Network',
        loadedApiData ? 'Stable' : 'Waiting',
        Icons.signal_cellular_alt_rounded,
        palette.green
      ),
      ('Last Updated', _clockLabel(), Icons.refresh_rounded, palette.blue),
    ];
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: items[i].$4.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(items[i].$3, color: items[i].$4, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          items[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: items[i].$4, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i != items.length - 1) VerticalDivider(color: palette.line),
          ],
        ],
      ),
    );
  }
}

String _titleFromEventType(String eventType) {
  final cleaned = eventType
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return 'Security event';
  return cleaned
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

String _clockLabel() {
  final now = DateTime.now();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final second = now.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}

class _Panel extends StatelessWidget {
  final _EmergencyPalette palette;
  final String title;
  final Widget child;
  final Widget? trailing;
  final IconData? titleIcon;
  final Color? titleColor;

  const _Panel({
    required this.palette,
    required this.title,
    required this.child,
    this.trailing,
    this.titleIcon,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, color: titleColor ?? palette.blue, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _EmergencyPalette palette;
  final _StatSpec spec;

  const _StatCard({required this.palette, required this.spec});

  @override
  Widget build(BuildContext context) {
    final active = spec.value == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? palette.redDark.withValues(alpha: 0.32) : palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? palette.red.withValues(alpha: 0.55) : palette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(color: spec.color.withValues(alpha: 0.35)),
            ),
            child: Icon(spec.icon, color: spec.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.label,
                    style: TextStyle(color: palette.muted, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  spec.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? palette.redHot : palette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    spec.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final _EmergencyPalette palette;
  final String initials;
  final String name;
  final String meta;
  final Color color;

  const _PersonTile({
    required this.palette,
    required this.initials,
    required this.name,
    required this.meta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Text(
              initials,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: palette.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                Text(meta,
                    style: TextStyle(color: palette.muted, fontSize: 10.5)),
              ],
            ),
          ),
          _SmallIconButton(palette: palette, icon: Icons.call_outlined),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final _EmergencyPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;

  const _ContactTile({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.red.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: palette.redHot, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: palette.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: TextStyle(color: palette.muted, fontSize: 10.5)),
              ],
            ),
          ),
          _SmallIconButton(palette: palette, icon: Icons.call_outlined),
        ],
      ),
    );
  }
}

class _IncidentProgress extends StatelessWidget {
  final _EmergencyPalette palette;

  const _IncidentProgress({required this.palette});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Reported', '08:42 AM', true),
      ('Dispatched', '08:43 AM', true),
      ('En Route', '', false),
      ('On Scene', '', false),
    ];
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: steps[i].$3 ? palette.red : palette.line,
                    child: Icon(
                      steps[i].$3 ? Icons.check_rounded : Icons.circle,
                      color: Colors.white,
                      size: steps[i].$3 ? 13 : 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i].$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 9),
                  ),
                  Text(
                    steps[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.text, fontSize: 8),
                  ),
                ],
              ),
            ),
            if (i != steps.length - 1)
              Expanded(
                child: Divider(
                  color: steps[i].$3 ? palette.red : palette.line,
                  thickness: 1.5,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ignore: unused_element
class _LanguagePill extends StatelessWidget {
  final _EmergencyPalette palette;

  const _LanguagePill({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Text('EN',
              style: TextStyle(
                  color: palette.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: 14),
          Text('عربي',
              style: TextStyle(
                  color: palette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _NotificationBell extends StatelessWidget {
  final _EmergencyPalette palette;

  const _NotificationBell({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _SquareIconButton(
          palette: palette,
          icon: Icons.notifications_none_rounded,
          onPressed: () {},
        ),
        Positioned(
          right: -4,
          top: -6,
          child: CircleAvatar(
            radius: 9,
            backgroundColor: palette.redHot,
            child: const Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final _EmergencyPalette palette;
  final IconData icon;
  final VoidCallback onPressed;

  const _SquareIconButton({
    required this.palette,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          backgroundColor: palette.card,
          side: BorderSide(color: palette.border),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final _EmergencyPalette palette;
  final IconData icon;

  const _SmallIconButton({required this.palette, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: palette.control,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: palette.border),
      ),
      child: Icon(icon, color: palette.muted, size: 15),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final _EmergencyPalette palette;
  final String label;

  const _MiniButton({required this.palette, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: palette.blue.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.blue,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final _EmergencyPalette palette;

  const _PriorityPill({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: palette.red.withValues(alpha: 0.45)),
      ),
      child: Text(
        'High Priority',
        style: TextStyle(
          color: palette.redHot,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BannerAction extends StatelessWidget {
  final _EmergencyPalette palette;
  final IconData icon;
  final String label;

  const _BannerAction({
    required this.palette,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: palette.red.withValues(alpha: 0.24)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.redHot, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: palette.redHot,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _MapLegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9DB2D8),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 8)
        ],
      ),
    );
  }
}

class _SituationMapPainter extends CustomPainter {
  final _EmergencyPalette palette;

  const _SituationMapPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final incident = Offset(size.width * 0.57, size.height * 0.54);
    for (var i = 4; i >= 1; i--) {
      canvas.drawCircle(
        incident,
        i * 18,
        Paint()
          ..color = palette.red.withValues(alpha: 0.045)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        incident,
        i * 18,
        Paint()
          ..color = palette.red.withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke,
      );
    }
    _drawNode(canvas, size, incident, palette.red, Icons.warning_rounded);
    _drawNode(canvas, size, Offset(size.width * 0.22, size.height * 0.58),
        palette.green, Icons.directions_bus_rounded);
    _drawNode(canvas, size, Offset(size.width * 0.74, size.height * 0.42),
        palette.green, Icons.directions_bus_rounded);
    _drawNode(canvas, size, Offset(size.width * 0.38, size.height * 0.24),
        palette.blue, Icons.security_rounded);
    _drawNode(canvas, size, Offset(size.width * 0.79, size.height * 0.72),
        palette.gold, Icons.videocam_rounded);
    _drawPath(
        canvas,
        size,
        [
          Offset(size.width * 0.12, size.height * 0.37),
          Offset(size.width * 0.25, size.height * 0.28),
          Offset(size.width * 0.31, size.height * 0.33),
        ],
        palette.redHot);
    _drawPath(
        canvas,
        size,
        [
          Offset(size.width * 0.68, size.height * 0.33),
          Offset(size.width * 0.82, size.height * 0.47),
          Offset(size.width * 0.91, size.height * 0.40),
        ],
        palette.blue);
  }

  void _drawPath(Canvas canvas, Size size, List<Offset> points, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawNode(
    Canvas canvas,
    Size size,
    Offset center,
    Color color,
    IconData icon,
  ) {
    canvas.drawCircle(
      center,
      16,
      Paint()..color = color.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = palette.card
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
          fontSize: 15,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SituationMapPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class _HeartbeatPainter extends CustomPainter {
  final Color color;

  const _HeartbeatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(0, size.height * 0.55);
    for (var i = 1; i < 12; i++) {
      final x = size.width * i / 11;
      final spike = i == 4 || i == 8;
      final y = spike
          ? size.height * 0.14
          : size.height * (0.52 + math.sin(i) * 0.10);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _StatSpec {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  const _StatSpec(
    this.label,
    this.value,
    this.caption,
    this.icon,
    this.color,
  );
}

class _EmergencyPalette {
  final bool isDark;

  const _EmergencyPalette(this.isDark);

  Color get page => isDark ? const Color(0xFF020914) : AppTheme.lightBackground;
  Color get pageAlt =>
      isDark ? const Color(0xFF03182C) : const Color(0xFFEAF4FF);
  Color get card => isDark ? const Color(0xFF061A2F) : Colors.white;
  Color get control =>
      isDark ? const Color(0xFF071F3B) : const Color(0xFFF3F8FF);
  Color get border =>
      isDark ? const Color(0xFF0D4A79) : const Color(0xFFC8DFFF);
  Color get line => isDark ? const Color(0xFF123554) : const Color(0xFFD9E7FA);
  Color get text => isDark ? Colors.white : const Color(0xFF061B44);
  Color get muted => isDark ? const Color(0xFF9DB2D8) : const Color(0xFF577099);
  Color get shadow => isDark
      ? Colors.black.withValues(alpha: 0.22)
      : const Color(0xFF9CC9FF).withValues(alpha: 0.18);
  Color get blue => const Color(0xFF0EA5FF);
  Color get green => const Color(0xFF18D47B);
  Color get gold => const Color(0xFFFFB020);
  Color get red => const Color(0xFFE53935);
  Color get redHot => const Color(0xFFFF4040);
  Color get redDark => const Color(0xFF4D0B14);
}
