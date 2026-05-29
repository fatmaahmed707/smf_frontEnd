import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/navigation_helper.dart';
import 'announcement_model.dart';

class AnnouncementsPage extends StatefulWidget {
  final bool embedded;

  const AnnouncementsPage({super.key, this.embedded = false});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<_AnnouncementEntry> _announcements = [
    _AnnouncementEntry(
      model: AnnouncementModel(
        title: 'Security Update Available',
        message: 'System firmware v2.4.1 is ready for deployment',
        priority: 'Medium',
        sender: 'System',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      scheduled: false,
      visual: _AnnouncementVisual.update,
    ),
    _AnnouncementEntry(
      model: AnnouncementModel(
        title: 'Worker #21 entered Zone A',
        message: 'Location updated • All systems normal',
        priority: 'Info',
        sender: 'Tracker',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      scheduled: false,
      visual: _AnnouncementVisual.worker,
    ),
    _AnnouncementEntry(
      model: AnnouncementModel(
        title: 'SOS button pressed',
        message: 'Worker #15 • Immediate attention required',
        priority: 'High',
        sender: 'Emergency',
        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
      scheduled: false,
      visual: _AnnouncementVisual.sos,
    ),
    _AnnouncementEntry(
      model: AnnouncementModel(
        title: 'Device #45 connected',
        message: 'New device synced successfully',
        priority: 'Info',
        sender: 'Devices',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      scheduled: true,
      visual: _AnnouncementVisual.device,
    ),
  ];

  _AnnouncementFilter _activeFilter = _AnnouncementFilter.all;
  _AnnouncementPriority _selectedPriority = _AnnouncementPriority.medium;
  _ScheduleMode _scheduleMode = _ScheduleMode.now;

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  List<_AnnouncementEntry> get _filteredAnnouncements {
    final query = _searchController.text.trim().toLowerCase();
    return _announcements.where((entry) {
      final matchesFilter =
          _activeFilter == _AnnouncementFilter.all ? true : entry.scheduled;
      final matchesSearch = query.isEmpty
          ? true
          : entry.model.title.toLowerCase().contains(query) ||
              entry.model.message.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  int get _scheduledCount =>
      _announcements.where((item) => item.scheduled).length;

  void _sendAnnouncement() {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    setState(() {
      _announcements.insert(
        0,
        _AnnouncementEntry(
          model: AnnouncementModel(
            title: title,
            message: message,
            priority: _selectedPriority.label,
            sender: 'Admin',
            timestamp: DateTime.now(),
          ),
          scheduled: _scheduleMode == _ScheduleMode.later,
          visual: _AnnouncementVisual.update,
        ),
      );
      _titleController.clear();
      _messageController.clear();
      _selectedPriority = _AnnouncementPriority.medium;
      _scheduleMode = _ScheduleMode.now;
      _activeFilter = _AnnouncementFilter.all;
    });
  }

  Future<void> _openAnnouncementActions(_AnnouncementEntry entry) async {
    final lang = context.read<LanguageProvider>();
    final titleController = TextEditingController(text: entry.model.title);
    final messageController = TextEditingController(text: entry.model.message);
    var priority = _priorityFromLabel(entry.model.priority);

    final action = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(lang.getText('editAnnouncement')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: lang.getText('title'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: lang.getText('message'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<_AnnouncementPriority>(
                  initialValue: priority,
                  decoration: InputDecoration(
                    labelText: lang.getText('priority'),
                    border: const OutlineInputBorder(),
                  ),
                  items: _AnnouncementPriority.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(_localizedPriority(item.label)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => priority = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, 'delete'),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(lang.getText('delete')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.getText('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: Text(lang.getText('save')),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'delete') {
      setState(() => _announcements.remove(entry));
    } else if (action == 'save') {
      final title = titleController.text.trim();
      final message = messageController.text.trim();
      if (title.isEmpty || message.isEmpty) return;
      setState(() {
        final index = _announcements.indexOf(entry);
        if (index == -1) return;
        _announcements[index] = _AnnouncementEntry(
          model: AnnouncementModel(
            title: title,
            message: message,
            priority: priority.label,
            sender: entry.model.sender,
            timestamp: entry.model.timestamp,
          ),
          scheduled: entry.scheduled,
          visual: entry.visual,
        );
      });
    }

    titleController.dispose();
    messageController.dispose();
  }

  _AnnouncementPriority _priorityFromLabel(String label) {
    return _AnnouncementPriority.values.firstWhere(
      (priority) => priority.label.toLowerCase() == label.toLowerCase(),
      orElse: () => _AnnouncementPriority.medium,
    );
  }

  String _localizedAnnouncementTitle(_AnnouncementEntry entry) {
    final lang = context.read<LanguageProvider>();
    final title = entry.model.title.toLowerCase();
    if (title.contains('security update')) {
      return lang.getText('securityUpdateAvailable');
    }
    if (title.contains('worker #21')) return lang.getText('workerEnteredZone');
    if (title.contains('sos')) return lang.getText('sosButtonPressed');
    if (title.contains('device #45')) return lang.getText('deviceConnected');
    return entry.model.title;
  }

  String _localizedAnnouncementMessage(_AnnouncementEntry entry) {
    final lang = context.read<LanguageProvider>();
    final message = entry.model.message.toLowerCase();
    if (message.contains('firmware')) return lang.getText('firmwareReady');
    if (message.contains('location updated')) {
      return lang.getText('locationUpdatedNormal');
    }
    if (message.contains('immediate attention')) {
      return lang.getText('workerAttentionRequired');
    }
    if (message.contains('new device')) return lang.getText('newDeviceSynced');
    return entry.model.message;
  }

  String _localizedPriority(String priority) {
    final lang = context.read<LanguageProvider>();
    switch (priority.toLowerCase()) {
      case 'high':
        return lang.getText('high');
      case 'medium':
        return lang.getText('medium');
      case 'low':
        return lang.getText('low');
      case 'info':
        return lang.getText('info');
      default:
        return priority;
    }
  }

  String _timeAgo(DateTime timestamp) {
    final lang = context.read<LanguageProvider>();
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return lang.getText('justNow');
    if (diff.inMinutes < 60) {
      return lang.getText('minutesAgo').replaceAll(
            '{count}',
            diff.inMinutes.toString(),
          );
    }
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final palette = themeProvider.isDarkMode
        ? const _AnnouncementsPalette.dark()
        : const _AnnouncementsPalette.light();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1180;

    final content = Container(
      decoration: widget.embedded
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.background, palette.backgroundEnd],
              ),
            ),
      child: Stack(
        children: [
          if (!widget.embedded)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OrbitalPainter(
                    primary: palette.glow,
                    secondary: palette.orbit,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.embedded ? 20 : 24,
              widget.embedded ? 14 : 18,
              widget.embedded ? 20 : 24,
              widget.embedded ? 20 : 18,
            ),
            child: Column(
              children: [
                if (!widget.embedded) ...[
                  _topBar(
                    palette: palette,
                    themeProvider: themeProvider,
                    languageProvider: languageProvider,
                  ),
                  const SizedBox(height: 24),
                ],
                Expanded(
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _leftPanel(palette, fillHeight: true),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: _rightPanel(palette),
                            ),
                          ],
                        )
                      : ListView(
                          children: [
                            _leftPanel(palette, fillHeight: false),
                            const SizedBox(height: 24),
                            _rightPanel(palette),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final page = Directionality(
      textDirection:
          languageProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: widget.embedded
          ? content
          : Scaffold(
              backgroundColor: palette.background,
              body: SafeArea(child: content),
            ),
    );

    if (widget.embedded) return page;

    return WillPopScope(
      onWillPop: () => AppNavigation.handleSystemBack(context),
      child: page,
    );
  }

  Widget _topBar({
    required _AnnouncementsPalette palette,
    required ThemeProvider themeProvider,
    required LanguageProvider languageProvider,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: () => AppNavigation.goBack(context),
          icon: Icon(
            Icons.close_rounded,
            color: palette.textMuted,
          ),
          tooltip: 'Close',
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [palette.primary, palette.accent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.glow.withValues(alpha: 0.30),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset('assets/images/logo_smf_clear.png'),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMF',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  languageProvider.getText('smfProjectName'),
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: palette.chipBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, color: palette.gold, size: 16),
              const SizedBox(width: 10),
              Text(
                languageProvider.getText('safetyPriority'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _topPill(
          palette: palette,
          onTap: languageProvider.toggleLanguage,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageProvider.isArabic ? 'AR' : 'EN',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: palette.textPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.chipBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: !themeProvider.isDarkMode
                        ? palette.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.wb_sunny_outlined,
                    color:
                        !themeProvider.isDarkMode ? Colors.white : palette.gold,
                  ),
                ),
              ),
              InkWell(
                onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? palette.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.nights_stay_rounded,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          children: [
            _topPill(
              palette: palette,
              child: Icon(
                Icons.notifications_none_rounded,
                color: palette.textPrimary,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: palette.danger,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _topPill({
    required _AnnouncementsPalette palette,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: palette.chipBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
        child: child,
      ),
    );
  }

  Widget _leftPanel(_AnnouncementsPalette palette, {required bool fillHeight}) {
    final lang = context.watch<LanguageProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.glow.withValues(alpha: 0.14),
                boxShadow: [
                  BoxShadow(
                    color: palette.glow.withValues(alpha: 0.35),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Icon(
                Icons.campaign_rounded,
                color: palette.gold,
                size: 42,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.getText('announcements'),
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.getText('announcementSubtitle'),
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final search = Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: palette.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: palette.textMuted),
                  border: InputBorder.none,
                  hintText: lang.getText('searchAnnouncements'),
                  hintStyle: TextStyle(color: palette.textMuted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            );
            final filters = Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                _filterTab(
                  label: lang.getText('allAnnouncements'),
                  count: _announcements.length,
                  active: _activeFilter == _AnnouncementFilter.all,
                  onTap: () =>
                      setState(() => _activeFilter = _AnnouncementFilter.all),
                  palette: palette,
                ),
                _filterTab(
                  label: lang.getText('scheduled'),
                  count: _scheduledCount,
                  active: _activeFilter == _AnnouncementFilter.scheduled,
                  onTap: () => setState(
                    () => _activeFilter = _AnnouncementFilter.scheduled,
                  ),
                  palette: palette,
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  filters,
                  const SizedBox(height: 12),
                  search,
                ],
              );
            }

            return Row(
              children: [
                filters,
                const SizedBox(width: 18),
                Expanded(child: search),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (fillHeight)
          Expanded(child: _announcementsListPanel(palette))
        else
          SizedBox(
            height: 520,
            child: _announcementsListPanel(palette),
          ),
      ],
    );
  }

  Widget _announcementsListPanel(_AnnouncementsPalette palette) {
    return _panel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _filteredAnnouncements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final entry = _filteredAnnouncements[index];
                final badge = _priorityStyle(entry.model.priority, palette);
                final icon = _visualStyle(entry.visual, palette);

                return InkWell(
                  onTap: () => _openAnnouncementActions(entry),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.035),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.borderSoft),
                      boxShadow: [
                        BoxShadow(
                          color: palette.glow.withValues(alpha: 0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                icon.color.withValues(alpha: 0.24),
                                icon.color.withValues(alpha: 0.08),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: icon.color.withValues(alpha: 0.35),
                                blurRadius: 22,
                              ),
                            ],
                          ),
                          child: Icon(icon.icon, color: icon.color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _localizedAnnouncementTitle(entry),
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _localizedAnnouncementMessage(entry),
                                style: TextStyle(
                                  color: palette.textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: badge.background,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _localizedPriority(entry.model.priority),
                                style: TextStyle(
                                  color: badge.foreground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _timeAgo(entry.model.timestamp),
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: palette.textMuted,
                          size: 28,
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
  }

  Widget _rightPanel(_AnnouncementsPalette palette) {
    final lang = context.watch<LanguageProvider>();
    return _panel(
      palette: palette,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.glow.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: palette.glow.withValues(alpha: 0.22),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: palette.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      lang.getText('createAnnouncement'),
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: palette.border),
              const SizedBox(height: 24),
              Text(
                lang.getText('title'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _inputField(
                controller: _titleController,
                palette: palette,
                hint: lang.getText('enterTitle'),
                maxLines: 1,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    lang.getText('message'),
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_messageController.text.length} / 400',
                    style: TextStyle(color: palette.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _inputField(
                controller: _messageController,
                palette: palette,
                hint: lang.getText('writeYourMessage'),
                maxLines: 5,
                maxLength: 400,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              Text(
                lang.getText('priority'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ClipRect(
                child: Row(
                  children: [
                    for (var index = 0;
                        index < _AnnouncementPriority.values.length;
                        index++) ...[
                      Expanded(
                        child: _priorityButton(
                          priority: _AnnouncementPriority.values[index],
                          palette: palette,
                        ),
                      ),
                      if (index != _AnnouncementPriority.values.length - 1)
                        const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                lang.getText('scheduleOptional'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_ScheduleMode>(
                    value: _scheduleMode,
                    dropdownColor: palette.panel,
                    borderRadius: BorderRadius.circular(16),
                    iconEnabledColor: palette.textMuted,
                    style: TextStyle(color: palette.textPrimary),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: _ScheduleMode.now,
                        child: Text(lang.getText('sendImmediately')),
                      ),
                      DropdownMenuItem(
                        value: _ScheduleMode.later,
                        child: Text(lang.getText('scheduleForLater')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _scheduleMode = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _sendAnnouncement,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(lang.getText('sendAnnouncement')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: palette.glow.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel({
    required _AnnouncementsPalette palette,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.10),
            blurRadius: 28,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required _AnnouncementsPalette palette,
    required String hint,
    required int maxLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: TextStyle(color: palette.textPrimary),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(color: palette.textMuted),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.accent),
        ),
      ),
    );
  }

  Widget _filterTab({
    required String label,
    required int count,
    required bool active,
    required VoidCallback onTap,
    required _AnnouncementsPalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(colors: [palette.primary, palette.accent])
              : null,
          color: active ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: active ? Colors.transparent : palette.borderSoft),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: palette.glow.withValues(alpha: 0.25),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : palette.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.16)
                    : palette.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: active ? Colors.white : palette.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priorityButton({
    required _AnnouncementPriority priority,
    required _AnnouncementsPalette palette,
  }) {
    final selected = _selectedPriority == priority;
    final color = switch (priority) {
      _AnnouncementPriority.low => const Color(0xFF60A5FA),
      _AnnouncementPriority.medium => palette.gold,
      _AnnouncementPriority.high => palette.danger,
    };

    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: () => setState(() => _selectedPriority = priority),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : palette.borderSoft,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              _localizedPriority(priority.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? color : palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _AnnouncementFilter { all, scheduled }

enum _ScheduleMode { now, later }

enum _AnnouncementPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  final String label;
  const _AnnouncementPriority(this.label);
}

enum _AnnouncementVisual { update, worker, sos, device }

class _AnnouncementEntry {
  final AnnouncementModel model;
  final bool scheduled;
  final _AnnouncementVisual visual;

  const _AnnouncementEntry({
    required this.model,
    required this.scheduled,
    required this.visual,
  });
}

class _PriorityStyle {
  final Color background;
  final Color foreground;

  const _PriorityStyle(this.background, this.foreground);
}

class _VisualStyle {
  final IconData icon;
  final Color color;

  const _VisualStyle(this.icon, this.color);
}

extension on _AnnouncementsPageState {
  _PriorityStyle _priorityStyle(
    String priority,
    _AnnouncementsPalette palette,
  ) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const _PriorityStyle(
          Color.fromRGBO(239, 68, 68, 0.18),
          Color(0xFFFF6B6B),
        );
      case 'medium':
        return const _PriorityStyle(
          Color.fromRGBO(251, 191, 36, 0.16),
          Color(0xFFFBBF24),
        );
      default:
        return _PriorityStyle(
          const Color.fromRGBO(59, 130, 246, 0.18),
          palette.accentSoft,
        );
    }
  }

  _VisualStyle _visualStyle(
    _AnnouncementVisual visual,
    _AnnouncementsPalette palette,
  ) {
    switch (visual) {
      case _AnnouncementVisual.update:
        return _VisualStyle(Icons.notifications_active_rounded, palette.accent);
      case _AnnouncementVisual.worker:
        return _VisualStyle(Icons.verified_user_rounded, palette.success);
      case _AnnouncementVisual.sos:
        return _VisualStyle(Icons.sos_rounded, palette.danger);
      case _AnnouncementVisual.device:
        return _VisualStyle(Icons.memory_rounded, palette.gold);
    }
  }
}

class _AnnouncementsPalette {
  final Color background;
  final Color backgroundEnd;
  final Color panel;
  final Color card;
  final Color border;
  final Color borderSoft;
  final Color primary;
  final Color accent;
  final Color accentSoft;
  final Color glow;
  final Color orbit;
  final Color textPrimary;
  final Color textMuted;
  final Color gold;
  final Color danger;
  final Color success;
  final Color chipBackground;

  const _AnnouncementsPalette({
    required this.background,
    required this.backgroundEnd,
    required this.panel,
    required this.card,
    required this.border,
    required this.borderSoft,
    required this.primary,
    required this.accent,
    required this.accentSoft,
    required this.glow,
    required this.orbit,
    required this.textPrimary,
    required this.textMuted,
    required this.gold,
    required this.danger,
    required this.success,
    required this.chipBackground,
  });

  const _AnnouncementsPalette.dark()
      : background = const Color(0xFF020B1F),
        backgroundEnd = const Color(0xFF03142D),
        panel = const Color.fromRGBO(5, 18, 45, 0.72),
        card = const Color.fromRGBO(8, 25, 58, 0.75),
        border = const Color.fromRGBO(56, 189, 248, 0.22),
        borderSoft = const Color.fromRGBO(56, 189, 248, 0.14),
        primary = const Color(0xFF0B63F6),
        accent = const Color(0xFF00B8FF),
        accentSoft = const Color(0xFF60A5FA),
        glow = const Color(0xFF38BDF8),
        orbit = const Color.fromRGBO(11, 99, 246, 0.18),
        textPrimary = const Color(0xFFF8FAFC),
        textMuted = const Color(0xFF9DB2D8),
        gold = const Color(0xFFFBBF24),
        danger = const Color(0xFFEF4444),
        success = const Color(0xFF22C55E),
        chipBackground = const Color.fromRGBO(255, 255, 255, 0.04);

  const _AnnouncementsPalette.light()
      : background = const Color(0xFFF7FAFF),
        backgroundEnd = const Color(0xFFEEF4FF),
        panel = const Color.fromRGBO(255, 255, 255, 0.86),
        card = const Color.fromRGBO(255, 255, 255, 0.92),
        border = const Color.fromRGBO(99, 102, 241, 0.18),
        borderSoft = const Color.fromRGBO(99, 102, 241, 0.12),
        primary = const Color(0xFF0B63F6),
        accent = const Color(0xFF7C3AED),
        accentSoft = const Color(0xFF60A5FA),
        glow = const Color(0xFF60A5FA),
        orbit = const Color.fromRGBO(124, 58, 237, 0.10),
        textPrimary = const Color(0xFF0F172A),
        textMuted = const Color(0xFF64748B),
        gold = const Color(0xFFFBBF24),
        danger = const Color(0xFFEF4444),
        success = const Color(0xFF10B981),
        chipBackground = const Color.fromRGBO(255, 255, 255, 0.78);
}

class _OrbitalPainter extends CustomPainter {
  final Color primary;
  final Color secondary;

  const _OrbitalPainter({
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final topArc = Rect.fromCircle(
      center: Offset(size.width * 0.82, size.height * 0.26),
      radius: size.width * 0.22,
    );
    paint.color = primary.withValues(alpha: 0.18);
    canvas.drawArc(topArc, 3.4, 1.9, false, paint);

    final sideArc = Rect.fromCircle(
      center: Offset(size.width * 0.92, size.height * 0.52),
      radius: size.width * 0.26,
    );
    paint.color = secondary.withValues(alpha: 0.22);
    canvas.drawArc(sideArc, 2.9, 1.8, false, paint);

    final dots = Paint()..color = primary.withValues(alpha: 0.65);
    for (final dot in [
      Offset(size.width * 0.78, size.height * 0.22),
      Offset(size.width * 0.90, size.height * 0.31),
      Offset(size.width * 0.88, size.height * 0.60),
      Offset(size.width * 0.17, size.height * 0.57),
    ]) {
      canvas.drawCircle(dot, 2, dots);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }
}
