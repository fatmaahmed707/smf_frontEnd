import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mock_monitoring_data.dart';
import '../../models/event_log.dart';
import '../../providers/language_provider.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/events_service.dart';
import '../../services/users_service.dart';
import '../../services/zones_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/navigation_helper.dart';
import 'logout_dialog.dart';
import 'personal_info_page.dart';
import 'profile_image_picker.dart';
import 'work_info_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UsersService _usersService = UsersService();
  final ZonesService _zonesService = ZonesService();
  final EventsService _eventsService = EventsService();
  static const _profileImageKey = 'profile_image_url';
  static const _profileDisplayNameKey = 'profile_display_name';
  static const _firstActiveAtKey = 'profile_first_active_at';
  static const _notificationSettingsKey = 'profile_notification_settings';
  static const _reportsGeneratedCount = 3;
  User? _currentUser;
  String? _profileImageUrl;
  String? _profileDisplayName;
  int _alertsHandled = MockMonitoringData.alerts
      .where((alert) => alert.status.toLowerCase() != 'open')
      .length;
  int _zonesMonitored =
      MockMonitoringData.alerts.map((alert) => alert.zone).toSet().length;
  int _reportsGenerated = _reportsGeneratedCount;
  int _daysActive = 1;
  List<_Activity> _recentActivities = const [];
  final List<_ProfileNotification> _notifications = const [];
  final Set<int> _readNotificationIndexes = <int>{};
  Map<String, bool> _notificationSettings = {
    'critical': true,
    'reports': true,
    'announcements': false,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadProfileImage();
    _loadProfileDisplayName();
    _loadPreferences();
    _loadProfileStats();
    _loadRecentActivity();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationRaw = prefs.getString(_notificationSettingsKey);
    if (!mounted) return;
    setState(() {
      _notificationSettings = {
        ..._notificationSettings,
        ..._decodeBoolMap(notificationRaw),
      };
    });
  }

  Map<String, bool> _decodeBoolMap(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const {};
      return decoded.map((key, value) => MapEntry(key, value == true));
    } catch (_) {
      return const {};
    }
  }

  Future<void> _saveBoolMap(String key, Map<String, bool> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _profileImageUrl = prefs.getString(_profileImageKey));
  }

  Future<void> _loadProfileDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _profileDisplayName = prefs.getString(_profileDisplayNameKey));
  }

  Future<void> _loadProfileStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final firstActiveRaw = prefs.getString(_firstActiveAtKey);
    var firstActive = DateTime.tryParse(firstActiveRaw ?? '');
    if (firstActive == null) {
      firstActive = now;
      await prefs.setString(_firstActiveAtKey, firstActive.toIso8601String());
    }

    var zonesMonitored =
        MockMonitoringData.alerts.map((alert) => alert.zone).toSet().length;
    try {
      final zones = await _zonesService.getZones();
      zonesMonitored = zones.length;
    } catch (_) {
      // Keep the local alert-zone fallback when the API is unavailable.
    }

    if (!mounted) return;
    setState(() {
      _alertsHandled = MockMonitoringData.alerts
          .where((alert) => alert.status.toLowerCase() != 'open')
          .length;
      _zonesMonitored = zonesMonitored;
      _reportsGenerated = _reportsGeneratedCount;
      _daysActive = now.difference(firstActive!).inDays + 1;
    });
  }

  Future<void> _loadRecentActivity() async {
    try {
      final events = await _eventsService.getEvents(since: 3600 * 24 * 7);
      final sortedEvents = [...events]
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      if (!mounted) return;
      setState(() {
        _recentActivities = sortedEvents.take(8).map(_activityFromEvent).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recentActivities = const []);
    }
  }

  _Activity _activityFromEvent(EventLog event) {
    final normalized = event.eventType.trim().toLowerCase();
    final zone = event.zoneName?.trim();
    final device = event.macAddress.trim();
    final message = event.message?.trim();
    final title = message != null && message.isNotEmpty
        ? message
        : zone != null && zone.isNotEmpty
            ? '${_titleFromEventType(event.eventType)} in $zone'
            : device.isNotEmpty
                ? '${_titleFromEventType(event.eventType)} from $device'
                : _titleFromEventType(event.eventType);

    return _Activity(
      title,
      _relativeEventTime(event.createdAt),
      _iconForEvent(normalized),
      _colorForEvent(normalized),
    );
  }

  String _titleFromEventType(String eventType) {
    final cleaned = eventType
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'System event recorded';
    return cleaned
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _relativeEventTime(DateTime? createdAt) {
    if (createdAt == null) return 'Time unavailable';
    final diff = DateTime.now().difference(createdAt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return '${createdAt.toLocal().month}/${createdAt.toLocal().day}/${createdAt.toLocal().year}';
  }

  IconData _iconForEvent(String eventType) {
    if (eventType.contains('zone')) return Icons.location_on_rounded;
    if (eventType.contains('device') || eventType.contains('connect')) {
      return Icons.memory_rounded;
    }
    if (eventType.contains('alert') || eventType.contains('sos')) {
      return Icons.notifications_active_rounded;
    }
    if (eventType.contains('access') || eventType.contains('auth')) {
      return Icons.shield_rounded;
    }
    return Icons.history_rounded;
  }

  Color _colorForEvent(String eventType) {
    if (eventType.contains('sos') || eventType.contains('alert')) {
      return _ProfileColors.pink;
    }
    if (eventType.contains('zone')) return _ProfileColors.blue;
    if (eventType.contains('device') || eventType.contains('connect')) {
      return _ProfileColors.cyan;
    }
    if (eventType.contains('access') || eventType.contains('auth')) {
      return _ProfileColors.green;
    }
    return _ProfileColors.purple;
  }

  Future<void> _loadCurrentUser() async {
    final userId = AuthService.instance.userId;
    if (userId == null || userId.isEmpty) {
      setState(() => _currentUser = _fallbackUser);
      return;
    }

    try {
      final user = await _usersService.getUser(userId);
      if (!mounted) return;
      setState(() => _currentUser = user);
      if ((user.pictureUrl ?? '').trim().isNotEmpty) {
        setState(() => _profileImageUrl ??= user.pictureUrl!.trim());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _currentUser = _fallbackUser);
    }
  }

  Future<void> _saveProfileImage(String? imageUrl) async {
    final normalized = imageUrl?.trim();
    final prefs = await SharedPreferences.getInstance();
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(_profileImageKey);
    } else {
      await prefs.setString(_profileImageKey, normalized);
    }
    if (!mounted) return;
    setState(() =>
        _profileImageUrl = normalized?.isEmpty == true ? null : normalized);
  }

  void _openProfileEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
    ).then((_) {
      _loadCurrentUser();
      _loadProfileDisplayName();
    });
  }

  Future<void> _openAvatarPicker() async {
    final controller = TextEditingController(text: _profileImageUrl ?? '');
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AvatarSheet(
        palette: _ProfilePalette(context.read<ThemeProvider>().isDarkMode),
        controller: controller,
        currentImageUrl: _profileImageUrl,
      ),
    );
    controller.dispose();
    if (selected != null) await _saveProfileImage(selected);
  }

  void _openNotificationCenter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return _NotificationCenterSheet(
          palette: _ProfilePalette(context.read<ThemeProvider>().isDarkMode),
          notifications: _notifications,
          readIndexes: _readNotificationIndexes,
          onMarkAllRead: () {
            setState(() {
              _readNotificationIndexes
                ..clear()
                ..addAll(
                  List<int>.generate(_notifications.length, (index) => index),
                );
            });
          },
          onOpenNotification: (index) {
            setState(() => _readNotificationIndexes.add(index));
          },
        );
      },
    );
  }

  void _openSettingsPanel(_ProfilePanel panel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final palette =
            _ProfilePalette(context.read<ThemeProvider>().isDarkMode);
        switch (panel) {
          case _ProfilePanel.notifications:
            return _NotificationSettingsSheet(
              palette: palette,
              settings: _notificationSettings,
              onChanged: (key, value) {
                setState(() {
                  _notificationSettings = {
                    ..._notificationSettings,
                    key: value,
                  };
                });
                _saveBoolMap(_notificationSettingsKey, _notificationSettings);
              },
            );
        }
      },
    );
  }

  void _openRecentActivity() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecentActivitySheet(
        palette: _ProfilePalette(context.read<ThemeProvider>().isDarkMode),
        activities: _recentActivities,
      ),
    );
  }

  User get _fallbackUser => const User(
        id: '',
        name: 'Admin User',
        email: 'admin@smf.com',
        role: 'ADMIN',
        roles: ['ADMIN'],
      );

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final palette = _ProfilePalette(themeProvider.isDarkMode);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1180;
    final isTablet = size.width >= 760 && size.width < 1180;
    final outerPadding = size.width >= 900 ? 24.0 : 14.0;
    final shellPadding = size.width >= 760 ? 28.0 : 16.0;
    final currentUser = _currentUser ?? _fallbackUser;

    return WillPopScope(
      onWillPop: () => AppNavigation.handleSystemBack(context),
      child: Directionality(
        textDirection:
            languageProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
        backgroundColor: palette.background,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.backgroundGradient,
            ),
          ),
          child: SafeArea(
            minimum: EdgeInsets.only(top: size.width >= 760 ? 18 : 12),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(outerPadding, 10, outerPadding, 30),
              child: _GlassShell(
                palette: palette,
                padding: shellPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderBar(
                      palette: palette,
                      languageProvider: languageProvider,
                      themeProvider: themeProvider,
                      onNotificationsTap: _openNotificationCenter,
                      notificationCount: _notifications.length -
                          _readNotificationIndexes.length,
                    ),
                    const SizedBox(height: 34),
                    _TitleArea(
                      palette: palette,
                      title: languageProvider.getText('profile'),
                      subtitle: languageProvider.getText('profileSubtitle'),
                      onBack: () => AppNavigation.goBack(context),
                    ),
                    const SizedBox(height: 22),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 34,
                            child: _ProfileCard(
                              palette: palette,
                              languageProvider: languageProvider,
                              user: currentUser,
                              profileDisplayName: _profileDisplayName,
                              imageUrl: _profileImageUrl,
                              alertsHandled: _alertsHandled,
                              zonesMonitored: _zonesMonitored,
                              reportsGenerated: _reportsGenerated,
                              daysActive: _daysActive,
                              onEditProfile: _openProfileEditor,
                              onPickAvatar: _openAvatarPicker,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 47,
                            child: _SettingsColumn(
                              palette: palette,
                              languageProvider: languageProvider,
                              onOpenPanel: _openSettingsPanel,
                              onProfileChanged: _loadProfileDisplayName,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 29,
                            child: _RightColumn(
                              palette: palette,
                              activities: _recentActivities,
                              onViewAll: _openRecentActivity,
                            ),
                          ),
                        ],
                      )
                    else if (isTablet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _ProfileCard(
                                  palette: palette,
                                  languageProvider: languageProvider,
                                  user: currentUser,
                                  profileDisplayName: _profileDisplayName,
                                  imageUrl: _profileImageUrl,
                                  alertsHandled: _alertsHandled,
                                  zonesMonitored: _zonesMonitored,
                                  reportsGenerated: _reportsGenerated,
                                  daysActive: _daysActive,
                                  onEditProfile: _openProfileEditor,
                                  onPickAvatar: _openAvatarPicker,
                                ),
                                const SizedBox(height: 18),
                                _RightColumn(
                                  palette: palette,
                                  activities: _recentActivities,
                                  onViewAll: _openRecentActivity,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _SettingsColumn(
                              palette: palette,
                              languageProvider: languageProvider,
                              onOpenPanel: _openSettingsPanel,
                              onProfileChanged: _loadProfileDisplayName,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _ProfileCard(
                            palette: palette,
                            languageProvider: languageProvider,
                            user: currentUser,
                            profileDisplayName: _profileDisplayName,
                            imageUrl: _profileImageUrl,
                            alertsHandled: _alertsHandled,
                            zonesMonitored: _zonesMonitored,
                            reportsGenerated: _reportsGenerated,
                            daysActive: _daysActive,
                            onEditProfile: _openProfileEditor,
                            onPickAvatar: _openAvatarPicker,
                          ),
                          const SizedBox(height: 18),
                          _SettingsColumn(
                            palette: palette,
                            languageProvider: languageProvider,
                            onOpenPanel: _openSettingsPanel,
                            onProfileChanged: _loadProfileDisplayName,
                          ),
                          const SizedBox(height: 18),
                          _RightColumn(
                            palette: palette,
                            activities: _recentActivities,
                            onViewAll: _openRecentActivity,
                          ),
                        ],
                      ),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        '© 2025 SMF Security Monitoring. All rights reserved.',
                        style: TextStyle(
                          color: palette.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final _ProfilePalette palette;
  final LanguageProvider languageProvider;
  final ThemeProvider themeProvider;
  final VoidCallback onNotificationsTap;
  final int notificationCount;

  const _HeaderBar({
    required this.palette,
    required this.languageProvider,
    required this.themeProvider,
    required this.onNotificationsTap,
    required this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 900;

    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 58 : 74,
          height: compact ? 58 : 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _ProfileColors.cyan
                    .withValues(alpha: palette.isDark ? 0.30 : 0.18),
                blurRadius: 24,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_smf_clear.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SMF',
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                languageProvider.getText('smfProjectName'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          brand,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: brand),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final _ProfilePalette palette;
  final LanguageProvider languageProvider;
  final User user;
  final String? profileDisplayName;
  final String? imageUrl;
  final int alertsHandled;
  final int zonesMonitored;
  final int reportsGenerated;
  final int daysActive;
  final VoidCallback onEditProfile;
  final VoidCallback onPickAvatar;

  const _ProfileCard({
    required this.palette,
    required this.languageProvider,
    required this.user,
    required this.profileDisplayName,
    required this.imageUrl,
    required this.alertsHandled,
    required this.zonesMonitored,
    required this.reportsGenerated,
    required this.daysActive,
    required this.onEditProfile,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final savedName = profileDisplayName?.trim();
    final displayName = savedName != null && savedName.isNotEmpty
        ? savedName
        : _profileDisplayName(user, languageProvider);
    final roleLabel = _localizedProfileRole(user, languageProvider);
    final idLabel = _profileId(user);

    return _GlowCard(
      palette: palette,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              gradient: RadialGradient(
                center: const Alignment(0, -0.18),
                radius: 1.10,
                colors: [
                  _ProfileColors.blue.withValues(alpha: palette.isDark ? 0.26 : 0.11),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                _AvatarPicker(
                  palette: palette,
                  imageUrl: imageUrl,
                  onTap: onPickAvatar,
                ),
                const SizedBox(height: 18),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: _ProfileColors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: palette.pillBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _ProfileColors.blue.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    idLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(languageProvider.getText('editProfile')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ProfileColors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    minimumSize: const Size(170, 48),
                    side: BorderSide(
                      color: _ProfileColors.blue.withValues(alpha: 0.58),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              children: [
                _StatsGrid(
                  palette: palette,
                  alertsHandled: alertsHandled,
                  zonesMonitored: zonesMonitored,
                  reportsGenerated: reportsGenerated,
                  daysActive: daysActive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _profileDisplayName(User user, LanguageProvider lang) {
  final name = user.name.trim();
  if (name.isNotEmpty) return name;
  final email = user.email.trim();
  if (email.isNotEmpty) return email.split('@').first;
  return _profileRole(user) == 'ADMIN'
      ? lang.getText('roleAdmin')
      : lang.getText('user');
}

String _profileRole(User user) {
  final roles = user.roles
      .where((role) => role.trim().isNotEmpty)
      .map((role) => role.replaceFirst(RegExp(r'^ROLE_'), ''))
      .toList();
  if (roles.any((role) => role.toUpperCase() == 'ADMIN')) return 'ADMIN';
  final role = (user.role ?? '').trim().replaceFirst(RegExp(r'^ROLE_'), '');
  return role.isEmpty ? 'System User' : role.toUpperCase();
}

String _localizedProfileRole(User user, LanguageProvider lang) {
  switch (_profileRole(user).toUpperCase()) {
    case 'ADMIN':
      return lang.getText('roleAdmin');
    case 'ENGINEER':
      return lang.getText('roleEngineer');
    case 'MANAGER':
      return lang.getText('roleManager');
    case 'WORKER':
      return lang.getText('roleWorker');
    case 'USER':
    case 'ROLE_USER':
      return lang.getText('roleUser');
    default:
      return lang.getText('user');
  }
}

String _profileId(User user) {
  final email = user.email.trim();
  if (email.isNotEmpty) return email;
  if (user.id.trim().isNotEmpty) return 'Account linked';
  return 'Session user';
}

class _SettingsColumn extends StatelessWidget {
  final _ProfilePalette palette;
  final LanguageProvider languageProvider;
  final ValueChanged<_ProfilePanel> onOpenPanel;
  final VoidCallback onProfileChanged;

  const _SettingsColumn({
    required this.palette,
    required this.languageProvider,
    required this.onOpenPanel,
    required this.onProfileChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsOptionCard(
          palette: palette,
          icon: Icons.person_outline_rounded,
          title: languageProvider.getText('personalInfo'),
          subtitle: languageProvider.getText('personalInfoDesc'),
          color: _ProfileColors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
          ).then((_) => onProfileChanged()),
        ),
        const SizedBox(height: 14),
        _SettingsOptionCard(
          palette: palette,
          icon: Icons.work_outline_rounded,
          title: languageProvider.getText('workInfo'),
          subtitle: languageProvider.getText('workInfoDesc'),
          color: _ProfileColors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkInfoPage()),
          ),
        ),
        const SizedBox(height: 14),
        _SettingsOptionCard(
          palette: palette,
          icon: Icons.notifications_outlined,
          title: languageProvider.getText('notificationSettings'),
          subtitle: languageProvider.getText('notificationSettingsDesc'),
          color: _ProfileColors.yellow,
          onTap: () => onOpenPanel(_ProfilePanel.notifications),
        ),
        const SizedBox(height: 14),
        _SettingsOptionCard(
          palette: palette,
          icon: Icons.logout_rounded,
          title: languageProvider.getText('logout'),
          subtitle: languageProvider.getText('logoutDesc'),
          color: _ProfileColors.red,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const LogoutDialog(),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsOptionCard extends StatefulWidget {
  final _ProfilePalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _SettingsOptionCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  State<_SettingsOptionCard> createState() => _SettingsOptionCardState();
}

class _SettingsOptionCardState extends State<_SettingsOptionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 180),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 104),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  widget.color.withValues(alpha: _hovered ? 0.17 : 0.08),
                  palette.cardFill,
                ],
              ),
              border: Border.all(
                color: widget.color.withValues(alpha: _hovered ? 0.42 : 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _hovered ? 0.24 : 0.09),
                  blurRadius: _hovered ? 28 : 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 4,
                  height: _hovered ? 72 : 60,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.72),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                _GlowIcon(
                  palette: palette,
                  icon: widget.icon,
                  color: widget.color,
                  size: 64,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: palette.secondaryText,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.only(right: _hovered ? 18 : 24),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: widget.color,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  final _ProfilePalette palette;
  final List<_Activity> activities;
  final VoidCallback onViewAll;

  const _RightColumn({
    required this.palette,
    required this.activities,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AccountStatusCard(palette: palette),
        const SizedBox(height: 16),
        _RecentActivityCard(
          palette: palette,
          activities: activities,
          onViewAll: onViewAll,
        ),
      ],
    );
  }
}

class _AccountStatusCard extends StatelessWidget {
  final _ProfilePalette palette;

  const _AccountStatusCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return _GlowCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageProvider.getText('accountStatus'),
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _StatusPill(
            palette: palette,
            label: languageProvider.getText('active'),
            value: languageProvider.getText('verified'),
            icon: Icons.verified_user_rounded,
            color: _ProfileColors.green,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            palette: palette,
            icon: Icons.access_time_rounded,
            label: languageProvider.getText('lastLogin'),
            value: _localizedProfileDateTime(languageProvider, DateTime.now()),
            color: _ProfileColors.purple,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            palette: palette,
            icon: Icons.calendar_month_rounded,
            label: languageProvider.getText('memberSince'),
            value: _localizedProfileDate(
              languageProvider,
              DateTime(2025, 1, 12),
            ),
            color: _ProfileColors.purple,
          ),
        ],
      ),
    );
  }
}

String _localizedProfileDateTime(LanguageProvider lang, DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_localizedWeekday(lang, local.weekday)}, ${_localizedProfileDate(lang, local)} $hour:$minute';
}

String _localizedProfileDate(LanguageProvider lang, DateTime value) {
  final local = value.toLocal();
  if (lang.isArabic) {
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

String _localizedWeekday(LanguageProvider lang, int weekday) {
  if (lang.isArabic) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[weekday - 1];
  }
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return days[weekday - 1];
}

class _RecentActivityCard extends StatelessWidget {
  final _ProfilePalette palette;
  final List<_Activity> activities;
  final VoidCallback onViewAll;

  const _RecentActivityCard({
    required this.palette,
    required this.activities,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
      final languageProvider = context.watch<LanguageProvider>();
    return _GlowCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  languageProvider.getText('recentActivity'),
                  style: TextStyle(
                    color: palette.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  languageProvider.getText('viewAll'),
                  style: const TextStyle(
                    color: _ProfileColors.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (activities.isEmpty)
            _EmptyActivityState(palette: palette)
          else
            for (var i = 0; i < activities.length; i++)
              _TimelineItem(
                palette: palette,
                activity: activities[i],
                isLast: i == activities.length - 1,
              ),
        ],
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  final _ProfilePalette palette;

  const _EmptyActivityState({required this.palette});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.innerFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Text(
        languageProvider.getText('noRecentActivity'),
        style: TextStyle(
          color: palette.mutedText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TitleArea extends StatelessWidget {
  final _ProfilePalette palette;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _TitleArea({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          palette: palette,
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: palette.secondaryText,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassShell extends StatelessWidget {
  final _ProfilePalette palette;
  final Widget child;
  final double padding;

  const _GlassShell({
    required this.palette,
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: palette.shellFill,
        border: Border.all(color: palette.shellBorder),
        boxShadow: [
          BoxShadow(
            color:
                _ProfileColors.blue.withValues(alpha: palette.isDark ? 0.12 : 0.10),
            blurRadius: 38,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.26 : 0.07),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlowCard extends StatelessWidget {
  final _ProfilePalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlowCard({
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color:
                _ProfileColors.cyan.withValues(alpha: palette.isDark ? 0.08 : 0.05),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.14 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CircleButton extends StatelessWidget {
  final _ProfilePalette palette;
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleButton({
    required this.palette,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.controlFill,
          border: Border.all(color: palette.controlBorder),
          boxShadow: [
            BoxShadow(
              color:
                  _ProfileColors.blue.withValues(alpha: palette.isDark ? 0.12 : 0.08),
              blurRadius: 20,
            ),
          ],
        ),
        child: Icon(icon, color: palette.primaryText, size: 27),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final _ProfilePalette palette;
  final String? imageUrl;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.palette,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedImage = imageUrl?.trim();

    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.isDark
                      ? const [Color(0xFF243B64), Color(0xFF6F86B7)]
                      : const [Color(0xFFE9F4FF), Color(0xFFC8DCFF)],
                ),
                border: Border.all(color: _ProfileColors.blue, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _ProfileColors.cyan
                        .withValues(alpha: palette.isDark ? 0.42 : 0.18),
                    blurRadius: 28,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: normalizedImage != null && normalizedImage.isNotEmpty
                  ? _AvatarImage(
                      imageUrl: normalizedImage,
                      palette: palette,
                    )
                  : _AvatarFallback(palette: palette),
            ),
            Positioned(
              right: 3,
              bottom: 10,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_ProfileColors.cyan, _ProfileColors.blue],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                  boxShadow: [
                    BoxShadow(
                      color: _ProfileColors.cyan.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final String imageUrl;
  final _ProfilePalette palette;

  const _AvatarImage({
    required this.imageUrl,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final memoryImage = _decodeDataImage(imageUrl);
    if (memoryImage != null) {
      return Image.memory(
        memoryImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _AvatarFallback(palette: palette),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _AvatarFallback(palette: palette),
    );
  }
}

Uint8List? _decodeDataImage(String value) {
  final commaIndex = value.indexOf(',');
  if (!value.startsWith('data:image/') || commaIndex == -1) return null;

  try {
    return base64Decode(value.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

class _AvatarFallback extends StatelessWidget {
  final _ProfilePalette palette;

  const _AvatarFallback({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      color: palette.isDark
          ? Colors.white.withValues(alpha: 0.80)
          : const Color(0xFF4E6B9D),
      size: 96,
    );
  }
}

enum _ProfilePanel { notifications }

class _AvatarSheet extends StatelessWidget {
  final _ProfilePalette palette;
  final TextEditingController controller;
  final String? currentImageUrl;

  const _AvatarSheet({
    required this.palette,
    required this.controller,
    required this.currentImageUrl,
  });

  static const _presetImages = [
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=240&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=240&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=240&q=80',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=240&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: _BottomSheetShell(
        palette: palette,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              palette: palette,
              icon: Icons.camera_alt_rounded,
              title: 'Profile Photo',
              subtitle: 'Choose a photo URL or use one of the quick avatars.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              style: TextStyle(color: palette.primaryText),
              decoration: InputDecoration(
                labelText: 'Photo URL',
                hintText: 'https://example.com/photo.jpg',
                labelStyle: TextStyle(color: palette.secondaryText),
                hintStyle: TextStyle(color: palette.mutedText),
                prefixIcon: const Icon(Icons.link_rounded),
                filled: true,
                fillColor: palette.innerFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: palette.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final image in _presetImages)
                  InkWell(
                    onTap: () => Navigator.pop(context, image),
                    borderRadius: BorderRadius.circular(999),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(image),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final imageDataUrl = await pickProfileImageDataUrl();
                  if (context.mounted && imageDataUrl != null) {
                    Navigator.pop(context, imageDataUrl);
                  }
                },
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Choose from device'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, ''),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete Photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: _ProfileColors.red,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, controller.text),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Use Photo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCenterSheet extends StatelessWidget {
  final _ProfilePalette palette;
  final List<_ProfileNotification> notifications;
  final Set<int> readIndexes;
  final VoidCallback onMarkAllRead;
  final ValueChanged<int> onOpenNotification;

  const _NotificationCenterSheet({
    required this.palette,
    required this.notifications,
    required this.readIndexes,
    required this.onMarkAllRead,
    required this.onOpenNotification,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = (notifications.length - readIndexes.length)
        .clamp(0, notifications.length);

    return DraggableScrollableSheet(
      initialChildSize: 0.56,
      minChildSize: 0.32,
      maxChildSize: 0.86,
      builder: (context, scrollController) {
        return _BottomSheetShell(
          palette: palette,
          margin: const EdgeInsets.all(14),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.mutedText.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    _GlowIcon(
                      palette: palette,
                      icon: Icons.notifications_active_rounded,
                      color: _ProfileColors.blue,
                      size: 48,
                      iconSize: 25,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              color: palette.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '$unreadCount unread operational updates',
                            style: TextStyle(color: palette.mutedText),
                          ),
                        ],
                      ),
                    ),
                    if (notifications.isNotEmpty)
                      TextButton(
                        onPressed: onMarkAllRead,
                        child: const Text('Mark all read'),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: palette.innerFill,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 42,
                                  color: palette.mutedText,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    color: palette.primaryText,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Critical updates will appear here when available.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.mutedText,
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
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          final read = readIndexes.contains(index);

                          return InkWell(
                            onTap: () {
                              onOpenNotification(index);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: read
                                    ? palette.innerFill
                                    : item.color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: read
                                      ? palette.cardBorder
                                      : item.color.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _GlowIcon(
                                    palette: palette,
                                    icon: item.icon,
                                    color: item.color,
                                    size: 42,
                                    iconSize: 21,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            color: palette.primaryText,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.subtitle,
                                          style: TextStyle(
                                            color: palette.secondaryText,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.time,
                                          style: TextStyle(
                                            color: palette.mutedText,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!read)
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: item.color,
                                        shape: BoxShape.circle,
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
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  final _ProfilePalette palette;
  final Map<String, bool> settings;
  final void Function(String key, bool value) onChanged;

  const _NotificationSettingsSheet({
    required this.palette,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  late final Map<String, bool> _settings = Map.of(widget.settings);

  void _setValue(String key, bool value) {
    setState(() => _settings[key] = value);
    widget.onChanged(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      palette: widget.palette,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            palette: widget.palette,
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            subtitle: 'Choose which alerts you want to receive.',
          ),
          const SizedBox(height: 14),
          _SettingSwitchTile(
            palette: widget.palette,
            icon: Icons.warning_amber_rounded,
            color: _ProfileColors.yellow,
            title: 'Critical alerts',
            subtitle: 'Security incidents and emergency events.',
            value: _settings['critical'] ?? true,
            onChanged: (value) => _setValue('critical', value),
          ),
          _SettingSwitchTile(
            palette: widget.palette,
            icon: Icons.description_outlined,
            color: _ProfileColors.yellow,
            title: 'Reports',
            subtitle: 'Daily summaries and generated documents.',
            value: _settings['reports'] ?? true,
            onChanged: (value) => _setValue('reports', value),
          ),
          _SettingSwitchTile(
            palette: widget.palette,
            icon: Icons.campaign_outlined,
            color: _ProfileColors.yellow,
            title: 'Announcements',
            subtitle: 'Product updates and facility messages.',
            value: _settings['announcements'] ?? false,
            onChanged: (value) => _setValue('announcements', value),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySheet extends StatelessWidget {
  final _ProfilePalette palette;
  final List<_Activity> activities;

  const _RecentActivitySheet({
    required this.palette,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.34,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return _BottomSheetShell(
          palette: palette,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.mutedText.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
                child: Row(
                  children: [
                    _GlowIcon(
                      palette: palette,
                      icon: Icons.history_rounded,
                      color: _ProfileColors.blue,
                      size: 48,
                      iconSize: 25,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              color: palette.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${activities.length} account events',
                            style: TextStyle(color: palette.mutedText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: activities.isEmpty
                    ? ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                        children: [_EmptyActivityState(palette: palette)],
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                        itemCount: activities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: palette.innerFill,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: Row(
                              children: [
                                _GlowIcon(
                                  palette: palette,
                                  icon: activity.icon,
                                  color: activity.color,
                                  size: 44,
                                  iconSize: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.title,
                                        style: TextStyle(
                                          color: palette.primaryText,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        activity.time,
                                        style: TextStyle(
                                          color: palette.mutedText,
                                        ),
                                      ),
                                    ],
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
      },
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  final _ProfilePalette palette;
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const _BottomSheetShell({
    required this.palette,
    required this.child,
    this.margin = const EdgeInsets.all(14),
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: palette.cardFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: palette.isDark ? 0.35 : 0.12),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final _ProfilePalette palette;
  final IconData icon;
  final String title;
  final String subtitle;

  const _SheetHeader({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlowIcon(
          palette: palette,
          icon: icon,
          color: _ProfileColors.blue,
          size: 52,
          iconSize: 25,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: palette.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: palette.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final _ProfilePalette palette;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.palette,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.innerFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        children: [
          _GlowIcon(
            palette: palette,
            icon: icon,
            color: color,
            size: 42,
            iconSize: 21,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: palette.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _ProfilePalette palette;
  final int alertsHandled;
  final int zonesMonitored;
  final int reportsGenerated;
  final int daysActive;

  const _StatsGrid({
    required this.palette,
    required this.alertsHandled,
    required this.zonesMonitored,
    required this.reportsGenerated,
    required this.daysActive,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        final children = [
          _StatCard(
            palette: palette,
            icon: Icons.notifications_active_rounded,
            label: languageProvider.getText('alertsHandled'),
            value: '$alertsHandled',
            change: languageProvider.getText('live'),
            color: _ProfileColors.cyan,
          ),
          _StatCard(
            palette: palette,
            icon: Icons.location_on_rounded,
            label: languageProvider.getText('zonesMonitored'),
            value: '$zonesMonitored',
            change: languageProvider.getText('live'),
            color: _ProfileColors.blue,
          ),
          _StatCard(
            palette: palette,
            icon: Icons.description_rounded,
            label: languageProvider.getText('reportsGenerated'),
            value: '$reportsGenerated',
            change: languageProvider.getText('available'),
            color: _ProfileColors.purple,
          ),
          _StatCard(
            palette: palette,
            icon: Icons.calendar_month_rounded,
            label: languageProvider.getText('daysActive'),
            value: '$daysActive',
            change: languageProvider.getText('tracked'),
            color: _ProfileColors.yellow,
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return GridView.count(
          crossAxisCount: constraints.maxWidth < 520 ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth < 520 ? 3.2 : 2.65,
          children: children,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _ProfilePalette palette;
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final Color color;

  const _StatCard({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: palette.innerFill,
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          _GlowIcon(
            palette: palette,
            icon: icon,
            color: color,
            size: 42,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        change,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ProfileColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
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

class _StatusPill extends StatelessWidget {
  final _ProfilePalette palette;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusPill({
    required this.palette,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          _GlowIcon(
            palette: palette,
            icon: icon,
            color: color,
            size: 48,
            iconSize: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: palette.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: palette.primaryText,
                    fontWeight: FontWeight.w900,
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

class _GlowIcon extends StatelessWidget {
  final _ProfilePalette palette;
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const _GlowIcon({
    required this.palette,
    required this.icon,
    required this.color,
    required this.size,
    this.iconSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: palette.isDark ? 0.38 : 0.16),
            color.withValues(alpha: palette.isDark ? 0.12 : 0.08),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: palette.isDark ? 0.26 : 0.12),
            blurRadius: 20,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final _ProfilePalette palette;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: palette.primaryText),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final _ProfilePalette palette;
  final _Activity activity;
  final bool isLast;

  const _TimelineItem({
    required this.palette,
    required this.activity,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    color: activity.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activity.color.withValues(alpha: 0.65),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _ProfileColors.cyan
                          .withValues(alpha: palette.isDark ? 0.26 : 0.20),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: _GlowIcon(
              palette: palette,
              icon: activity.icon,
              color: activity.color,
              size: 42,
              iconSize: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 10, bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      color: palette.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    activity.time,
                    style: TextStyle(color: palette.mutedText),
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

class _Activity {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const _Activity(this.title, this.time, this.icon, this.color);
}

class _ProfileNotification {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _ProfileNotification({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class _ProfilePalette {
  final bool isDark;

  const _ProfilePalette(this.isDark);

  Color get background =>
      isDark ? const Color(0xFF020B1F) : const Color(0xFFF5FAFF);

  List<Color> get backgroundGradient => isDark
      ? const [
          Color(0xFF061126),
          Color(0xFF020A1E),
          Color(0xFF061A35),
        ]
      : const [
          Color(0xFFF9FDFF),
          Color(0xFFEAF5FF),
          Color(0xFFF7FBFF),
        ];

  Color get shellFill => isDark
      ? const Color(0xFF031532).withValues(alpha: 0.74)
      : Colors.white.withValues(alpha: 0.62);

  Color get shellBorder => isDark
      ? _ProfileColors.blue.withValues(alpha: 0.18)
      : _ProfileColors.blue.withValues(alpha: 0.20);

  Color get cardFill => isDark
      ? const Color(0xFF061936).withValues(alpha: 0.72)
      : Colors.white.withValues(alpha: 0.72);

  Color get innerFill => isDark
      ? const Color(0xFF061831).withValues(alpha: 0.78)
      : const Color(0xFFF4F9FF).withValues(alpha: 0.84);

  Color get cardBorder => isDark
      ? _ProfileColors.blue.withValues(alpha: 0.20)
      : _ProfileColors.blue.withValues(alpha: 0.17);

  Color get controlFill => isDark
      ? const Color(0xFF071B3C).withValues(alpha: 0.72)
      : Colors.white.withValues(alpha: 0.64);

  Color get controlBorder => isDark
      ? _ProfileColors.blue.withValues(alpha: 0.22)
      : _ProfileColors.blue.withValues(alpha: 0.20);

  Color get pillBackground => isDark
      ? Colors.white.withValues(alpha: 0.05)
      : const Color(0xFFEAF4FF).withValues(alpha: 0.80);

  Color get primaryText => isDark ? Colors.white : const Color(0xFF061B44);

  Color get secondaryText =>
      isDark ? const Color(0xFFB7C7E6) : const Color(0xFF365174);

  Color get mutedText =>
      isDark ? const Color(0xFF8DA4CC) : const Color(0xFF5D759A);
}

class _ProfileColors {
  static const blue = Color(0xFF1677FF);
  static const cyan = Color(0xFF00D7FF);
  static const green = Color(0xFF18C987);
  static const purple = Color(0xFF8B5CF6);
  static const yellow = Color(0xFFFFB21A);
  static const pink = Color(0xFFFF3F91);
  static const red = Color(0xFFFF3B6B);
}
