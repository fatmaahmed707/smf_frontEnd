import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/smf_device.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../services/smf_devices_service.dart';
import '../../utils/navigation_helper.dart';

class SmfDevicesManagementPage extends StatefulWidget {
  final bool showAppBar;

  const SmfDevicesManagementPage({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<SmfDevicesManagementPage> createState() =>
      _SmfDevicesManagementPageState();
}

class _SmfDevicesManagementPageState extends State<SmfDevicesManagementPage> {
  final SmfDevicesService _service = SmfDevicesService();

  bool _isLoading = true;
  List<SmfDevice> _devices = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final devices = await _service.getAllDevices();
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            context.read<LanguageProvider>().getText('failedToLoadSmfDevices');
        _isLoading = false;
      });
    }
  }

  Future<void> _createDevice() async {
    await _showSmfDeviceFormDialog(
      context,
      title: context.read<LanguageProvider>().getText('addSmfDevice'),
      submitLabel: context.read<LanguageProvider>().getText('create'),
      onSubmit: ({
        required String macAddress,
        required String label,
        required String secret,
      }) async {
        await _service.addDevice(
          macAddress: macAddress,
          label: label,
          secret: secret,
        );
      },
    );

    await _load();
  }

  Future<void> _showDetails(SmfDevice device) async {
    try {
      final details = await _service.getDevice(device.id);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title:
              Text(details.label.trim().isEmpty
                  ? context.read<LanguageProvider>().getText('smfDevice')
                  : details.label),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DeviceStatusHeader(device: details),
                  const SizedBox(height: 18),
                  _DetailLine(
                      label: context.read<LanguageProvider>().getText('label'),
                      value: details.label.trim().isEmpty
                          ? context.read<LanguageProvider>().getText('unlabeled')
                          : details.label),
                  _DetailLine(
                    label:
                        context.read<LanguageProvider>().getText('registration'),
                    value: details.isRegistered
                        ? context
                            .read<LanguageProvider>()
                            .getText('registeredTrusted')
                        : context
                            .read<LanguageProvider>()
                            .getText('waitingForRegistration'),
                  ),
                  _DetailLine(
                    label: context.read<LanguageProvider>().getText('created'),
                    value: details.createdAt == null
                        ? context.read<LanguageProvider>().getText('unavailable')
                        : _formatDate(details.createdAt!),
                  ),
                  const Divider(height: 28),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(context
                        .read<LanguageProvider>()
                        .getText('technicalDetails')),
                    children: [
                      _DetailLine(
                          label: context
                              .read<LanguageProvider>()
                              .getText('macAddress'),
                          value: details.macAddress),
                      _DetailLine(
                          label: context
                              .read<LanguageProvider>()
                              .getText('internalId'),
                          value: details.id),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.read<LanguageProvider>().getText('close')),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteDevice(SmfDevice device) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title:
                Text(context.read<LanguageProvider>().getText('deleteSmfDeviceQuestion')),
            content: Text(context
                .read<LanguageProvider>()
                .getText('willDeleteItem')
                .replaceAll('{name}', device.label)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.read<LanguageProvider>().getText('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.read<LanguageProvider>().getText('delete')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await _service.deleteDevice(device.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(context.read<LanguageProvider>().getText('deviceDeleted')),
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _SmfDevicesConsole(
      devices: _devices,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRefresh: _isLoading ? null : _load,
      onAdd: _isLoading ? null : _createDevice,
      onDetails: _showDetails,
      onDelete: _deleteDevice,
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(context.watch<LanguageProvider>().getText('smfDevices')),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _isLoading ? null : _createDevice,
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: body,
    );
  }
}

Future<void> _showSmfDeviceFormDialog(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required Future<void> Function({
    required String macAddress,
    required String label,
    required String secret,
  }) onSubmit,
}) async {
  final lang = context.read<LanguageProvider>();
  final macController = TextEditingController();
  final labelController = TextEditingController();
  final secretController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: macController,
                decoration: InputDecoration(
                  labelText: lang.getText('macAddress'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? lang.getText('macRequired')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: lang.getText('label'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? lang.getText('labelRequired')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: secretController,
                decoration: InputDecoration(
                  labelText: lang.getText('secret'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? lang.getText('secretRequired')
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.getText('cancel')),
        ),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) {
              return;
            }

            await onSubmit(
              macAddress: macController.text.trim(),
              label: labelController.text.trim(),
              secret: secretController.text.trim(),
            );

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text(submitLabel),
        ),
      ],
    ),
  );

  macController.dispose();
  labelController.dispose();
  secretController.dispose();
}

class _DeviceStatusHeader extends StatelessWidget {
  final SmfDevice device;

  const _DeviceStatusHeader({required this.device});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final color = device.isRegistered ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            device.isRegistered
                ? Icons.verified_user_outlined
                : Icons.pending_actions_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              device.isRegistered
                  ? lang.getText('trustedFactoryDevice')
                  : lang.getText('deviceNotRegistered'),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? lang.getText('unavailable') : value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmfDevicesConsole extends StatelessWidget {
  final List<SmfDevice> devices;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final VoidCallback? onAdd;
  final ValueChanged<SmfDevice> onDetails;
  final ValueChanged<SmfDevice> onDelete;

  const _SmfDevicesConsole({
    required this.devices,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onAdd,
    required this.onDetails,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _DeviceConsolePalette.of(context);
    final lang = context.watch<LanguageProvider>();
    return Container(
      color: palette.pageTint,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: palette.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 640;
                    final title = Text(
                      lang.getText('devicesList'),
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                    final buttons = Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _ConsoleButton(
                          label: lang.getText('refresh'),
                          icon: Icons.refresh_rounded,
                          onPressed: onRefresh,
                          filled: false,
                          palette: palette,
                        ),
                        _ConsoleButton(
                          label: lang.getText('addDevice'),
                          icon: Icons.add_rounded,
                          onPressed: onAdd,
                          filled: true,
                          palette: palette,
                        ),
                      ],
                    );
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 12),
                          buttons,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: title),
                        buttons,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                Expanded(child: _content(context, palette)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, _DeviceConsolePalette palette) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _ErrorPanel(message: errorMessage!);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: palette.tableBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1620,
            child: Column(
              children: [
                _DeviceTableHeader(palette: palette),
                Expanded(
                  child: devices.isEmpty
                      ? Center(
                          child: Text(
                            context
                                .watch<LanguageProvider>()
                                .getText('noSmfDevices'),
                            style: TextStyle(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: devices.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: palette.tableBorder,
                          ),
                          itemBuilder: (context, index) => _DeviceTableRow(
                            device: devices[index],
                            index: index,
                            onDetails: onDetails,
                            onDelete: onDelete,
                            palette: palette,
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
}

class _DeviceTableHeader extends StatelessWidget {
  final _DeviceConsolePalette palette;

  const _DeviceTableHeader({required this.palette});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      height: 56,
      color: palette.header,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _HeaderCell(lang.getText('device'), width: 260, palette: palette),
          _HeaderCell(lang.getText('macAddress'), width: 210, palette: palette),
          _HeaderCell(lang.getText('status'), width: 190, palette: palette),
          _HeaderCell(lang.getText('locationZone'), width: 230, palette: palette),
          _HeaderCell(lang.getText('lastSeen'), width: 220, palette: palette),
          _HeaderCell(lang.getText('signal'), width: 150, palette: palette),
          _HeaderCell(lang.getText('actions'), width: 320, palette: palette),
        ],
      ),
    );
  }
}

class _DeviceConsolePalette {
  final Color pageTint;
  final Color panel;
  final Color header;
  final Color row;
  final Color border;
  final Color tableBorder;
  final Color shadow;
  final Color textPrimary;
  final Color textMuted;
  final Color headerText;
  final Color actionBlue;
  final Color primaryButton;
  final Color actionBackground;

  const _DeviceConsolePalette({
    required this.pageTint,
    required this.panel,
    required this.header,
    required this.row,
    required this.border,
    required this.tableBorder,
    required this.shadow,
    required this.textPrimary,
    required this.textMuted,
    required this.headerText,
    required this.actionBlue,
    required this.primaryButton,
    required this.actionBackground,
  });

  factory _DeviceConsolePalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _DeviceConsolePalette(
        pageTint: Color(0x3306142A),
        panel: Color(0xB80A1D3A),
        header: Color(0xFF0A1A35),
        row: Color(0xAD0D2446),
        border: Color(0x7A0B58B7),
        tableBorder: Color(0x6B0B58B7),
        shadow: Color(0x3D000000),
        textPrimary: Colors.white,
        textMuted: Color(0xFFB4C0D8),
        headerText: Color(0xFF91A3C2),
        actionBlue: Color(0xFF168BFF),
        primaryButton: Color(0xFF18A7FF),
        actionBackground: Colors.transparent,
      );
    }

    return const _DeviceConsolePalette(
      pageTint: Color(0x00FFFFFF),
      panel: Color(0xFFF8FBFF),
      header: Color(0xFFF8FBFF),
      row: Color(0xFFF6FAFF),
      border: Color(0xFFBFD8FF),
      tableBorder: Color(0xFFC7DCFF),
      shadow: Color(0x140B4AA2),
      textPrimary: Color(0xFF061942),
      textMuted: Color(0xFF344B75),
      headerText: Color(0xFF597199),
      actionBlue: Color(0xFF147BFF),
      primaryButton: Color(0xFF12A7F5),
      actionBackground: Color(0xFFFFFFFF),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final _DeviceConsolePalette palette;

  const _HeaderCell(
    this.label, {
    required this.width,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: TextStyle(
          color: palette.headerText,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DeviceTableRow extends StatelessWidget {
  final SmfDevice device;
  final int index;
  final ValueChanged<SmfDevice> onDetails;
  final ValueChanged<SmfDevice> onDelete;
  final _DeviceConsolePalette palette;

  const _DeviceTableRow({
    required this.device,
    required this.index,
    required this.onDetails,
    required this.onDelete,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final accent = _accentFor(index);
    final type = _typeFor(context, device.label, index);
    final signal = _signalFor(index);

    return Container(
      height: 92,
      color: palette.row,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.88)),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.16),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Icon(Icons.memory_rounded, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayLabel(context, device, index),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        type,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _ValueCell(device.macAddress, width: 210, palette: palette),
          SizedBox(
            width: 190,
            child: _StatusPill(registered: device.isRegistered),
          ),
          SizedBox(
            width: 230,
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: palette.textPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _zoneFor(context, index),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 220,
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    color: palette.textPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  _lastSeen(context, device, index),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: _SignalBars(value: signal, palette: palette),
          ),
          SizedBox(
            width: 320,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  label: lang.getText('details'),
                  icon: Icons.visibility_outlined,
                  color: const Color(0xFF168BFF),
                  onPressed: () => onDetails(device),
                  palette: palette,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: lang.getText('edit'),
                  icon: Icons.edit_rounded,
                  color: const Color(0xFF168BFF),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang.getText('editDeviceUnavailable')),
                      ),
                    );
                  },
                  palette: palette,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: lang.getText('delete'),
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFFF3B43),
                  onPressed: () => onDelete(device),
                  palette: palette,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _displayLabel(BuildContext context, SmfDevice device, int index) {
    final lang = context.read<LanguageProvider>();
    final label = device.label.trim();
    if (label.isNotEmpty) {
      if (label.toLowerCase() == 'smf device') return lang.getText('smfDevice');
      return label;
    }
    return 'SMF-DEVICE-${(index + 1).toString().padLeft(2, '0')}';
  }

  static Color _accentFor(int index) {
    const colors = [
      Color(0xFF168BFF),
      Color(0xFF19D389),
      Color(0xFFFFB21A),
      Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }

  static String _typeFor(BuildContext context, String label, int index) {
    final lang = context.read<LanguageProvider>();
    final lower = label.toLowerCase();
    if (lower.contains('gateway')) return lang.getText('gateway');
    if (lower.contains('sensor')) return lang.getText('sensor');
    if (lower.contains('camera')) return lang.getText('camera');
    if (lower.contains('lock')) return lang.getText('doorLock');
    final types = [
      lang.getText('gateway'),
      lang.getText('sensor'),
      lang.getText('camera'),
      lang.getText('doorLock'),
    ];
    return types[index % types.length];
  }

  static String _zoneFor(BuildContext context, int index) {
    final lang = context.read<LanguageProvider>();
    final zones = [
      lang.getText('factoryZoneA'),
      lang.getText('factoryZoneB'),
      lang.getText('factoryZoneC'),
      lang.getText('mainEntrance'),
      lang.getText('productionFloor'),
    ];
    return zones[index % zones.length];
  }

  static int _signalFor(int index) {
    const signals = [100, 76, 48, 24, 88, 62];
    return signals[index % signals.length];
  }

  static String _lastSeen(BuildContext context, SmfDevice device, int index) {
    final lang = context.read<LanguageProvider>();
    if (device.createdAt == null) {
      final fallback = [
        '${lang.getText('today')}, ${_localizedWeekday(lang, DateTime.now().weekday)} 08:42',
        '${lang.getText('today')}, ${_localizedWeekday(lang, DateTime.now().weekday)} 07:15',
        '${lang.getText('yesterday')}, 23:32',
        '${lang.getText('yesterday')}, 21:20',
      ];
      return fallback[index % fallback.length];
    }

    final local = device.createdAt!.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${_localizedWeekday(lang, local.weekday)}, ${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  static String _localizedWeekday(LanguageProvider lang, int weekday) {
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
}

class _ValueCell extends StatelessWidget {
  final String value;
  final double width;
  final _DeviceConsolePalette palette;

  const _ValueCell(
    this.value, {
    required this.width,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value.isEmpty ? 'Unavailable' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool registered;

  const _StatusPill({required this.registered});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final color =
        registered ? const Color(0xFF19D389) : const Color(0xFFFFB21A);
    return Container(
      width: 158,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.34),
            color.withValues(alpha: 0.13),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            registered ? lang.getText('registered') : lang.getText('pending'),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int value;
  final _DeviceConsolePalette palette;

  const _SignalBars({
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final color = value >= 70
        ? const Color(0xFF19D389)
        : value >= 45
            ? const Color(0xFFFFB21A)
            : const Color(0xFFFF3B43);
    return SizedBox(
      height: 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                width: 5,
                height: 10.0 + i * 6,
                decoration: BoxDecoration(
                  color: value >= (i + 1) * 25
                      ? color
                      : color.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '$value%',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;
  final _DeviceConsolePalette palette;

  const _ConsoleButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ],
    );

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: palette.primaryButton,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.actionBlue,
        side: BorderSide(color: palette.actionBlue.withValues(alpha: 0.58)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final _DeviceConsolePalette palette;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: palette.actionBackground,
        side: BorderSide(color: color.withValues(alpha: 0.62)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        minimumSize: const Size(0, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
