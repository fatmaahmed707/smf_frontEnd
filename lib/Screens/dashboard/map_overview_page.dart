import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/map_zone_mapper.dart';
import '../../models/device_record.dart';
import '../../models/event_log.dart';
import '../../models/map_worker_marker.dart';
import '../../models/map_zone_view_model.dart';
import '../../models/smf_device.dart';
import '../../models/user.dart';
import '../../models/zone_layout_slot.dart';
import '../../models/zone_summary.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../services/devices_service.dart';
import '../../services/events_service.dart';
import '../../services/smf_devices_service.dart';
import '../../services/users_service.dart';
import '../../services/zones_service.dart';
import '../../widgets/campus_map_canvas.dart';
import '../../widgets/worker_marker_chip.dart';
import '../../widgets/zone_details_panel.dart';

String _mapText(BuildContext context, String key) =>
    context.watch<LanguageProvider>().getText(key);

String _mapZoneName(BuildContext context, String value) {
  final lower = value.toLowerCase();
  final lang = context.watch<LanguageProvider>();
  if (lower.contains('zone a')) return lang.getText('zoneAEngineeringOnly');
  if (lower.contains('zone b')) return lang.getText('zoneBEngineeringManager');
  if (lower.contains('zone c')) return lang.getText('zoneCOpenAccess');
  return value;
}

String _mapArea(BuildContext context, String value) {
  final lower = value.toLowerCase();
  final lang = context.watch<LanguageProvider>();
  if (lower.contains('production')) return lang.getText('productionArea');
  if (lower.contains('assembly')) return lang.getText('assemblyArea');
  if (lower.contains('maintenance')) return lang.getText('maintenanceArea');
  return value;
}

String _mapStatus(BuildContext context, String value) {
  final lang = context.watch<LanguageProvider>();
  switch (value.toUpperCase()) {
    case 'SAFE':
      return lang.getText('safe');
    case 'WARNING':
      return lang.getText('warning');
    case 'EMERGENCY':
      return lang.getText('emergency');
    case 'OFFLINE':
      return lang.getText('offline');
    default:
      return value;
  }
}

String _mapRoleName(BuildContext context, String value) {
  final lang = context.watch<LanguageProvider>();
  switch (value.trim().toUpperCase()) {
    case 'ADMIN':
      return lang.getText('roleAdmin');
    case 'ENGINEER':
      return lang.getText('roleEngineer');
    case 'MANAGER':
      return lang.getText('roleManager');
    case 'WORKER':
      return lang.getText('roleWorker');
    case 'ROLE_USER':
      return lang.getText('roleUser');
    default:
      return value;
  }
}

class MapOverviewPage extends StatefulWidget {
  const MapOverviewPage({super.key});

  @override
  State<MapOverviewPage> createState() => _MapOverviewPageState();
}

class _MapOverviewPageState extends State<MapOverviewPage> {
  static const _profileDisplayNameKey = 'profile_display_name';
  final ZonesService _zonesService = ZonesService();
  final UsersService _usersService = UsersService();
  final DevicesService _devicesService = DevicesService();
  final EventsService _eventsService = EventsService();
  final SmfDevicesService _smfDevicesService = SmfDevicesService();
  final MapZoneMapper _mapper = const MapZoneMapper();

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _profileDisplayName;
  Timer? _refreshTimer;

  List<User> _users = const [];
  List<DeviceRecord> _devices = const [];
  List<SmfDevice> _smfDevices = const [];
  List<EventLog> _events = const [];
  List<MapZoneViewModel> _viewZones = const [];

  String? _selectedZoneId;
  String? _selectedWorkerId;

  @override
  void initState() {
    super.initState();
    _loadProfileDisplayName();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isRefreshing) {
        _loadData(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
        () => _profileDisplayName = prefs.getString(_profileDisplayNameKey));
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (_isRefreshing) return;

    final lang = context.read<LanguageProvider>();
    _isRefreshing = true;
    setState(() {
      if (showLoading) {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    List<ZoneSummary> zones = const [];
    List<User> users = const [];
    List<DeviceRecord> devices = const [];
    List<SmfDevice> smfDevices = const [];
    List<EventLog> events = const [];
    String? error;

    try {
      zones = await _zonesService.getZones();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = lang.getText('failedToLoadZones');
    }

    try {
      users = await _usersService.getUsers();
    } on ApiException catch (_) {
      users = const [];
    } catch (_) {
      users = const [];
    }

    try {
      devices = await _devicesService.getDevices();
    } on ApiException catch (_) {
      devices = const [];
    } catch (_) {
      devices = const [];
    }

    try {
      smfDevices = await _smfDevicesService.getAllDevices();
    } on ApiException catch (_) {
      smfDevices = const [];
    } catch (_) {
      smfDevices = const [];
    }

    try {
      events = await _eventsService.getEvents(since: 3600 * 24);
    } on ApiException catch (_) {
      events = const [];
    } catch (_) {
      events = const [];
    }

    if (!mounted) {
      _isRefreshing = false;
      return;
    }

    final brightness = Theme.of(context).brightness;
    final mapped = _mapper
        .build(
          zones: zones,
          users: users,
          devices: devices,
          events: events,
          brightness: brightness,
        )
        .take(3)
        .toList();

    setState(() {
      _users = users;
      _devices = devices;
      _smfDevices = smfDevices;
      _events = events;
      _viewZones = mapped;
      _errorMessage = error;
      _isLoading = false;
      _isRefreshing = false;
      _selectedZoneId = mapped.any((zone) => zone.id == _selectedZoneId)
          ? _selectedZoneId
          : mapped.firstOrNull?.id;
      final selectedZone = _selectedZone;
      final selectedWorkers = selectedZone == null
          ? const <MapWorkerMarker>[]
          : _workersForSingleZone(selectedZone);
      _selectedWorkerId =
          selectedWorkers.any((worker) => worker.id == _selectedWorkerId) ==
                  true
              ? _selectedWorkerId
              : selectedWorkers.firstOrNull?.id;
    });
  }

  MapZoneViewModel? get _selectedZone {
    for (final zone in _viewZones) {
      if (zone.id == _selectedZoneId) return zone;
    }
    return _viewZones.firstOrNull;
  }

  MapWorkerMarker? get _selectedWorker {
    final zone = _selectedZone;
    if (zone == null) return null;
    final workers = _workersForSingleZone(zone);
    for (final worker in workers) {
      if (worker.id == _selectedWorkerId) return worker;
    }
    return workers.firstOrNull;
  }

  List<MapWorkerMarker> get _allRealWorkers {
    final byId = <String, MapWorkerMarker>{};
    for (final zone in _viewZones) {
      for (final worker in zone.workers) {
        byId.putIfAbsent(worker.id, () => worker);
      }
    }
    return byId.values.toList();
  }

  List<DeviceRecord> get _mappedDevices {
    final userIds = _users.map((user) => user.id).toSet();
    return _devices.where((device) {
      if (!userIds.contains(device.ownerId)) return false;
      return _viewZones.any((zone) => _deviceMatchesZone(device, zone));
    }).toList();
  }

  void _selectZone(MapZoneViewModel zone) {
    setState(() {
      _selectedZoneId = zone.id;
      _selectedWorkerId = _workersForSingleZone(zone).firstOrNull?.id;
    });
  }

  List<MapWorkerMarker> _workersForSingleZone(MapZoneViewModel zone) {
    if (zone.workers.isNotEmpty) {
      return zone.workers;
    }

    final userById = {for (final user in _users) user.id: user};
    final smfByMac = {
      for (final device in _smfDevices) device.macAddress.toLowerCase(): device,
    };

    final zoneDevices = _devices.where((device) {
      return _deviceMatchesZone(device, zone);
    }).toList();

    return zoneDevices
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final device = entry.value;
          final user = userById[device.ownerId];
          if (user == null) return null;
          final smfDevice = smfByMac[device.macAddress.toLowerCase()];
          return MapWorkerMarker(
            id: user.id.isNotEmpty ? user.id : device.id,
            name: user.name.isNotEmpty
                ? user.name
                : (smfDevice?.label.trim().isNotEmpty == true
                    ? smfDevice!.label
                    : 'Monitored device'),
            status: _workerStatusFromDevice(device.status),
            role: user.role,
            locationLabel: zone.name,
            deviceLabel: smfDevice?.label.trim().isNotEmpty == true
                ? smfDevice!.label
                : 'Worker device',
            offsetDx: _markerOffset(index, axis: 0),
            offsetDy: _markerOffset(index, axis: 1),
            avatarUrl: user.pictureUrl,
          );
        })
        .whereType<MapWorkerMarker>()
        .toList();
  }

  List<_MapWorkerPlacement> _workerPlacementsForMap() {
    final placements = <_MapWorkerPlacement>[];
    for (var zoneIndex = 0; zoneIndex < _viewZones.length; zoneIndex++) {
      final zone = _viewZones[zoneIndex];
      final workers = _workersForSingleZone(zone);
      for (var workerIndex = 0; workerIndex < workers.length; workerIndex++) {
        placements.add(
          _MapWorkerPlacement(
            zone: zone,
            worker: workers[workerIndex],
            zoneIndex: zoneIndex,
            workerIndex: workerIndex,
            totalWorkersInZone: workers.length,
          ),
        );
      }
    }
    return placements;
  }

  bool _namesMatch(String? value, String zoneName) {
    if (value == null || value.trim().isEmpty) return false;
    final left = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final right = zoneName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return left == right || left.contains(right) || right.contains(left);
  }

  bool _deviceMatchesZone(DeviceRecord device, MapZoneViewModel zone) {
    final byId = device.zoneId != null &&
        device.zoneId!.isNotEmpty &&
        device.zoneId == zone.id;
    final byName = _namesMatch(device.zoneName, zone.name);
    return byId || byName;
  }

  double _markerOffset(int index, {required int axis}) {
    const positions = [
      [0.26, 0.32],
      [0.44, 0.24],
      [0.62, 0.34],
      [0.36, 0.52],
      [0.56, 0.56],
      [0.72, 0.48],
      [0.25, 0.68],
      [0.49, 0.74],
      [0.67, 0.70],
    ];
    final item = positions[index % positions.length];
    return item[axis];
  }

  String _workerStatusFromDevice(String status) {
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

  Future<void> _openZonePanel(MapZoneViewModel zone) async {
    _selectZone(zone);
    if (MediaQuery.of(context).size.width >= 1100) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: ZoneDetailsPanel(
          zone: zone,
          palette: CampusMapPalette.fromBrightness(
            Theme.of(context).brightness,
          ),
        ),
      ),
    );
  }

  Future<void> _openWorkerPanel(
    MapZoneViewModel zone,
    MapWorkerMarker worker,
  ) async {
    setState(() => _selectedWorkerId = worker.id);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: _SelectedWorkerPanel(
          palette: CampusMapPalette.fromBrightness(
            Theme.of(context).brightness,
          ),
          zone: zone,
          worker: worker,
          workers: _workersForSingleZone(zone),
          profileDisplayName: _profileDisplayName,
          onPickWorker: (item) {
            Navigator.pop(context);
            setState(() => _selectedWorkerId = item.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        CampusMapPalette.fromBrightness(Theme.of(context).brightness);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1320;
    final isWide = width >= 1100;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _viewZones.isEmpty) {
      return _MapErrorState(
        message: _errorMessage!,
        palette: palette,
        onRetry: _loadData,
      );
    }

    final selectedZone = _selectedZone;
    final selectedWorker = _selectedWorker;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (width >= 1450)
            Row(
              children: [
                Expanded(child: _buildMetricsRow(palette)),
                const SizedBox(width: 18),
                _LiveMonitoringPill(palette: palette),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LiveMonitoringPill(palette: palette),
                const SizedBox(height: 14),
                _buildMetricsRow(palette),
              ],
            ),
          const SizedBox(height: 18),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 10,
                  child: Column(
                    children: [
                      _buildMapSection(
                        palette: palette,
                        showInlinePanel: true,
                        selectedZone: selectedZone,
                        selectedWorker: selectedWorker,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 318,
                  child: _buildRightRail(
                    palette: palette,
                    selectedZone: selectedZone,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildMapSection(
                  palette: palette,
                  showInlinePanel: isWide,
                  selectedZone: selectedZone,
                  selectedWorker: selectedWorker,
                ),
                const SizedBox(height: 18),
                _buildRightRail(
                  palette: palette,
                  selectedZone: selectedZone,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(CampusMapPalette palette) {
    final workers = _allRealWorkers;
    final totalWorkers = workers.length;
    final safe =
        workers.where((worker) => worker.status.toLowerCase() == 'safe').length;
    final warning = workers
        .where((worker) => worker.status.toLowerCase() == 'warning')
        .length;
    final emergency = workers
        .where((worker) => worker.status.toLowerCase() == 'emergency')
        .length;
    final onlineWorkers = workers
        .where((worker) => worker.status.toLowerCase() != 'offline')
        .length;
    final mappedDevices = _mappedDevices;
    final devicesOnline = mappedDevices
        .where((device) => device.status.toUpperCase() != 'OFFLINE')
        .length;
    final lang = context.watch<LanguageProvider>();

    final cards = [
      _MetricCardData(
        title: lang.getText('totalWorkers'),
        value: '$totalWorkers',
        secondary: '${lang.getText('online')} $onlineWorkers',
        accent: palette.accentBlue,
        icon: Icons.groups_2_outlined,
      ),
      _MetricCardData(
        title: lang.getText('safe'),
        value: '$safe',
        secondary: _percentLabel(safe, totalWorkers),
        accent: palette.metricSafe,
        icon: Icons.shield_outlined,
      ),
      _MetricCardData(
        title: lang.getText('warning'),
        value: '$warning',
        secondary: _percentLabel(warning, totalWorkers),
        accent: palette.metricWarning,
        icon: Icons.warning_amber_rounded,
      ),
      _MetricCardData(
        title: lang.getText('emergency'),
        value: '$emergency',
        secondary: _percentLabel(emergency, totalWorkers),
        accent: palette.metricEmergency,
        icon: Icons.notification_important_outlined,
      ),
      _MetricCardData(
        title: lang.getText('devices'),
        value: '${mappedDevices.length}',
        secondary:
            '${lang.getText('registry')} ${_smfDevices.length} / ${lang.getText('online')} $devicesOnline',
        accent: const Color(0xFF7C3AED),
        icon: Icons.desktop_windows_outlined,
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: cards
          .map((card) => _MetricCard(palette: palette, data: card))
          .toList(),
    );
  }

  String _percentLabel(int count, int total) {
    if (total <= 0) return '0%';
    return '${((count / total) * 100).round()}%';
  }

  Widget _buildMapSection({
    required CampusMapPalette palette,
    required bool showInlinePanel,
    required MapZoneViewModel? selectedZone,
    required MapWorkerMarker? selectedWorker,
  }) {
    if (selectedZone == null) {
      return _MapErrorState(
        message: _mapText(context, 'noMonitoredZones'),
        palette: palette,
        onRetry: _loadData,
      );
    }

    final workers = _workersForSingleZone(selectedZone);
    final mapWorkers = _workerPlacementsForMap();

    return Column(
      children: [
        _SingleZoneBuildingMonitor(
          palette: palette,
          zone: selectedZone,
          zones: _viewZones,
          workers: workers,
          mapWorkers: mapWorkers,
          deviceCount: _mappedDevices.length,
          registryCount: _smfDevices.length,
          selectedWorkerId: selectedWorker?.id,
          selectedZoneId: selectedZone.id,
          onSelectZone: _selectZone,
          onSelectWorker: (placement) {
            setState(() {
              _selectedZoneId = placement.zone.id;
              _selectedWorkerId = placement.worker.id;
            });
            if (!showInlinePanel) {
              _openWorkerPanel(placement.zone, placement.worker);
            }
          },
        ),
        if (showInlinePanel) ...[
          const SizedBox(height: 16),
          _SelectedWorkerPanel(
            palette: palette,
            zone: selectedZone,
            worker: selectedWorker,
            workers: workers,
            profileDisplayName: _profileDisplayName,
            onPickWorker: (worker) {
              setState(() => _selectedWorkerId = worker.id);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRightRail({
    required CampusMapPalette palette,
    required MapZoneViewModel? selectedZone,
  }) {
    final sortedEvents = [..._events]..sort((a, b) =>
        (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970)));

    return Column(
      children: [
        _CampusOverviewPanel(
          palette: palette,
          zones: _viewZones,
          selectedZoneId: selectedZone?.id,
          onSelectZone: (zone) => _openZonePanel(zone),
        ),
        const SizedBox(height: 16),
        _RecentEventsPanel(
          palette: palette,
          events: sortedEvents.take(8).toList(),
        ),
        const SizedBox(height: 16),
        _ActiveWorkersPanel(
          palette: palette,
          activeWorkers: _allRealWorkers
              .where((worker) => worker.status.toLowerCase() != 'offline')
              .length,
          totalWorkers: _allRealWorkers.length,
        ),
      ],
    );
  }
}

class _MapWorkerPlacement {
  final MapZoneViewModel zone;
  final MapWorkerMarker worker;
  final int zoneIndex;
  final int workerIndex;
  final int totalWorkersInZone;

  const _MapWorkerPlacement({
    required this.zone,
    required this.worker,
    required this.zoneIndex,
    required this.workerIndex,
    required this.totalWorkersInZone,
  });
}

class _SingleZoneBuildingMonitor extends StatefulWidget {
  final CampusMapPalette palette;
  final MapZoneViewModel zone;
  final List<MapZoneViewModel> zones;
  final List<MapWorkerMarker> workers;
  final List<_MapWorkerPlacement> mapWorkers;
  final int deviceCount;
  final int registryCount;
  final String? selectedWorkerId;
  final String? selectedZoneId;
  final ValueChanged<MapZoneViewModel> onSelectZone;
  final ValueChanged<_MapWorkerPlacement> onSelectWorker;

  const _SingleZoneBuildingMonitor({
    required this.palette,
    required this.zone,
    required this.zones,
    required this.workers,
    required this.mapWorkers,
    required this.deviceCount,
    required this.registryCount,
    required this.selectedWorkerId,
    required this.selectedZoneId,
    required this.onSelectZone,
    required this.onSelectWorker,
  });

  @override
  State<_SingleZoneBuildingMonitor> createState() =>
      _SingleZoneBuildingMonitorState();
}

class _SingleZoneBuildingMonitorState
    extends State<_SingleZoneBuildingMonitor> {
  final TransformationController _transformationController =
      TransformationController();
  Offset? _debugTapOffset;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomToScale(double targetScale, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final translation = Matrix4.translationValues(cx, cy, 0.0);
    final scaling = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    final translationInv = Matrix4.translationValues(-cx, -cy, 0.0);
    final matrix = translation * scaling * translationInv;
    setState(() {
      _transformationController.value = matrix;
    });
  }

  void _zoomIn(Size size) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale < 5.0) {
      _zoomToScale((scale + 0.5).clamp(1.0, 5.0), size);
    }
  }

  void _zoomOut(Size size) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale > 1.0) {
      _zoomToScale((scale - 0.5).clamp(1.0, 5.0), size);
    }
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AspectRatio(
      aspectRatio: MediaQuery.of(context).size.width >= 900 ? 1.72 : 0.92,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.palette.panelBackground,
              widget.palette.pageBackground,
              isDark ? const Color(0xFF06111F) : const Color(0xFFEAF4FF),
            ],
          ),
          border: Border.all(
              color: widget.zone.statusColor.withValues(alpha: 0.26)),
          boxShadow: [
            BoxShadow(
              color: widget.zone.statusColor.withValues(alpha: 0.10),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final isCompact = constraints.maxWidth < 720;
            final displayWorkers = widget.mapWorkers;

            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1.0,
                    maxScale: 5.0,
                    clipBehavior: Clip.none,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ColorFiltered(
                            colorFilter: isDark
                                ? const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  )
                                : const ColorFilter.matrix([
                                    1.18,
                                    0,
                                    0,
                                    0,
                                    18,
                                    0,
                                    1.18,
                                    0,
                                    0,
                                    18,
                                    0,
                                    0,
                                    1.18,
                                    0,
                                    20,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                            child: Image.asset(
                              'assets/images/uni_design.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? RadialGradient(
                                      center: const Alignment(0.08, -0.08),
                                      radius: 0.92,
                                      colors: [
                                        Colors.transparent,
                                        widget.palette.pageBackground
                                            .withValues(alpha: 0.18),
                                      ],
                                    )
                                  : LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.18),
                                        widget.palette.pageBackground
                                            .withValues(alpha: 0.30),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: _ReferenceZoneLayer(
                            palette: widget.palette,
                            zones: widget.zones,
                            selectedZoneId: widget.selectedZoneId,
                            onSelectZone: widget.onSelectZone,
                            onCoordinateClick: (offset) {
                              setState(() {
                                _debugTapOffset = offset;
                              });
                              debugPrint(
                                'MAP_TAP: Offset(${offset.dx.toStringAsFixed(3)}, ${offset.dy.toStringAsFixed(3)}),',
                              );
                            },
                          ),
                        ),
                        Positioned.fill(
                          child: Stack(
                            children: [
                              for (var i = 0; i < displayWorkers.length; i++)
                                _ReferenceWorkerMarker(
                                  palette: widget.palette,
                                  worker: displayWorkers[i].worker,
                                  index: displayWorkers[i].workerIndex,
                                  zoneIndex: displayWorkers[i].zoneIndex,
                                  totalWorkers:
                                      displayWorkers[i].totalWorkersInZone,
                                  selected: displayWorkers[i].worker.id ==
                                      widget.selectedWorkerId,
                                  onTap: () =>
                                      widget.onSelectWorker(displayWorkers[i]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_debugTapOffset != null)
                  Positioned(
                    left: isCompact ? 18 : 24,
                    top: isCompact ? 104 + 68 : 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.palette.panelBackground
                            .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.palette.panelBorder),
                        boxShadow: [
                          BoxShadow(
                            color: widget.palette.panelShadow
                                .withValues(alpha: 0.15),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ads_click,
                            color: widget.palette.metricSafe,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          SelectableText(
                            'Offset(${_debugTapOffset!.dx.toStringAsFixed(3)}, ${_debugTapOffset!.dy.toStringAsFixed(3)})',
                            style: TextStyle(
                              color: widget.palette.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _debugTapOffset = null;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              color: widget.palette.textSecondary,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: isCompact ? 18 : 24,
                  top: isCompact ? 18 : 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.palette.panelBackground
                          .withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            widget.palette.panelBorder.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              widget.palette.panelShadow.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ZoomButton(
                          icon: Icons.add,
                          onPressed: () => _zoomIn(size),
                          palette: widget.palette,
                        ),
                        const SizedBox(height: 4),
                        _ZoomButton(
                          icon: Icons.remove,
                          onPressed: () => _zoomOut(size),
                          palette: widget.palette,
                        ),
                        const SizedBox(height: 4),
                        _ZoomButton(
                          icon: Icons.zoom_out_map_outlined,
                          onPressed: _resetZoom,
                          palette: widget.palette,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: isCompact ? 18 : 24,
                  top: isCompact ? 18 : constraints.maxHeight * 0.30,
                  child: _BuildingInfoCallout(
                    palette: widget.palette,
                    zone: widget.zone,
                    workersCount: widget.workers.isNotEmpty
                        ? widget.workers.length
                        : math.max(widget.zone.workersCount, displayWorkers.length),
                  ),
                ),
                Positioned(
                  right: isCompact ? 18 : 26,
                  top: isCompact ? 104 : constraints.maxHeight * 0.34,
                  child: _BuildingStatusCallout(
                    palette: widget.palette,
                    zone: widget.zone,
                    workers: widget.workers,
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: _SingleZoneLegend(
                    palette: widget.palette,
                    online: widget.workers
                        .where((item) => item.status.toLowerCase() != 'offline')
                        .length,
                    offline: widget.workers
                        .where((item) => item.status.toLowerCase() == 'offline')
                        .length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final CampusMapPalette palette;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: palette.panelBackground.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: palette.panelBorder.withValues(alpha: 0.8)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon, color: palette.textPrimary),
        onPressed: onPressed,
      ),
    );
  }
}

class _BuildingInfoCallout extends StatelessWidget {
  final CampusMapPalette palette;
  final MapZoneViewModel zone;
  final int workersCount;

  const _BuildingInfoCallout({
    required this.palette,
    required this.zone,
    required this.workersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 252),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.pageBackground.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.accentBlue.withValues(alpha: 0.70)),
        boxShadow: [
          BoxShadow(
            color: palette.accentBlue.withValues(alpha: 0.18),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.factory_outlined, color: palette.accentBlue, size: 36),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  zone.name.isEmpty
                      ? _mapText(context, 'zoneAEngineeringOnly')
                      : _mapZoneName(context, zone.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.accentBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  zone.area.isEmpty
                      ? _mapText(context, 'productionArea')
                      : _mapArea(context, zone.area),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_2_outlined,
                        color: palette.accentBlue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '$workersCount ${_mapText(context, 'workers')}',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingStatusCallout extends StatelessWidget {
  final CampusMapPalette palette;
  final MapZoneViewModel zone;
  final List<MapWorkerMarker> workers;

  const _BuildingStatusCallout({
    required this.palette,
    required this.zone,
    required this.workers,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = workers.any((worker) => worker.status.toLowerCase() != 'offline');
    final color = isOn ? palette.metricSafe : palette.metricOffline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: palette.pageBackground.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.verified_user_outlined, color: color, size: 32),
          ),
          const SizedBox(width: 14),
          Text(
            '${_mapText(context, 'status')}\n${isOn ? 'On' : 'Off'}',
            style: TextStyle(
              color: color,
              height: 1.15,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceZoneLayer extends StatelessWidget {
  final CampusMapPalette palette;
  final List<MapZoneViewModel> zones;
  final String? selectedZoneId;
  final ValueChanged<MapZoneViewModel> onSelectZone;
  final void Function(Offset)? onCoordinateClick;

  const _ReferenceZoneLayer({
    required this.palette,
    required this.zones,
    required this.selectedZoneId,
    required this.onSelectZone,
    this.onCoordinateClick,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) {
              final localPos = details.localPosition;
              final dx = localPos.dx / size.width;
              final dy = localPos.dy / size.height;
              onCoordinateClick?.call(Offset(dx, dy));

              final zone = _zoneAt(localPos, size);
              if (zone != null) {
                onSelectZone(zone);
              }
            },
            child: CustomPaint(
              painter: _ReferenceZonePainter(
                palette: palette,
                zones: zones,
                selectedZoneId: selectedZoneId,
              ),
            ),
          ),
        );
      },
    );
  }

  MapZoneViewModel? _zoneAt(Offset point, Size size) {
    for (var index = zones.length - 1; index >= 0; index--) {
      if (_zonePathForIndex(index, size).contains(point)) {
        return zones[index];
      }
    }
    return null;
  }
}

class _ReferenceZonePainter extends CustomPainter {
  final CampusMapPalette palette;
  final List<MapZoneViewModel> zones;
  final String? selectedZoneId;

  const _ReferenceZonePainter({
    required this.palette,
    required this.zones,
    required this.selectedZoneId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < zones.length; index++) {
      final zone = zones[index];
      final selected = zone.id == selectedZoneId;
      final path = _zonePathForIndex(index, size);
      const color = Color(0xFF6B7280);

      if (selected) {
        canvas.save();
        canvas.clipPath(path);
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.16)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0,
        );
        canvas.restore();
      }

      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: selected ? 0.72 : 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 1.4 : 1.0,
      );
      canvas.restore();

      final center = _zoneCenterForIndex(index, size);
      canvas.drawCircle(
        center,
        selected ? 12 : 9,
        Paint()..color = palette.pageBackground.withValues(alpha: 0.86),
      );
      canvas.drawCircle(
        center,
        selected ? 12 : 9,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.4 : 1.8,
      );
      canvas.drawCircle(center, 4.2, Paint()..color = color);

      if (selected) {
        _drawSelectedLabel(canvas, size, zone, center, color);
      }
    }
  }

  void _drawSelectedLabel(
    Canvas canvas,
    Size size,
    MapZoneViewModel zone,
    Offset center,
    Color color,
  ) {
    final label = zone.name.trim().isEmpty ? 'Zone' : zone.name.trim();
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      maxLines: 1,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 136);

    final rect = Rect.fromLTWH(
      (center.dx - textPainter.width / 2 - 9)
          .clamp(10, size.width - textPainter.width - 28),
      (center.dy + 16).clamp(10, size.height - 36),
      textPainter.width + 18,
      28,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(
      rrect,
      Paint()..color = palette.pageBackground.withValues(alpha: 0.88),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke,
    );
    textPainter.paint(canvas, Offset(rect.left + 9, rect.top + 6));
  }

  @override
  bool shouldRepaint(covariant _ReferenceZonePainter oldDelegate) {
    return oldDelegate.zones != zones ||
        oldDelegate.selectedZoneId != selectedZoneId ||
        oldDelegate.palette != palette;
  }
}

Path _zonePathForIndex(int index, Size size) {
  final points = _zonePoints[index % _zonePoints.length];
  final path = Path()
    ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx * size.width, point.dy * size.height);
  }
  return path..close();
}

Offset _zoneCenterForIndex(int index, Size size) {
  final point = _zoneCenters[index % _zoneCenters.length];
  return Offset(point.dx * size.width, point.dy * size.height);
}

Offset _workerPointInZone({
  required int zoneIndex,
  required int workerIndex,
  required int totalWorkers,
}) {
  final center = _zoneCenters[zoneIndex % _zoneCenters.length];
  const offsets = [
    Offset(0.0, 0.0),
    Offset(-0.02, -0.015),
    Offset(0.02, 0.015),
    Offset(-0.02, 0.015),
    Offset(0.02, -0.015),
    Offset(0.0, -0.025),
    Offset(0.0, 0.025),
  ];
  final offset = offsets[workerIndex % offsets.length];
  return Offset(center.dx + offset.dx, center.dy + offset.dy);
}

const _zonePoints = [
  // Zone A (Blue) - User calibrated high-precision multi-point boundary
  [
    Offset(0.804, 0.025),
    Offset(0.880, 0.149),
    Offset(0.863, 0.191),
    Offset(0.874, 0.209),
    Offset(0.836, 0.280),
    Offset(0.822, 0.260),
    Offset(0.800, 0.294),
    Offset(0.786, 0.277),
    Offset(0.773, 0.292),
    Offset(0.739, 0.140),
  ],
  // Zone B (Green) - User calibrated high-precision multi-point boundary
  [
    Offset(0.650, 0.189),
    Offset(0.737, 0.147),
    Offset(0.771, 0.293),
    Offset(0.783, 0.292),
    Offset(0.771, 0.336),
    Offset(0.690, 0.380),
    Offset(0.692, 0.369),
    Offset(0.686, 0.341),
    Offset(0.697, 0.332),
    Offset(0.686, 0.287),
    Offset(0.670, 0.292),
  ],
  // Zone C (Yellow) - High-precision multi-point boundary
  [
    Offset(0.647, 0.190),
    Offset(0.670, 0.295),
    Offset(0.686, 0.288),
    Offset(0.686, 0.288),
    Offset(0.694, 0.331),
    Offset(0.657, 0.354),
    Offset(0.658, 0.363),
    Offset(0.631, 0.377),
    Offset(0.636, 0.391),
    Offset(0.631, 0.417),
    Offset(0.618, 0.422),
    Offset(0.605, 0.344),
    Offset(0.575, 0.360),
    Offset(0.556, 0.239),
  ],
];

const _zoneCenters = [
  Offset(0.81, 0.16), // Zone A
  Offset(0.710, 0.230), // Zone B
  Offset(0.617, 0.284), // Zone C
];

class _ReferenceWorkerMarker extends StatelessWidget {
  final CampusMapPalette palette;
  final MapWorkerMarker worker;
  final int index;
  final int zoneIndex;
  final int totalWorkers;
  final bool selected;
  final VoidCallback onTap;

  const _ReferenceWorkerMarker({
    required this.palette,
    required this.worker,
    required this.index,
    required this.zoneIndex,
    required this.totalWorkers,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final position = _workerPointInZone(
      zoneIndex: zoneIndex,
      workerIndex: index,
      totalWorkers: totalWorkers,
    );
    return Positioned.fill(
      child: Align(
        alignment: Alignment(position.dx * 2 - 1, position.dy * 2 - 1),
        child: GestureDetector(
          onTap: onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.96, end: selected ? 1.10 : 1),
            duration: const Duration(milliseconds: 220),
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                WorkerMarkerChip(
                  worker: worker,
                  palette: palette,
                  size: selected ? 38 : 30,
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: selected ? 10 : 8,
                    height: selected ? 10 : 8,
                    decoration: BoxDecoration(
                      color: _workerColor(worker.status),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: palette.pageBackground, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _workerColor(String status) {
    switch (status.toLowerCase()) {
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

class _SingleZoneLegend extends StatelessWidget {
  final CampusMapPalette palette;
  final int online;
  final int offline;

  const _SingleZoneLegend({
    required this.palette,
    required this.online,
    required this.offline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.panelBackground.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _legendItem('On', online, palette.metricSafe),
          _legendItem('Off', offline, palette.metricOffline),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: palette.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _MapErrorState extends StatelessWidget {
  final String message;
  final CampusMapPalette palette;
  final VoidCallback onRetry;

  const _MapErrorState({
    required this.message,
    required this.palette,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.panelBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.panelBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              color: palette.textMuted,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(_mapText(context, 'retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCardData {
  final String title;
  final String value;
  final String secondary;
  final Color accent;
  final IconData icon;

  const _MetricCardData({
    required this.title,
    required this.value,
    required this.secondary,
    required this.accent,
    required this.icon,
  });
}

class _MetricCard extends StatelessWidget {
  final CampusMapPalette palette;
  final _MetricCardData data;

  const _MetricCard({
    required this.palette,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.panelBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: data.accent.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: data.accent.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: data.accent.withValues(alpha: 0.12),
              ),
              child: Icon(
                data.icon,
                color: data.accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        data.value,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        data.secondary,
                        style: TextStyle(
                          color: data.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMonitoringPill extends StatelessWidget {
  final CampusMapPalette palette;

  const _LiveMonitoringPill({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: palette.metricSafe,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _mapText(context, 'liveMonitoring'),
            style: TextStyle(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 160,
            height: 24,
            child: CustomPaint(
              painter: _LinePulsePainter(color: palette.metricSafe),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusOverviewPanel extends StatelessWidget {
  final CampusMapPalette palette;
  final List<MapZoneViewModel> zones;
  final String? selectedZoneId;
  final ValueChanged<MapZoneViewModel> onSelectZone;

  const _CampusOverviewPanel({
    required this.palette,
    required this.zones,
    required this.selectedZoneId,
    required this.onSelectZone,
  });

  @override
  Widget build(BuildContext context) {
    return _SidePanel(
      palette: palette,
      title: _mapText(context, 'zoneOverview'),
      child: Column(
        children: [
          ...zones.map(
            (zone) => GestureDetector(
              onTap: () => onSelectZone(zone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedZoneId == zone.id
                      ? zone.statusColor.withValues(alpha: 0.10)
                      : palette.track,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedZoneId == zone.id
                        ? zone.statusColor.withValues(alpha: 0.42)
                        : palette.panelBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: zone.statusColor.withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        _zoneIcon(zone.layoutSlot.visualType),
                        color: zone.statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mapZoneName(context, zone.name),
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _mapArea(context, zone.area),
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CountColumn(
                      label: 'W',
                      value: zone.workersCount,
                      color: palette.textPrimary,
                    ),
                    _CountColumn(
                      label: 'S',
                      value: zone.safeCount,
                      color: palette.metricSafe,
                    ),
                    _CountColumn(
                      label: 'W',
                      value: zone.warningCount,
                      color: palette.metricWarning,
                    ),
                    _CountColumn(
                      label: 'E',
                      value: zone.emergencyCount,
                      color: palette.metricEmergency,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _zoneIcon(ZoneVisualType type) {
    switch (type) {
      case ZoneVisualType.building:
        return Icons.corporate_fare_outlined;
      case ZoneVisualType.court:
        return Icons.sports_basketball_outlined;
      case ZoneVisualType.gate:
        return Icons.shield_outlined;
      case ZoneVisualType.restricted:
        return Icons.lock_outline_rounded;
      case ZoneVisualType.assembly:
        return Icons.groups_2_outlined;
      case ZoneVisualType.utility:
        return Icons.electrical_services_outlined;
      case ZoneVisualType.generic:
        return Icons.place_outlined;
    }
  }
}

class _RecentEventsPanel extends StatelessWidget {
  final CampusMapPalette palette;
  final List<EventLog> events;

  const _RecentEventsPanel({
    required this.palette,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return _SidePanel(
      palette: palette,
      title: _mapText(context, 'recentEvents'),
      trailing: Text(
        'View All',
        style: TextStyle(
          color: palette.accentBlue,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
      child: Column(
        children: [
          if (events.isEmpty)
            Text(
              _mapText(context, 'noRecentEvents'),
              style: TextStyle(color: palette.textMuted),
            )
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _eventColor(event.eventType, palette),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 58,
                      child: Text(
                        _timeAgo(event.createdAt),
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: event.message?.isNotEmpty == true
                                  ? event.message!
                                  : event.eventType,
                              style: TextStyle(
                                color: event.eventType == 'SOS_TRIGGERED'
                                    ? palette.metricEmergency
                                    : palette.textSecondary,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                            if ((event.zoneName ?? '').isNotEmpty)
                              TextSpan(
                                text: ' in ${event.zoneName}',
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Color _eventColor(String type, CampusMapPalette palette) {
    switch (type) {
      case 'SOS_TRIGGERED':
      case 'ACCESS_DENIED':
        return palette.metricEmergency;
      case 'DEVICE_OFFLINE':
        return palette.metricWarning;
      default:
        return palette.metricSafe;
    }
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hr';
    return '${diff.inDays} d';
  }
}

class _ActiveWorkersPanel extends StatelessWidget {
  final CampusMapPalette palette;
  final int activeWorkers;
  final int totalWorkers;

  const _ActiveWorkersPanel({
    required this.palette,
    required this.activeWorkers,
    required this.totalWorkers,
  });

  @override
  Widget build(BuildContext context) {
    return _SidePanel(
      palette: palette,
      title: _mapText(context, 'activeWorkers'),
      trailing: Text(
        '$activeWorkers / $totalWorkers',
        style: TextStyle(
          color: palette.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 42,
            child: CustomPaint(
              painter: _LinePulsePainter(color: palette.metricSafe),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: Text(
              _mapText(context, 'viewAllWorkers'),
              style: TextStyle(
                color: palette.accentBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final CampusMapPalette palette;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SidePanel({
    required this.palette,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.panelBorder),
        boxShadow: [
          BoxShadow(
            color: palette.panelShadow.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CountColumn extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CountColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedWorkerPanel extends StatelessWidget {
  final CampusMapPalette palette;
  final MapZoneViewModel zone;
  final MapWorkerMarker? worker;
  final List<MapWorkerMarker> workers;
  final String? profileDisplayName;
  final ValueChanged<MapWorkerMarker> onPickWorker;

  const _SelectedWorkerPanel({
    required this.palette,
    required this.zone,
    required this.worker,
    required this.workers,
    required this.profileDisplayName,
    required this.onPickWorker,
  });

  @override
  Widget build(BuildContext context) {
    final selectedWorker = worker ?? workers.firstOrNull;
    final savedName = profileDisplayName?.trim();
    final workerName = selectedWorker?.name.trim();
    final displayName = savedName != null &&
            savedName.isNotEmpty &&
            (workerName == null ||
                workerName.isEmpty ||
                workerName.toLowerCase() == 'admin')
        ? savedName
        : selectedWorker?.name ?? _mapZoneName(context, zone.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.panelBorder),
        boxShadow: [
          BoxShadow(
            color: palette.panelShadow.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedWorker != null)
                WorkerMarkerChip(
                  worker: selectedWorker,
                  palette: palette,
                  size: 74,
                )
              else
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.track,
                  ),
                  child: Icon(Icons.person_outline, color: palette.textMuted),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          selectedWorker?.role == null
                              ? _mapArea(context, zone.area)
                              : _mapRoleName(
                                  context,
                                  selectedWorker!.role ?? '',
                                ),
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: zone.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _mapStatus(context, zone.status),
                            style: TextStyle(
                              color: zone.statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _mapText(context, 'currentLocation'),
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedWorker?.locationLabel?.trim().isNotEmpty == true
                          ? _mapZoneName(
                              context,
                              selectedWorker!.locationLabel!,
                            )
                          : _mapArea(context, zone.area),
                      style: TextStyle(
                        color: palette.metricSafe,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              if (zone.latestEvent != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mapText(context, 'lastEvent'),
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          zone.latestEvent!.eventType,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          zone.latestEvent!.message ??
                              zone.latestEvent!.macAddress,
                          style: TextStyle(
                            color: palette.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (workers.isNotEmpty) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: workers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = workers[index];
                  final isSelected = item.id == selectedWorker?.id;
                  return GestureDetector(
                    onTap: () => onPickWorker(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? zone.statusColor.withValues(alpha: 0.10)
                            : palette.track,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? zone.statusColor.withValues(alpha: 0.36)
                              : palette.panelBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          WorkerMarkerChip(
                            worker: item,
                            palette: palette,
                            size: 34,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.name,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinePulsePainter extends CustomPainter {
  final Color color;

  const _LinePulsePainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    for (var i = 0; i < 28; i++) {
      final x = size.width * (i / 27);
      final seed = math.sin(i * 0.9) * 0.28 + math.cos(i * 1.4) * 0.11;
      final y = size.height * (0.52 - seed);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePulsePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
