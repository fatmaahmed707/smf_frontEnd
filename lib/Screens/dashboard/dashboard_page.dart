import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/event_log.dart';
import '../../models/user.dart';
import '../../providers/language_provider.dart';
import '../../services/events_service.dart';
import '../../services/smf_devices_service.dart';
import '../../services/users_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/dashboard_history.dart';
import '../announcements/announcements_page.dart';
import 'emergency_dashboard_page.dart';
import 'map_overview_page.dart';
import 'reports_page.dart';
import 'roles_management_page.dart';
import 'users_management_page.dart';
import 'zones_management_page.dart';

enum _DashboardTab {
  dashboard,
  map,
  alerts,
  roles,
  zones,
  announcements,
  emergency,
  users,
  reports,
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  static const _profileImageKey = 'profile_image_url';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  _DashboardTab _selectedTab = _DashboardTab.dashboard;
  final List<_AlertRecord> _alerts = <_AlertRecord>[];
  late final AnimationController _livePulse;
  late final AnimationController _badgePulse;
  StreamSubscription<String>? _dashboardHistorySubscription;
  final List<_DashboardTab> _dashboardTabHistory = <_DashboardTab>[];
  final Set<int> _readNotificationIndexes = <int>{};
  final UsersService _usersService = UsersService();
  final SmfDevicesService _smfDevicesService = SmfDevicesService();
  final EventsService _eventsService = EventsService();
  User? _currentUser;
  String? _profileImageUrl;
  int? _onlineUserCount;
  int? _smfDeviceCount;
  int? _registeredSmfDeviceCount;
  int _selectedAlertIndex = 0;
  int _alertsCurrentPage = 1;
  String _alertSearchQuery = '';
  String _alertSeverityFilter = 'All';
  String _alertDateRange = 'Last 7 days';
  static const int _alertsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _selectedTab = _tabFromSlug(DashboardHistory.currentSlug());
    DashboardHistory.replace(_slugForTab(_selectedTab));
    _dashboardHistorySubscription =
        DashboardHistory.changes.listen(_restoreDashboardTabFromHistory);
    _livePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _badgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _loadCurrentUser();
    _loadProfileImage();
    _loadAlertsFromEvents();
    _loadOnlineUserCount();
    _loadSmfDeviceCount();
  }

  Future<void> _loadAlertsFromEvents() async {
    try {
      final events = await _eventsService.getEvents(since: 3600 * 24 * 7);
      final mapped = events
          .where((event) => _eventLooksLikeAlert(event))
          .map(_alertFromEvent)
          .toList();
      if (!mounted) return;
      setState(() {
        _alerts
          ..clear()
          ..addAll(mapped);
        _selectedAlertIndex = 0;
        _alertsCurrentPage = 1;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _alerts.clear());
    }
  }

  bool _eventLooksLikeAlert(EventLog event) {
    final normalized = event.eventType.toLowerCase();
    return normalized.contains('alert') ||
        normalized.contains('sos') ||
        normalized.contains('breach') ||
        normalized.contains('violation') ||
        normalized.contains('unauthorized') ||
        normalized.contains('offline');
  }

  _AlertRecord _alertFromEvent(EventLog event) {
    final eventType =
        event.eventType.isEmpty ? 'Security event' : event.eventType;
    final title = event.message ?? _titleFromEventType(eventType);
    final description = event.zoneName ??
        (event.macAddress.isNotEmpty ? event.macAddress : 'SMF event stream');
    return _AlertRecord(
      title: title,
      description: description,
      severity: _severityFromEvent(eventType),
      status: 'Open',
      timeLabel: _relativeEventTime(event.createdAt),
    );
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

  String _severityFromEvent(String eventType) {
    final normalized = eventType.toLowerCase();
    if (normalized.contains('sos') ||
        normalized.contains('breach') ||
        normalized.contains('unauthorized')) {
      return 'High';
    }
    if (normalized.contains('offline') || normalized.contains('violation')) {
      return 'Medium';
    }
    return 'Low';
  }

  String _relativeEventTime(DateTime? createdAt) {
    if (createdAt == null) return 'Just now';
    final diff = DateTime.now().difference(createdAt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _profileImageUrl = prefs.getString(_profileImageKey));
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _usersService.getCurrentUser();
      if (!mounted) return;
      setState(() => _currentUser = user);
    } catch (_) {
      if (!mounted) return;
      setState(() => _currentUser = null);
    }
  }

  Future<void> _loadOnlineUserCount() async {
    try {
      final users = await _usersService.getUsers();
      if (!mounted) return;
      setState(() => _onlineUserCount = users.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _onlineUserCount = 0);
    }
  }

  Future<void> _loadSmfDeviceCount() async {
    try {
      final devices = await _smfDevicesService.getAllDevices();
      if (!mounted) return;
      setState(() {
        _smfDeviceCount = devices.length;
        _registeredSmfDeviceCount =
            devices.where((device) => device.isRegistered).length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _smfDeviceCount = 0;
        _registeredSmfDeviceCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _dashboardHistorySubscription?.cancel();
    _livePulse.dispose();
    _badgePulse.dispose();
    super.dispose();
  }

  String _slugForTab(_DashboardTab tab) {
    switch (tab) {
      case _DashboardTab.dashboard:
        return 'dashboard';
      case _DashboardTab.map:
        return 'map';
      case _DashboardTab.alerts:
        return 'alerts';
      case _DashboardTab.roles:
        return 'roles';
      case _DashboardTab.zones:
        return 'zones';
      case _DashboardTab.announcements:
        return 'announcements';
      case _DashboardTab.emergency:
        return 'emergency';
      case _DashboardTab.users:
        return 'users';
      case _DashboardTab.reports:
        return 'reports';
    }
  }

  _DashboardTab _tabFromSlug(String slug) {
    switch (slug.trim().toLowerCase()) {
      case 'map':
        return _DashboardTab.map;
      case 'alerts':
        return _DashboardTab.alerts;
      case 'roles':
        return _DashboardTab.roles;
      case 'zones':
        return _DashboardTab.zones;
      case 'announcements':
        return _DashboardTab.announcements;
      case 'emergency':
      case 'emergency-dashboard':
        return _DashboardTab.emergency;
      case 'users':
        return _DashboardTab.users;
      case 'reports':
        return _DashboardTab.reports;
      case 'dashboard':
      default:
        return _DashboardTab.dashboard;
    }
  }

  void _restoreDashboardTabFromHistory(String slug) {
    if (!mounted) return;
    final tab = _tabFromSlug(slug);
    if (_selectedTab == tab) return;
    if (_dashboardTabHistory.isNotEmpty && _dashboardTabHistory.last == tab) {
      _dashboardTabHistory.removeLast();
    }
    setState(() => _selectedTab = tab);
  }

  void _goBackFromDashboardTab() {
    final drawerIsOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    if (drawerIsOpen) {
      Navigator.of(context).pop();
      return;
    }

    if (_dashboardTabHistory.isNotEmpty) {
      final previousTab = _dashboardTabHistory.removeLast();
      setState(() => _selectedTab = previousTab);
      DashboardHistory.replace(_slugForTab(previousTab));
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    if (_selectedTab != _DashboardTab.dashboard) {
      setState(() => _selectedTab = _DashboardTab.dashboard);
      DashboardHistory.replace(_slugForTab(_DashboardTab.dashboard));
    }
  }

  Future<bool> _handleDashboardSystemBack() async {
    final drawerIsOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    if (drawerIsOpen ||
        _dashboardTabHistory.isNotEmpty ||
        _selectedTab != _DashboardTab.dashboard) {
      _goBackFromDashboardTab();
      return false;
    }
    return true;
  }

  String _greeting(LanguageProvider languageProvider) {
    final hour = DateTime.now().hour;
    if (languageProvider.isArabic) {
      if (hour < 12) return 'صباح الخير';
      if (hour < 17) return 'مساء الخير';
      return 'مساء الخير';
    }
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  _DashboardPalette _palette(bool isDark) =>
      isDark ? const _DashboardPalette.dark() : const _DashboardPalette.light();

  String _heroAsset(bool isDark) =>
      isDark ? 'assets/images/hero_dark.jpeg' : 'assets/images/hero_light.jpeg';

  String _sidebarWatermarkAsset(bool isDark) =>
      isDark ? 'assets/images/hero_dark.jpeg' : 'assets/images/hero_light.jpeg';

  List<double> _heroImageFilterMatrix(bool isDark) {
    if (!isDark) {
      return const <double>[
        1.12,
        0,
        0,
        0,
        8,
        0,
        1.12,
        0,
        0,
        8,
        0,
        0,
        1.12,
        0,
        8,
        0,
        0,
        0,
        1,
        0,
      ];
    }
    return const <double>[
      1.28,
      -0.04,
      -0.04,
      0,
      12,
      -0.04,
      1.28,
      -0.04,
      0,
      12,
      -0.04,
      -0.04,
      1.28,
      0,
      12,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<double> _sidebarImageFilterMatrix(bool isDark) {
    if (!isDark) {
      return const <double>[
        1.05,
        0,
        0,
        0,
        0,
        0,
        1.05,
        0,
        0,
        0,
        0,
        0,
        1.05,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ];
    }
    return const <double>[
      1.12,
      -0.02,
      -0.02,
      0,
      0,
      -0.02,
      1.12,
      -0.02,
      0,
      0,
      -0.02,
      -0.02,
      1.12,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  Color _severityColor(String severity, _DashboardPalette palette) {
    switch (severity) {
      case 'High':
        return palette.danger;
      case 'Medium':
        return palette.warning;
      default:
        return palette.success;
    }
  }

  Color _alertStatusColor(String status, _DashboardPalette palette) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'open':
        return palette.danger;
      case 'in progress':
      case 'investigating':
      case 'acknowledged':
        return palette.primaryBlue2;
      case 'resolved':
      case 'closed':
        return palette.success;
      default:
        return palette.textMuted;
    }
  }

  IconData _alertSeverityIcon(String severity) {
    switch (severity) {
      case 'High':
        return Icons.warning_amber_rounded;
      case 'Medium':
        return Icons.error_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  IconData _alertSourceIcon(String source) {
    final normalized = source.toLowerCase();
    if (normalized.contains('access')) {
      return Icons.shield_outlined;
    }
    if (normalized.contains('worker')) {
      return Icons.badge_outlined;
    }
    if (normalized.contains('device')) {
      return Icons.desktop_windows_outlined;
    }
    if (normalized.contains('location')) {
      return Icons.place_outlined;
    }
    if (normalized.contains('environment')) {
      return Icons.thermostat_outlined;
    }
    return Icons.settings_outlined;
  }

  List<_AlertRecord> _filteredAlerts() {
    return _alerts.where((alert) {
      final matchesQuery = _alertSearchQuery.isEmpty ||
          alert.title.toLowerCase().contains(_alertSearchQuery.toLowerCase()) ||
          alert.description
              .toLowerCase()
              .contains(_alertSearchQuery.toLowerCase());
      final matchesSeverity = _alertSeverityFilter == 'All' ||
          alert.severity == _alertSeverityFilter;
      return matchesQuery && matchesSeverity;
    }).toList();
  }

  String _localizedAlertTitle(_AlertRecord alert) {
    final lang = context.read<LanguageProvider>();
    final title = alert.title.toLowerCase();
    if (title.contains('unauthorized')) {
      return lang.getText('unauthorizedAccessAttempt');
    }
    if (title.contains('camera')) return lang.getText('cameraFeedUnstable');
    if (title.contains('perimeter')) {
      return lang.getText('perimeterSensorOffline');
    }
    if (title.contains('routine')) return lang.getText('routinePatrolCheckIn');
    return alert.title;
  }

  String _localizedAlertDescription(_AlertRecord alert) {
    final lang = context.read<LanguageProvider>();
    final description = alert.description.toLowerCase();
    if (description.contains('zone b gate')) return lang.getText('zoneBGate2');
    if (description.contains('warehouse')) {
      return lang.getText('warehouseNorth');
    }
    if (description.contains('fence')) return lang.getText('fenceLineEast');
    if (description.contains('lobby')) return lang.getText('lobbyControl');
    return alert.description;
  }

  String _localizedSeverity(String severity) {
    final lang = context.read<LanguageProvider>();
    switch (severity) {
      case 'High':
        return lang.getText('high');
      case 'Medium':
        return lang.getText('medium');
      case 'Low':
        return lang.getText('low');
      default:
        return severity;
    }
  }

  String _localizedStatus(String status) {
    final lang = context.read<LanguageProvider>();
    switch (status.toLowerCase()) {
      case 'open':
        return lang.getText('open');
      case 'investigating':
        return lang.getText('investigating');
      case 'acknowledged':
        return lang.getText('acknowledged');
      case 'closed':
        return lang.getText('closed');
      default:
        return status;
    }
  }

  String _localizedSource(String source) {
    final lang = context.read<LanguageProvider>();
    switch (source) {
      case 'Access Control':
        return lang.getText('accessControl');
      case 'System':
        return lang.getText('system');
      case 'Device Monitor':
        return lang.getText('deviceMonitor');
      case 'Worker Device':
        return lang.getText('workerDevice');
      case 'Location Service':
        return lang.getText('locationService');
      default:
        return source;
    }
  }

  String _localizedFilter(String filter) {
    final lang = context.read<LanguageProvider>();
    switch (filter) {
      case 'All':
        return lang.getText('all');
      case 'High':
        return lang.getText('high');
      case 'Medium':
        return lang.getText('medium');
      case 'Low':
        return lang.getText('low');
      default:
        return filter;
    }
  }

  String _localizedDateRange(String range) {
    final lang = context.read<LanguageProvider>();
    switch (range) {
      case 'Today':
        return lang.getText('today');
      case 'Last 7 days':
        return lang.getText('last7Days');
      case 'This month':
        return lang.getText('thisMonth');
      default:
        return range;
    }
  }

  String _localizedTimeLabel(String label) {
    final lang = context.read<LanguageProvider>();
    final minutes = RegExp(r'^(\d+)\s+min').firstMatch(label);
    if (minutes != null) {
      return lang
          .getText('minutesAgo')
          .replaceAll('{count}', minutes.group(1)!);
    }
    return label;
  }

  String _localizedLocation(_AlertRecord alert) {
    final lang = context.read<LanguageProvider>();
    final source = _alertSource(alert);
    if (source == 'Access Control') {
      return lang.getText('mainEntranceBuildingA');
    }
    if (source == 'Device Monitor') return lang.getText('eastFenceCorridor');
    if (source == 'System') return lang.getText('operationsLobby');
    return _alertLocation(alert);
  }

  void _setAlertSeverityFilter(String severity) {
    setState(() {
      _alertSeverityFilter = severity;
      _alertsCurrentPage = 1;
    });
  }

  _AlertRecord? _selectedAlert(List<_AlertRecord> alerts) {
    if (alerts.isEmpty) return null;
    final safeIndex = _selectedAlertIndex.clamp(0, _alerts.length - 1);
    final selected = _alerts[safeIndex];
    for (final alert in alerts) {
      if (identical(alert, selected)) return alert;
    }
    return alerts.first;
  }

  String _alertSource(_AlertRecord alert) {
    final title = alert.title.toLowerCase();
    if (title.contains('unauthorized')) return 'Access Control';
    if (title.contains('sos')) return 'Worker Device';
    if (title.contains('offline')) return 'Device Monitor';
    if (title.contains('geofence')) return 'Location Service';
    if (title.contains('temperature')) return 'Environment';
    return 'System';
  }

  String _alertLocation(_AlertRecord alert) {
    final title = alert.title.toLowerCase();
    if (title.contains('unauthorized')) return 'Main Entrance • Building A';
    if (title.contains('sos')) return 'Zone C • North Yard';
    if (title.contains('offline')) return 'Production Hall • Line 4';
    if (title.contains('geofence')) return 'Restricted Corridor • Zone B';
    if (title.contains('temperature')) return 'Boiler Room • Sector 2';
    return 'Central Infrastructure';
  }

  String _alertIpAddress(_AlertRecord alert) {
    final seed = math.max(alert.title.length * 7, 42);
    return '192.168.${seed % 18}.${100 + (seed % 80)}';
  }

  String _alertDevice(_AlertRecord alert) {
    final source = _alertSource(alert);
    if (source == 'Worker Device') return 'Assigned wearable';
    if (source == 'Access Control') return 'AC-Panel-01';
    if (source == 'Device Monitor') return 'Device #45';
    if (source == 'Location Service') return 'GeoFence Node #7';
    if (source == 'Environment') return 'Thermal Sensor A-2';
    return 'Security Core';
  }

  String _alertUserAgent(_AlertRecord alert) {
    if (_alertSource(alert) == 'Access Control') {
      return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
    }
    if (_alertSource(alert) == 'Worker Device') {
      return 'SMF Android Client 2.4.1';
    }
    return 'SMF Monitoring Agent';
  }

  void _updateAlertStatus(_AlertRecord alert, String status) {
    final index = _alerts.indexOf(alert);
    if (index == -1) return;
    setState(() {
      _alerts[index] = _AlertRecord(
        title: alert.title,
        description: alert.description,
        severity: alert.severity,
        status: status,
        timeLabel: alert.timeLabel,
      );
      _selectedAlertIndex = index;
    });
  }

  void _selectDashboardTab(_DashboardTab tab) {
    final drawerIsOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    if (drawerIsOpen) {
      Navigator.of(context).pop();
    }

    if (_selectedTab == tab) {
      return;
    }

    _dashboardTabHistory.add(_selectedTab);
    setState(() => _selectedTab = tab);
    DashboardHistory.push(_slugForTab(tab));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;
    final palette = _palette(isDark);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1280;
    final isTablet = width >= 760;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleDashboardSystemBack();
      },
      child: Directionality(
        textDirection:
            languageProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: palette.pageBackground,
          drawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: _buildSidebar(
                    context: context,
                    palette: palette,
                    isDark: isDark,
                    languageProvider: languageProvider,
                  ),
                ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.pageBackground, palette.pageBackgroundEnd],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0.94, -0.92),
                              radius: 0.5,
                              colors: [palette.glowColor, Colors.transparent],
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(-0.92, 0.98),
                              radius: 0.58,
                              colors: [
                                palette.glowColorSecondary,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -120,
                  right: -80,
                  child: IgnorePointer(
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            palette.glowColor,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isDesktop)
                        _buildSidebar(
                          context: context,
                          palette: palette,
                          isDark: isDark,
                          languageProvider: languageProvider,
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isDesktop ? 0 : 12,
                            isDesktop ? 12 : 68,
                            12,
                            12,
                          ),
                          child: _buildTabContent(
                            context: context,
                            palette: palette,
                            isDark: isDark,
                            isDesktop: isDesktop,
                            isTablet: isTablet,
                            languageProvider: languageProvider,
                            themeProvider: themeProvider,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDesktop)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, top: 8),
                        child: IconButton(
                          tooltip: languageProvider.getText('menu'),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          icon: Icon(
                            Icons.menu_rounded,
                            color: palette.textPrimary,
                          ),
                        ),
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

  Widget _buildSidebar({
    required BuildContext context,
    required _DashboardPalette palette,
    required bool isDark,
    required LanguageProvider languageProvider,
  }) {
    final user = _currentUser ??
        const User(
          id: '',
          name: '',
          email: '',
          role: 'USER',
          roles: ['USER'],
        );

    return Container(
      width: 104,
      margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      decoration: BoxDecoration(
        color: palette.sidebarBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.sidebarBorder),
        boxShadow: [
          BoxShadow(
            color: palette.sidebarShadow,
            blurRadius: 35,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: 0.42,
                    child: Opacity(
                      opacity: isDark ? 0.12 : 0.09,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                            _sidebarImageFilterMatrix(isDark)),
                        child: Image.asset(
                          _sidebarWatermarkAsset(isDark),
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                children: [
                  Tooltip(
                    message: 'SMF',
                    waitDuration: const Duration(milliseconds: 250),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: palette.sidebarBackground,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: palette.sidebarBorder),
                        boxShadow: [
                          BoxShadow(
                            color: palette.primaryBlue.withValues(alpha: 0.20),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/images/logo_smf_clear.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _sidebarItem(
                          label: languageProvider.getText('dashboard'),
                          icon: Icons.dashboard_rounded,
                          tab: _DashboardTab.dashboard,
                          palette: palette,
                        ),
                        _sidebarItem(
                          label: languageProvider.getText('map'),
                          icon: Icons.map_outlined,
                          tab: _DashboardTab.map,
                          palette: palette,
                        ),
                        _sidebarItem(
                          label: languageProvider.getText('alerts'),
                          icon: Icons.notifications_none_rounded,
                          tab: _DashboardTab.alerts,
                          palette: palette,
                        ),
                        _sidebarItem(
                          label: languageProvider.getText('roles'),
                          icon: Icons.admin_panel_settings_outlined,
                          tab: _DashboardTab.roles,
                          palette: palette,
                        ),
                        _sidebarItem(
                          label: languageProvider.getText('zones'),
                          icon: Icons.location_city_outlined,
                          tab: _DashboardTab.zones,
                          palette: palette,
                        ),
                        _sidebarItem(
                          label: languageProvider.getText('announcements'),
                          icon: Icons.campaign_rounded,
                          tab: _DashboardTab.announcements,
                          palette: palette,
                        ),
                        _sidebarItem(
                          label: languageProvider.getText('emergency'),
                          icon: Icons.warning_amber_rounded,
                          tab: _DashboardTab.emergency,
                          palette: palette,
                        ),
                        _sidebarItem(
                          label: languageProvider.getText('users'),
                          icon: Icons.people_outline_rounded,
                          tab: _DashboardTab.users,
                          palette: palette,
                        ),
                        _sidebarItem(
                          label: languageProvider.getText('reports'),
                          icon: Icons.description_outlined,
                          tab: _DashboardTab.reports,
                          palette: palette,
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Profile - ${_displayName(user)}',
                    waitDuration: const Duration(milliseconds: 250),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.pushNamed(context, '/profile').then((_) {
                          _loadProfileImage();
                        });
                      },
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: palette.workerCardBackground,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: palette.cardBorder.withValues(alpha: 0.9)),
                          boxShadow: [
                            BoxShadow(
                              color: palette.cardGlow.withValues(alpha: 0.12),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _SidebarProfileAvatar(
                          imageUrl: _profileImageUrl?.trim().isNotEmpty == true
                              ? _profileImageUrl!.trim()
                              : user.pictureUrl,
                          palette: palette,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem({
    required String label,
    required IconData icon,
    required _DashboardTab tab,
    required _DashboardPalette palette,
    String? badge,
    Color? badgeColor,
  }) {
    final selected = _selectedTab == tab;
    final iconColor = selected ? Colors.white : palette.sidebarItemColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 250),
        preferBelow: false,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            _selectDashboardTab(tab);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(
                      colors: [palette.primaryBlue, palette.activeBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : Colors.transparent,
              border: Border.all(
                color: selected
                    ? palette.primaryBlue2.withValues(alpha: 0.30)
                    : palette.sidebarBorder.withValues(alpha: 0.18),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: palette.activeSidebarShadow,
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Icon(icon, color: iconColor, size: 27)),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor ?? palette.primaryBlue,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.sidebarBackground),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
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

  Widget _buildTabContent({
    required BuildContext context,
    required _DashboardPalette palette,
    required bool isDark,
    required bool isDesktop,
    required bool isTablet,
    required LanguageProvider languageProvider,
    required ThemeProvider themeProvider,
  }) {
    switch (_selectedTab) {
      case _DashboardTab.dashboard:
        return _buildDashboardHome(
          palette: palette,
          isDark: isDark,
          isDesktop: isDesktop,
          isTablet: isTablet,
          languageProvider: languageProvider,
          themeProvider: themeProvider,
        );
      case _DashboardTab.map:
        return _pageShell(
          title: languageProvider.getText('map'),
          subtitle: languageProvider.getText('mapSubtitleDashboard'),
          heroIcon: Icons.location_on_rounded,
          heroAccent: const Color(0xFF7C3AED),
          child: const MapOverviewPage(),
          palette: palette,
        );
      case _DashboardTab.alerts:
        return _buildAlertsPage(palette);
      case _DashboardTab.roles:
        return const RolesManagementPage();
      case _DashboardTab.zones:
        return _pageShell(
          title: languageProvider.getText('zones'),
          subtitle: languageProvider.getText('zonesSubtitleDashboard'),
          heroIcon: Icons.location_city_rounded,
          heroAccent: palette.goldAccent,
          child: const ZonesManagementPage(),
          palette: palette,
        );
      case _DashboardTab.announcements:
        return const AnnouncementsPage(embedded: true);
      case _DashboardTab.emergency:
        return _pageShell(
          title: languageProvider.getText('emergencyDashboard'),
          subtitle: languageProvider.getText('emergencySubtitleDashboard'),
          child: const EmergencyDashboardPage(),
          palette: palette,
        );
      case _DashboardTab.users:
        return _pageShell(
          title: languageProvider.getText('users'),
          subtitle: languageProvider.getText('usersSubtitleDashboard'),
          heroIcon: Icons.groups_rounded,
          heroAccent: palette.success,
          child: const UsersManagementPage(),
          palette: palette,
        );
      case _DashboardTab.reports:
        return ReportsPage(palette: palette);
    }
  }

  Widget _buildDashboardHome({
    required _DashboardPalette palette,
    required bool isDark,
    required bool isDesktop,
    required bool isTablet,
    required LanguageProvider languageProvider,
    required ThemeProvider themeProvider,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const gap = 20.0;

        final topColumns = width >= 760 ? 2 : 1;
        final topMetricHeight = width >= 760 ? 260.0 : 240.0;

        final bottomColumns = width >= 1280
            ? 3
            : width >= 860
                ? 2
                : 1;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(width < 560 ? 14 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(
                  palette: palette,
                  isDark: isDark,
                  isDesktop: isDesktop,
                  languageProvider: languageProvider,
                  themeProvider: themeProvider,
                ),
                const SizedBox(height: 24),
                _systemOverviewCard(palette: palette),
                const SizedBox(height: 24),
                GridView.builder(
                  itemCount: 2,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: topColumns,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    mainAxisExtent: topMetricHeight,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final cards = [
                      _metricCard(
                        title: languageProvider.getText('onlineUsers'),
                        value: (_onlineUserCount ?? 0).toString(),
                        delta: '',
                        deltaLabel: languageProvider.getText('usersInSystem'),
                        accent: palette.success,
                        icon: Icons.groups_rounded,
                        palette: palette,
                        onTap: () => _selectDashboardTab(_DashboardTab.users),
                      ),
                      _metricCard(
                        title: languageProvider.getText('devices'),
                        value: (_smfDeviceCount ?? 0).toString(),
                        delta: '',
                        deltaLabel:
                            languageProvider.getText('smfDevicesRegistered'),
                        accent: palette.primaryBlue2,
                        icon: Icons.memory_rounded,
                        palette: palette,
                      ),
                    ];
                    return cards[index];
                  },
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: bottomColumns,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  childAspectRatio: bottomColumns == 3
                      ? 0.98
                      : bottomColumns == 2
                          ? 0.95
                          : 0.82,
                  children: [
                    _recentAlertsCard(
                      palette: palette,
                      languageProvider: languageProvider,
                    ),
                    _deviceOverviewCard(
                      palette: palette,
                      languageProvider: languageProvider,
                    ),
                    _quickActionsCard(
                      palette: palette,
                      languageProvider: languageProvider,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '© 2025 SMF Security Monitoring. All rights reserved.',
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero({
    required _DashboardPalette palette,
    required bool isDark,
    required bool isDesktop,
    required LanguageProvider languageProvider,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      height: isDesktop ? 280 : 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_heroImageFilterMatrix(isDark)),
                child: Image.asset(
                  _heroAsset(isDark),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: palette.heroHorizontalOverlay,
                    stops: const [0, 0.38, 0.68, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: palette.heroBottomFade,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 28 : 20,
                18,
                isDesktop ? 28 : 18,
                isDesktop ? 22 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _heroPill(
                              palette: palette,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaleTransition(
                                    scale: Tween<double>(begin: 0.9, end: 1.18)
                                        .animate(
                                      CurvedAnimation(
                                        parent: _livePulse,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: palette.success,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Live',
                                    style: TextStyle(
                                      color: palette.heroText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _heroPill(
                              palette: palette,
                              onTap: languageProvider.toggleLanguage,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    languageProvider.isArabic ? 'AR' : 'EN',
                                    style: TextStyle(
                                      color: palette.heroText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: palette.heroText,
                                  ),
                                ],
                              ),
                            ),
                            _themeToggle(
                              themeProvider: themeProvider,
                              palette: palette,
                            ),
                            _heroPill(
                              palette: palette,
                              onTap: () => _showNotificationsPanel(palette),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: palette.heroText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 560 : 420,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: palette.heroText,
                              fontWeight: FontWeight.w800,
                              fontSize: isDesktop ? 44 : 32,
                              height: 1.08,
                              shadows: [
                                Shadow(
                                  color: palette.heroTitleGlow,
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            children: [
                              TextSpan(
                                  text: '${_greeting(languageProvider)}, '),
                              TextSpan(
                                text: _displayName(_currentUser ??
                                    const User(
                                      id: '',
                                      name: '',
                                      email: '',
                                      role: 'USER',
                                      roles: ['USER'],
                                    )),
                                style: TextStyle(
                                  color: palette.heroHighlight,
                                  shadows: [
                                    Shadow(
                                      color: palette.heroHighlightGlow,
                                      blurRadius: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _heroAccentRule(palette),
                            Text(
                              languageProvider.getText('securityTagline'),
                              style: TextStyle(
                                color: palette.heroText,
                                fontSize: isDesktop ? 26 : 18,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: palette.heroTitleGlow
                                        .withValues(alpha: 0.22),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            _heroAccentRule(palette),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(User user) {
    final name = user.name.trim();
    if (name.isNotEmpty) return name;
    final email = user.email.trim();
    if (email.isNotEmpty) return email.split('@').first;
    if (_displayRole(user).toUpperCase().contains('ADMIN')) {
      return context.read<LanguageProvider>().getText('roleAdmin');
    }
    return context.read<LanguageProvider>().getText('user');
  }

  String _displayRole(User user) {
    final roles = user.roles
        .where((role) => role.trim().isNotEmpty)
        .map((role) => role.replaceFirst(RegExp(r'^ROLE_'), ''))
        .toList();
    final role = (user.role ?? '').trim().replaceFirst(RegExp(r'^ROLE_'), '');
    if (role.isNotEmpty) return role.toUpperCase();
    if (roles.isNotEmpty) return roles.first.toUpperCase();
    return 'USER';
  }

  Widget _heroAccentRule(_DashboardPalette palette) {
    return Container(
      width: 42,
      height: 2,
      color: palette.goldAccent,
    );
  }

  Widget _heroPill({
    required _DashboardPalette palette,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.heroControlBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.heroControlBorder),
        ),
        child: child,
      ),
    );
  }

  Widget _themeToggle({
    required ThemeProvider themeProvider,
    required _DashboardPalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.heroControlBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.heroControlBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: !themeProvider.isDarkMode
                    ? palette.primaryBlue
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                Icons.wb_sunny_outlined,
                color: !themeProvider.isDarkMode
                    ? Colors.white
                    : palette.goldAccent,
              ),
            ),
          ),
          InkWell(
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? palette.primaryBlue
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                Icons.nights_stay_rounded,
                color:
                    themeProvider.isDarkMode ? Colors.white : palette.heroText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotificationsPanel(_DashboardPalette palette) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.56,
          minChildSize: 0.32,
          maxChildSize: 0.86,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setPanelState) {
                const notifications = <_AlertRecord>[];
                final unreadCount =
                    (notifications.length - _readNotificationIndexes.length)
                        .clamp(0, notifications.length);

                return Container(
                  margin: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.cardBackground,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: palette.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: palette.cardShadow.withValues(alpha: 0.4),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: palette.textMuted.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    palette.primaryBlue.withValues(alpha: 0.14),
                              ),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                color: palette.primaryBlue2,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notifications',
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '$unreadCount unread operational updates',
                                    style: TextStyle(color: palette.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (notifications.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _readNotificationIndexes
                                      ..clear()
                                      ..addAll(
                                        List<int>.generate(
                                          notifications.length,
                                          (index) => index,
                                        ),
                                      );
                                  });
                                  setPanelState(() {});
                                },
                                child: const Text('Mark all read'),
                              ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close_rounded,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: notifications.isEmpty
                            ? ListView(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 24, 20, 28),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: palette.innerCardBackground,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: palette.innerCardBorder,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.notifications_off_outlined,
                                          size: 42,
                                          color: palette.textMuted,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No notifications yet',
                                          style: TextStyle(
                                            color: palette.textPrimary,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Critical updates will appear here when available.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: palette.textMuted,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 6, 20, 22),
                                itemCount: notifications.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final alert = notifications[index];
                                  final read =
                                      _readNotificationIndexes.contains(index);
                                  final accent = alert.severity == 'High'
                                      ? palette.danger
                                      : alert.severity == 'Medium'
                                          ? palette.warning
                                          : palette.success;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _readNotificationIndexes.add(index);
                                        _selectedAlertIndex = index;
                                      });
                                      _selectDashboardTab(_DashboardTab.alerts);
                                      Navigator.pop(context);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: read
                                            ? palette.innerCardBackground
                                            : accent.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: read
                                              ? palette.innerCardBorder
                                              : accent.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: accent.withValues(
                                                  alpha: 0.16),
                                            ),
                                            child: Icon(
                                              Icons.campaign_rounded,
                                              color: accent,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        alert.title,
                                                        style: TextStyle(
                                                          color: palette
                                                              .textPrimary,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    if (!read)
                                                      Container(
                                                        width: 9,
                                                        height: 9,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: accent,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  alert.description,
                                                  style: TextStyle(
                                                    color: palette.textMuted,
                                                    height: 1.35,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    _notificationChip(
                                                      label: alert.severity,
                                                      color: accent,
                                                      palette: palette,
                                                    ),
                                                    _notificationChip(
                                                      label: alert.status,
                                                      color:
                                                          palette.primaryBlue2,
                                                      palette: palette,
                                                    ),
                                                    _notificationChip(
                                                      label: alert.timeLabel,
                                                      color: palette.textMuted,
                                                      palette: palette,
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
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _notificationChip({
    required String label,
    required Color color,
    required _DashboardPalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == palette.textMuted ? palette.textMuted : color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _glassCard({
    required _DashboardPalette palette,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardOutlineGlow,
            blurRadius: 0,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 45,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: palette.cardGlow.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: palette.isDark ? 0.05 : 0.02),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String delta,
    required String deltaLabel,
    required Color accent,
    required IconData icon,
    required _DashboardPalette palette,
    VoidCallback? onTap,
  }) {
    final card = _glassCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: palette.isDark ? 0.34 : 0.22),
                      accent.withValues(alpha: 0.10),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: palette.numberText,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (delta.isNotEmpty) ...[
                Text(
                  delta,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  deltaLabel,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 26,
            child: CustomPaint(
              painter: _SparklinePainter(color: accent),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      ),
    );
  }

  Widget _systemOverviewCard({
    required _DashboardPalette palette,
  }) {
    final languageProvider = context.watch<LanguageProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final qrSize = compact ? 150.0 : 172.0;
        final qr = Container(
          width: qrSize,
          height: qrSize,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/qr.jpeg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        );
        final copy = Column(
          crossAxisAlignment:
              compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan Me',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 31,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'SMF',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 27,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              languageProvider.getText('securityTagline'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                color: Color(0xFFAFC2E7),
                height: 1.35,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: compact ? 330 : 220),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 32,
            vertical: compact ? 28 : 24,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF092D50),
                Color(0xFF061E3C),
                Color(0xFF03142D),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF145C93)),
            boxShadow: [
              BoxShadow(
                color: palette.cardShadow,
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                right: compact ? -90 : 70,
                bottom: -70,
                child: Container(
                  width: compact ? 160 : 240,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF1F78B4).withValues(alpha: 0.44),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              compact
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        qr,
                        const SizedBox(height: 18),
                        copy,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        qr,
                        const SizedBox(width: 28),
                        Expanded(child: copy),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _recentAlertsCard({
    required _DashboardPalette palette,
    required LanguageProvider languageProvider,
  }) {
    return _glassCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                languageProvider.getText('recentAlerts'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _selectDashboardTab(_DashboardTab.alerts),
                child: Text(languageProvider.getText('viewAll')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Column(
              children: _alerts.take(3).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final alert = entry.value;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.innerCardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.innerCardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: _severityColor(alert.severity, palette),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _localizedAlertTitle(alert),
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _localizedTimeLabel(alert.timeLabel),
                                style: TextStyle(color: palette.textMuted),
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
                            color: _severityColor(alert.severity, palette)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _localizedSeverity(alert.severity),
                            style: TextStyle(
                              color: _severityColor(alert.severity, palette),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceOverviewCard({
    required _DashboardPalette palette,
    required LanguageProvider languageProvider,
  }) {
    return _glassCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageProvider.getText('deviceOverview'),
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Color(0xFF22C55E),
                        Color(0xFF22C55E),
                        Color(0xFFEF4444),
                        Color(0xFFF59E0B),
                        Color(0xFF94A3B8),
                        Color(0xFF22C55E),
                      ],
                      stops: [0.0, 0.58, 0.76, 0.87, 0.94, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: palette.cardBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (_smfDeviceCount ?? 0).toString(),
                            style: TextStyle(
                              color: palette.numberText,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            languageProvider.getText('total'),
                            style: TextStyle(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendItem(
                        languageProvider.getText('registered'),
                        (_registeredSmfDeviceCount ?? 0).toString(),
                        palette.success,
                        palette,
                      ),
                      _legendItem(
                        languageProvider.getText('unregistered'),
                        ((_smfDeviceCount ?? 0) -
                                (_registeredSmfDeviceCount ?? 0))
                            .clamp(0, 999999)
                            .toString(),
                        palette.warning,
                        palette,
                      ),
                      _legendItem(
                        languageProvider.getText('totalDevices'),
                        (_smfDeviceCount ?? 0).toString(),
                        palette.primaryBlue2,
                        palette,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    String label,
    String value,
    Color color,
    _DashboardPalette palette,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionsCard({
    required _DashboardPalette palette,
    required LanguageProvider languageProvider,
  }) {
    return _glassCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageProvider.getText('quickActions'),
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 420 ? 2 : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: columns == 2 ? 1.55 : 2.45,
                  children: [
                    _quickActionTile(
                      label: languageProvider.getText('viewMap'),
                      icon: Icons.location_on_outlined,
                      accent: const Color(0xFF7C3AED),
                      onTap: () => _selectDashboardTab(_DashboardTab.map),
                      palette: palette,
                    ),
                    _quickActionTile(
                      label: languageProvider.getText('announcements'),
                      icon: Icons.campaign_rounded,
                      accent: palette.goldAccent,
                      onTap: () =>
                          _selectDashboardTab(_DashboardTab.announcements),
                      palette: palette,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    required _DashboardPalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(
          color: palette.quickActionBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.quickActionBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: palette.isDark ? 0.34 : 0.22),
                    accent.withValues(alpha: 0.10),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.24),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageShell({
    required String title,
    required String subtitle,
    required Widget child,
    required _DashboardPalette palette,
    IconData? heroIcon,
    Color? heroAccent,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final accent = heroAccent ?? palette.primaryBlue;
        final iconSize = compact ? 64.0 : 86.0;
        final titleSize = compact ? 30.0 : 36.0;
        final heroText = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: titleSize,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: compact ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: compact ? 15 : 17,
                height: 1.35,
              ),
            ),
          ],
        );
        final headerContent = heroIcon == null
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 24 : 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          maxLines: compact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: palette.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.14),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      heroIcon,
                      color: accent,
                      size: compact ? 32 : 42,
                    ),
                  ),
                  SizedBox(width: compact ? 0 : 18, height: compact ? 14 : 0),
                  if (compact) heroText else Expanded(child: heroText),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 20,
                compact ? 12 : 20,
                compact ? 12 : 20,
                0,
              ),
              child: headerContent,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget _buildAlertsPage(_DashboardPalette palette) {
    final lang = context.watch<LanguageProvider>();
    final alertsPalette = palette;
    final filteredAlerts = _filteredAlerts();
    final selectedAlert = _selectedAlert(filteredAlerts);
    final totalAlerts = _alerts.length;
    final highAlerts =
        _alerts.where((alert) => alert.severity == 'High').length;
    final mediumAlerts =
        _alerts.where((alert) => alert.severity == 'Medium').length;
    final lowAlerts = _alerts.where((alert) => alert.severity == 'Low').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1320;
        final isTablet = width >= 900;
        final statColumns = width >= 1180
            ? 4
            : width >= 760
                ? 2
                : 1;
        final stackHeader = width < 980;
        final stackToolbar = width < 1100;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: alertsPalette.cardBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: alertsPalette.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: alertsPalette.cardShadow.withValues(alpha: 0.95),
                      blurRadius: 45,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: stackHeader
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _alertsHeaderContent(alertsPalette),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _alertsHeaderContent(alertsPalette)),
                        ],
                      ),
              ),
              const SizedBox(height: 22),
              GridView.count(
                crossAxisCount: statColumns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: statColumns == 4
                    ? 1.45
                    : statColumns == 2
                        ? 1.5
                        : 1.45,
                children: [
                  _alertStatCard(
                    palette: alertsPalette,
                    label: lang.getText('totalAlerts'),
                    value: '$totalAlerts',
                    sublabel: lang.getText('totalAlerts'),
                    color: palette.danger,
                    icon: Icons.hexagon_outlined,
                    selected: _alertSeverityFilter == 'All',
                    onTap: () => _setAlertSeverityFilter('All'),
                  ),
                  _alertStatCard(
                    palette: alertsPalette,
                    label: lang.getText('highPriority'),
                    value: '$highAlerts',
                    sublabel: lang.getText('highAlerts'),
                    color: palette.danger,
                    icon: Icons.report_gmailerrorred_rounded,
                    selected: _alertSeverityFilter == 'High',
                    onTap: () => _setAlertSeverityFilter('High'),
                  ),
                  _alertStatCard(
                    palette: alertsPalette,
                    label: lang.getText('mediumPriority'),
                    value: '$mediumAlerts',
                    sublabel: lang.getText('mediumAlerts'),
                    color: palette.warning,
                    icon: Icons.warning_amber_rounded,
                    selected: _alertSeverityFilter == 'Medium',
                    onTap: () => _setAlertSeverityFilter('Medium'),
                  ),
                  _alertStatCard(
                    palette: alertsPalette,
                    label: lang.getText('lowPriority'),
                    value: '$lowAlerts',
                    sublabel: lang.getText('lowAlerts'),
                    color: palette.primaryBlue2,
                    icon: Icons.info_outline_rounded,
                    selected: _alertSeverityFilter == 'Low',
                    onTap: () => _setAlertSeverityFilter('Low'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              stackToolbar
                  ? Column(
                      children: [
                        _alertsSearchBar(alertsPalette),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _alertsToolbarButton(
                                palette: alertsPalette,
                                label: _localizedFilter(_alertSeverityFilter),
                                icon: Icons.filter_alt_outlined,
                                items: const ['All', 'High', 'Medium', 'Low'],
                                onSelected: (value) {
                                  _setAlertSeverityFilter(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _alertsToolbarButton(
                                palette: alertsPalette,
                                label: _localizedDateRange(_alertDateRange),
                                icon: Icons.calendar_today_outlined,
                                items: const [
                                  'Today',
                                  'Last 7 days',
                                  'This month'
                                ],
                                onSelected: (value) {
                                  setState(() {
                                    _alertDateRange = value;
                                    _alertsCurrentPage = 1;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _alertsSearchBar(alertsPalette)),
                        const SizedBox(width: 14),
                        _alertsToolbarButton(
                          palette: alertsPalette,
                          label: _localizedFilter(_alertSeverityFilter),
                          icon: Icons.filter_alt_outlined,
                          items: const ['All', 'High', 'Medium', 'Low'],
                          onSelected: (value) {
                            _setAlertSeverityFilter(value);
                          },
                        ),
                        const SizedBox(width: 14),
                        _alertsToolbarButton(
                          palette: alertsPalette,
                          label: _localizedDateRange(_alertDateRange),
                          icon: Icons.calendar_today_outlined,
                          items: const ['Today', 'Last 7 days', 'This month'],
                          onSelected: (value) {
                            setState(() {
                              _alertDateRange = value;
                              _alertsCurrentPage = 1;
                            });
                          },
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _alertsListPanel(
                        palette: alertsPalette,
                        alerts: filteredAlerts,
                        compact: width < 1500,
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 340,
                      child: _alertDetailsPanel(
                        palette: alertsPalette,
                        alert: selectedAlert,
                      ),
                    ),
                  ],
                )
              else ...[
                _alertsListPanel(
                  palette: alertsPalette,
                  alerts: filteredAlerts,
                  compact: true,
                ),
                const SizedBox(height: 20),
                if (selectedAlert != null)
                  SizedBox(
                    width: double.infinity,
                    child: _alertDetailsPanel(
                      palette: alertsPalette,
                      alert: selectedAlert,
                    ),
                  ),
              ],
              if (!isWide && isTablet) const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _alertsHeaderContent(_DashboardPalette palette) {
    final lang = context.read<LanguageProvider>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                palette.danger.withValues(alpha: 0.16),
                palette.danger.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: palette.danger.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.danger.withValues(alpha: 0.4),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            color: palette.danger,
            size: 40,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.getText('alerts'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lang.getText('alertsSubtitle'),
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _alertsSearchBar(_DashboardPalette palette) {
    final lang = context.read<LanguageProvider>();
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: palette.innerCardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.innerCardBorder),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _alertSearchQuery = value;
            _alertsCurrentPage = 1;
          });
        },
        style: TextStyle(color: palette.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: palette.textMuted,
          ),
          hintText: lang.getText('searchAlerts'),
          hintStyle: TextStyle(color: palette.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _alertStatCard({
    required _DashboardPalette palette,
    required String label,
    required String value,
    required String sublabel,
    required Color color,
    required IconData icon,
    required bool selected,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.82) : palette.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 45,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: palette.cardOutlineGlow,
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: palette.numberText,
                fontSize: 42,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            sublabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: card,
      ),
    );
  }

  Widget _alertsToolbarButton({
    required _DashboardPalette palette,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: palette.workerCardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              child: Text(
                items.contains('Today')
                    ? _localizedDateRange(item)
                    : _localizedFilter(item),
                style: TextStyle(color: palette.textPrimary),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: palette.innerCardBackground.withValues(
            alpha: palette.isDark ? 0.7 : 0.9,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.textPrimary, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.expand_more_rounded, color: palette.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _alertsListPanel({
    required _DashboardPalette palette,
    required List<_AlertRecord> alerts,
    required bool compact,
  }) {
    final lang = context.read<LanguageProvider>();
    final totalAlerts = alerts.length;
    final totalPages = totalAlerts == 0
        ? 1
        : ((totalAlerts + _alertsPerPage - 1) ~/ _alertsPerPage);
    final currentPage = _alertsCurrentPage.clamp(1, totalPages);
    final pageStart = (currentPage - 1) * _alertsPerPage;
    final pageEnd = (pageStart + _alertsPerPage).clamp(0, totalAlerts);
    final visibleAlerts = alerts.sublist(pageStart, pageEnd);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 36,
                    child: Text(
                      lang.getText('alert'),
                      style: TextStyle(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 12,
                    child: Text(
                      lang.getText('severity'),
                      style: TextStyle(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      lang.getText('source'),
                      style: TextStyle(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 18,
                    child: Text(
                      lang.getText('time'),
                      style: TextStyle(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 12,
                    child: Text(
                      lang.getText('status'),
                      style: TextStyle(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      lang.getText('actions'),
                      style: TextStyle(
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                lang.getText('noAlertsMatch'),
                style: TextStyle(color: palette.textMuted),
              ),
            )
          else
            ...visibleAlerts.map(
                (alert) => _buildAlertListRowForPanel(palette, compact)(alert)),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  lang
                      .getText('showingAlerts')
                      .replaceAll('{start}', '${pageStart + 1}')
                      .replaceAll('{end}', '$pageEnd')
                      .replaceAll('{total}', '$totalAlerts'),
                  style: TextStyle(color: palette.textMuted),
                ),
                const Spacer(),
                if (totalPages > 1)
                  ...List<int>.generate(totalPages, (index) => index + 1).map(
                    (page) {
                      final isActive = page == currentPage;
                      return InkWell(
                        onTap: () => setState(() => _alertsCurrentPage = page),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? palette.primaryBlue.withValues(alpha: 0.2)
                                : palette.innerCardBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? palette.primaryBlue2
                                  : palette.innerCardBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$page',
                            style: TextStyle(
                              color:
                                  isActive ? Colors.white : palette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget Function(_AlertRecord) _buildAlertListRowForPanel(
    _DashboardPalette palette,
    bool compact,
  ) {
    return (_AlertRecord alert) {
      final severityColor = _severityColor(alert.severity, palette);
      final source = _alertSource(alert);
      final sourceLabel = _localizedSource(source);
      final statusColor = _alertStatusColor(alert.status, palette);
      final index = _alerts.indexOf(alert);
      final isSelected = index == _selectedAlertIndex;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            if (index != -1) {
              setState(() => _selectedAlertIndex = index);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? palette.primaryBlue : palette.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.cardShadow
                      .withValues(alpha: isSelected ? 0.22 : 0.15),
                  blurRadius: isSelected ? 25 : 18,
                  offset: const Offset(0, 10),
                ),
                if (isSelected)
                  BoxShadow(
                    color: palette.primaryBlue.withValues(alpha: 0.30),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: severityColor.withValues(alpha: 0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: severityColor.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: Icon(
                              _alertSeverityIcon(alert.severity),
                              color: severityColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _localizedAlertTitle(alert),
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _localizedAlertDescription(alert),
                                  style: TextStyle(
                                    color: palette.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _alertMenuButton(palette, index),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _pill(_localizedSeverity(alert.severity),
                              severityColor),
                          _pill(_localizedStatus(alert.status), statusColor),
                          _detailMetaChip(
                            palette: palette,
                            icon: _alertSourceIcon(source),
                            label: sourceLabel,
                          ),
                          _detailMetaChip(
                            palette: palette,
                            icon: Icons.schedule_rounded,
                            label: _localizedTimeLabel(alert.timeLabel),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 36,
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: severityColor.withValues(alpha: 0.15),
                                boxShadow: [
                                  BoxShadow(
                                    color: severityColor.withValues(alpha: 0.4),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _alertSeverityIcon(alert.severity),
                                color: severityColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _localizedAlertTitle(alert),
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _localizedAlertDescription(alert),
                                    style: TextStyle(
                                      color: palette.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 12,
                        child: _pill(
                            _localizedSeverity(alert.severity), severityColor),
                      ),
                      Expanded(
                        flex: 16,
                        child: Row(
                          children: [
                            Icon(
                              _alertSourceIcon(source),
                              color: palette.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sourceLabel,
                                style: TextStyle(color: palette.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localizedTimeLabel(alert.timeLabel),
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '2025-05-16 11:45',
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 12,
                        child:
                            _pill(_localizedStatus(alert.status), statusColor),
                      ),
                      Expanded(
                        flex: 6,
                        child: _alertMenuButton(palette, index),
                      ),
                    ],
                  ),
          ),
        ),
      );
    };
  }

  Widget _alertMenuButton(_DashboardPalette palette, int index) {
    final lang = context.read<LanguageProvider>();
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _showAlertDialog(palette, index: index);
        } else if (value == 'delete') {
          _deleteAlert(index);
        }
      },
      color: palette.workerCardBackground,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Text(
            lang.getText('edit'),
            style: TextStyle(color: palette.textPrimary),
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            lang.getText('delete'),
            style: TextStyle(color: palette.textPrimary),
          ),
        ),
      ],
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: palette.innerCardBackground,
            shape: BoxShape.circle,
            border: Border.all(color: palette.innerCardBorder),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            color: palette.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _detailMetaChip({
    required _DashboardPalette palette,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.innerCardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.innerCardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: palette.textMuted, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertDetailsPanel({
    required _DashboardPalette palette,
    required _AlertRecord? alert,
  }) {
    final lang = context.read<LanguageProvider>();
    if (alert == null) {
      return const SizedBox.shrink();
    }

    final severityColor = _severityColor(alert.severity, palette);
    final statusColor = _alertStatusColor(alert.status, palette);
    final source = _alertSource(alert);
    final sourceLabel = _localizedSource(source);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                lang.getText('alertDetails'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: lang.getText('back'),
                onPressed: _goBackFromDashboardTab,
                icon: Icon(Icons.close_rounded, color: palette.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.innerCardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: severityColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        severityColor.withValues(alpha: 0.32),
                        severityColor.withValues(alpha: 0.08),
                      ],
                    ),
                    border:
                        Border.all(color: severityColor.withValues(alpha: 0.5)),
                  ),
                  child: Icon(
                    _alertSeverityIcon(alert.severity),
                    color: severityColor,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizedAlertTitle(alert),
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _pill(
                        alert.severity == 'High'
                            ? lang.getText('highPriority')
                            : alert.severity == 'Medium'
                                ? lang.getText('mediumPriority')
                                : lang.getText('lowPriority'),
                        severityColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${lang.getText('alertId')} ALT-2025-0516-001',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '2025-05-16 11:45 (${_localizedTimeLabel(alert.timeLabel)})',
                        style: TextStyle(color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _detailRow(
            palette: palette,
            label: lang.getText('description'),
            value: _localizedAlertDescription(alert),
          ),
          _detailRow(
            palette: palette,
            label: lang.getText('source'),
            value: sourceLabel,
          ),
          _detailRow(
            palette: palette,
            label: lang.getText('location'),
            value: _localizedLocation(alert),
          ),
          _detailRow(
            palette: palette,
            label: lang.getText('ipAddress'),
            value: _alertIpAddress(alert),
          ),
          _detailRow(
            palette: palette,
            label: lang.getText('device'),
            value: _alertDevice(alert),
          ),
          _detailRow(
            palette: palette,
            label: lang.getText('userAgent'),
            value: _alertUserAgent(alert),
          ),
          _detailRow(
            palette: palette,
            label: lang.getText('severity'),
            valueWidget:
                _pill(_localizedSeverity(alert.severity), severityColor),
          ),
          _detailRow(
            palette: palette,
            label: lang.getText('status'),
            valueWidget: _pill(_localizedStatus(alert.status), statusColor),
          ),
          const SizedBox(height: 18),
          Text(
            lang.getText('actions'),
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateAlertStatus(alert, 'Acknowledged'),
              icon: const Icon(Icons.check_rounded),
              label: Text(lang.getText('acknowledgeAlert')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                backgroundColor: palette.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateAlertStatus(alert, 'In Progress'),
                  icon: Icon(Icons.north_east_rounded, color: palette.warning),
                  label: Text(
                    lang.getText('escalate'),
                    style: TextStyle(color: palette.textPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: palette.warning.withValues(alpha: 0.7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateAlertStatus(alert, 'Resolved'),
                  icon: Icon(Icons.verified_user_outlined,
                      color: palette.success),
                  label: Text(
                    lang.getText('markResolved'),
                    style: TextStyle(color: palette.textPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: palette.success.withValues(alpha: 0.7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required _DashboardPalette palette,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.innerCardBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '',
                  style: TextStyle(color: palette.textMuted, height: 1.45),
                ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _showAlertDialog(
    _DashboardPalette palette, {
    int? index,
  }) async {
    final existing = index == null ? null : _alerts[index];
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    String severity = existing?.severity ?? 'Medium';
    String status = existing?.status ?? 'Open';
    final lang = context.read<LanguageProvider>();

    final result = await showDialog<_AlertRecord>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            index == null
                ? lang.getText('addAlert')
                : lang.getText('editAlert'),
            style: TextStyle(color: palette.textPrimary),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration:
                          InputDecoration(labelText: lang.getText('title')),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                          labelText: lang.getText('description')),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: severity,
                      items: [
                        DropdownMenuItem(
                          value: 'Low',
                          child: Text(lang.getText('low')),
                        ),
                        DropdownMenuItem(
                          value: 'Medium',
                          child: Text(lang.getText('medium')),
                        ),
                        DropdownMenuItem(
                          value: 'High',
                          child: Text(lang.getText('high')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => severity = value);
                        }
                      },
                      decoration:
                          InputDecoration(labelText: lang.getText('severity')),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      items: [
                        DropdownMenuItem(
                          value: 'Open',
                          child: Text(lang.getText('open')),
                        ),
                        DropdownMenuItem(
                          value: 'Investigating',
                          child: Text(lang.getText('investigating')),
                        ),
                        DropdownMenuItem(
                          value: 'Acknowledged',
                          child: Text(lang.getText('acknowledged')),
                        ),
                        DropdownMenuItem(
                          value: 'Closed',
                          child: Text(lang.getText('closed')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => status = value);
                        }
                      },
                      decoration:
                          InputDecoration(labelText: lang.getText('status')),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.getText('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _AlertRecord(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    severity: severity,
                    status: status,
                    timeLabel: existing?.timeLabel ?? lang.getText('justNow'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                  index == null ? lang.getText('add') : lang.getText('save')),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (index == null) {
        _alerts.insert(0, result);
        _selectedAlertIndex = 0;
      } else {
        _alerts[index] = result;
        _selectedAlertIndex = index;
      }
    });
  }

  Future<void> _deleteAlert(int index) async {
    final lang = context.read<LanguageProvider>();
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(lang.getText('deleteAlertQuestion')),
              content: Text(lang.getText('actionCannotBeUndone')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(lang.getText('cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(lang.getText('delete')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;
    setState(() {
      _alerts.removeAt(index);
      if (_alerts.isEmpty) {
        _selectedAlertIndex = 0;
      } else if (_selectedAlertIndex >= _alerts.length) {
        _selectedAlertIndex = _alerts.length - 1;
      }
    });
  }
}

class _SidebarProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final _DashboardPalette palette;

  const _SidebarProfileAvatar({
    required this.imageUrl,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = imageUrl?.trim();
    if (normalized == null || normalized.isEmpty) {
      return Icon(
        Icons.admin_panel_settings_rounded,
        color: palette.primaryBlue2,
      );
    }

    final memoryImage = _decodeSidebarDataImage(normalized);
    if (memoryImage != null) {
      return Image.memory(
        memoryImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.admin_panel_settings_rounded,
          color: palette.primaryBlue2,
        ),
      );
    }

    return Image.network(
      normalized,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.admin_panel_settings_rounded,
        color: palette.primaryBlue2,
      ),
    );
  }
}

Uint8List? _decodeSidebarDataImage(String value) {
  final commaIndex = value.indexOf(',');
  if (!value.startsWith('data:image/') || commaIndex == -1) return null;

  try {
    return base64Decode(value.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

class _AlertRecord {
  final String title;
  final String description;
  final String severity;
  final String status;
  final String timeLabel;

  const _AlertRecord({
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.timeLabel,
  });
}

class _SparklinePainter extends CustomPainter {
  final Color color;

  const _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < 6; i++) {
      final x = size.width * (i / 5);
      final y = size.height * (0.6 - math.sin(i * 1.25) * 0.18);
      points.add(Offset(x, y));
    }

    path.moveTo(0, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final control = Offset((current.dx + next.dx) / 2, current.dy);
      final control2 = Offset((current.dx + next.dx) / 2, next.dy);
      path.cubicTo(
          control.dx, control.dy, control2.dx, control2.dy, next.dx, next.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DashboardPalette {
  final bool isDark;
  final Color pageBackground;
  final Color pageBackgroundEnd;
  final Color glowColor;
  final Color glowColorSecondary;
  final Color sidebarBackground;
  final Color sidebarBorder;
  final Color sidebarShadow;
  final Color sidebarItemColor;
  final Color activeSidebarShadow;
  final Color cardBackground;
  final Color cardBorder;
  final Color cardShadow;
  final Color cardGlow;
  final Color cardOutlineGlow;
  final Color workerCardBackground;
  final Color innerCardBackground;
  final Color innerCardBorder;
  final Color quickActionBackground;
  final Color quickActionBorder;
  final Color heroControlBackground;
  final Color heroControlBorder;
  final Color primaryBlue;
  final Color primaryBlue2;
  final Color activeBlue;
  final Color textPrimary;
  final Color numberText;
  final Color textMuted;
  final Color heroText;
  final Color heroHighlight;
  final Color heroTitleGlow;
  final Color heroHighlightGlow;
  final Color goldAccent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color linkColor;
  final Color systemGlow;
  final Color systemShieldStart;
  final Color systemShieldEnd;
  final List<Color> heroHorizontalOverlay;
  final List<Color> heroBottomFade;

  const _DashboardPalette({
    required this.isDark,
    required this.pageBackground,
    required this.pageBackgroundEnd,
    required this.glowColor,
    required this.glowColorSecondary,
    required this.sidebarBackground,
    required this.sidebarBorder,
    required this.sidebarShadow,
    required this.sidebarItemColor,
    required this.activeSidebarShadow,
    required this.cardBackground,
    required this.cardBorder,
    required this.cardShadow,
    required this.cardGlow,
    required this.cardOutlineGlow,
    required this.workerCardBackground,
    required this.innerCardBackground,
    required this.innerCardBorder,
    required this.quickActionBackground,
    required this.quickActionBorder,
    required this.heroControlBackground,
    required this.heroControlBorder,
    required this.primaryBlue,
    required this.primaryBlue2,
    required this.activeBlue,
    required this.textPrimary,
    required this.numberText,
    required this.textMuted,
    required this.heroText,
    required this.heroHighlight,
    required this.heroTitleGlow,
    required this.heroHighlightGlow,
    required this.goldAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.linkColor,
    required this.systemGlow,
    required this.systemShieldStart,
    required this.systemShieldEnd,
    required this.heroHorizontalOverlay,
    required this.heroBottomFade,
  });

  const _DashboardPalette.dark()
      : isDark = true,
        pageBackground = const Color(0xFF020B1F),
        pageBackgroundEnd = const Color(0xFF03142D),
        glowColor = const Color.fromRGBO(0, 184, 255, 0.18),
        glowColorSecondary = const Color.fromRGBO(11, 99, 246, 0.16),
        sidebarBackground = const Color.fromRGBO(3, 13, 34, 0.88),
        sidebarBorder = const Color.fromRGBO(56, 189, 248, 0.20),
        sidebarShadow = const Color.fromRGBO(0, 184, 255, 0.12),
        sidebarItemColor = const Color(0xFFD7E4FF),
        activeSidebarShadow = const Color.fromRGBO(0, 184, 255, 0.22),
        cardBackground = const Color.fromRGBO(5, 18, 45, 0.66),
        cardBorder = const Color.fromRGBO(56, 189, 248, 0.26),
        cardShadow = const Color.fromRGBO(0, 184, 255, 0.13),
        cardGlow = const Color.fromRGBO(0, 184, 255, 0.22),
        cardOutlineGlow = const Color.fromRGBO(56, 189, 248, 0.08),
        workerCardBackground = const Color.fromRGBO(5, 18, 45, 0.78),
        innerCardBackground = const Color.fromRGBO(255, 255, 255, 0.03),
        innerCardBorder = const Color.fromRGBO(255, 255, 255, 0.07),
        quickActionBackground = const Color.fromRGBO(255, 255, 255, 0.035),
        quickActionBorder = const Color.fromRGBO(56, 189, 248, 0.14),
        heroControlBackground = const Color.fromRGBO(5, 18, 45, 0.72),
        heroControlBorder = const Color.fromRGBO(255, 255, 255, 0.12),
        primaryBlue = const Color(0xFF0B63F6),
        primaryBlue2 = const Color(0xFF00B8FF),
        activeBlue = const Color(0xFF0038A8),
        textPrimary = const Color(0xFFF8FAFC),
        numberText = const Color(0xFFFFFFFF),
        textMuted = const Color(0xFF9DB2D8),
        heroText = const Color(0xFFFFFFFF),
        heroHighlight = const Color(0xFF38BDF8),
        heroTitleGlow = const Color.fromRGBO(56, 189, 248, 0.35),
        heroHighlightGlow = const Color.fromRGBO(56, 189, 248, 0.60),
        goldAccent = const Color(0xFFFBBF24),
        success = const Color(0xFF22C55E),
        warning = const Color(0xFFF59E0B),
        danger = const Color(0xFFEF4444),
        linkColor = const Color(0xFF38BDF8),
        systemGlow = const Color.fromRGBO(0, 184, 255, 0.35),
        systemShieldStart = const Color(0xFF2D68FF),
        systemShieldEnd = const Color(0xFF00B8FF),
        heroHorizontalOverlay = const [
          Color.fromRGBO(2, 11, 31, 0.82),
          Color.fromRGBO(2, 11, 31, 0.42),
          Color.fromRGBO(2, 11, 31, 0.18),
          Color.fromRGBO(2, 11, 31, 0.55),
        ],
        heroBottomFade = const [
          Color.fromRGBO(2, 11, 31, 0.05),
          Color.fromRGBO(2, 11, 31, 0.96),
        ];

  const _DashboardPalette.light()
      : isDark = false,
        pageBackground = const Color(0xFFF6FAFF),
        pageBackgroundEnd = const Color(0xFFEEF6FF),
        glowColor = const Color.fromRGBO(11, 99, 246, 0.10),
        glowColorSecondary = const Color.fromRGBO(103, 183, 255, 0.08),
        sidebarBackground = const Color.fromRGBO(255, 255, 255, 0.80),
        sidebarBorder = const Color.fromRGBO(59, 130, 246, 0.16),
        sidebarShadow = const Color.fromRGBO(11, 99, 246, 0.08),
        sidebarItemColor = const Color(0xFF061B5B),
        activeSidebarShadow = const Color.fromRGBO(11, 99, 246, 0.22),
        cardBackground = const Color.fromRGBO(255, 255, 255, 0.86),
        cardBorder = const Color.fromRGBO(59, 130, 246, 0.16),
        cardShadow = const Color.fromRGBO(11, 99, 246, 0.08),
        cardGlow = const Color.fromRGBO(11, 99, 246, 0.16),
        cardOutlineGlow = const Color.fromRGBO(59, 130, 246, 0.06),
        workerCardBackground = const Color.fromRGBO(255, 255, 255, 0.88),
        innerCardBackground = const Color.fromRGBO(255, 255, 255, 0.70),
        innerCardBorder = const Color.fromRGBO(59, 130, 246, 0.08),
        quickActionBackground = const Color.fromRGBO(255, 255, 255, 0.65),
        quickActionBorder = const Color.fromRGBO(59, 130, 246, 0.14),
        heroControlBackground = const Color.fromRGBO(255, 255, 255, 0.84),
        heroControlBorder = const Color.fromRGBO(59, 130, 246, 0.14),
        primaryBlue = const Color(0xFF0B63F6),
        primaryBlue2 = const Color(0xFF67B7FF),
        activeBlue = const Color(0xFF67B7FF),
        textPrimary = const Color(0xFF061B5B),
        numberText = const Color(0xFF061B5B),
        textMuted = const Color(0xFF6678A5),
        heroText = const Color(0xFF061B5B),
        heroHighlight = const Color(0xFF0B63F6),
        heroTitleGlow = const Color.fromRGBO(11, 99, 246, 0.14),
        heroHighlightGlow = const Color.fromRGBO(11, 99, 246, 0.26),
        goldAccent = const Color(0xFFFBBF24),
        success = const Color(0xFF16C784),
        warning = const Color(0xFFF59E0B),
        danger = const Color(0xFFEF4444),
        linkColor = const Color(0xFF0B63F6),
        systemGlow = const Color.fromRGBO(11, 99, 246, 0.20),
        systemShieldStart = const Color(0xFF0B63F6),
        systemShieldEnd = const Color(0xFF67B7FF),
        heroHorizontalOverlay = const [
          Color.fromRGBO(246, 250, 255, 0.88),
          Color.fromRGBO(246, 250, 255, 0.50),
          Color.fromRGBO(246, 250, 255, 0.18),
          Color.fromRGBO(246, 250, 255, 0.60),
        ],
        heroBottomFade = const [
          Color.fromRGBO(246, 250, 255, 0.05),
          Color.fromRGBO(246, 250, 255, 0.96),
        ];
}
