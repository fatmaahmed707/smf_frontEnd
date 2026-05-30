import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/role_summary.dart';
import '../../models/zone_summary.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../services/roles_service.dart';
import '../../services/zones_service.dart';

String _localizedZoneRoleName(String value, LanguageProvider lang) {
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

class ZonesManagementPage extends StatefulWidget {
  const ZonesManagementPage({super.key});

  @override
  State<ZonesManagementPage> createState() => _ZonesManagementPageState();
}

class _ZonesManagementPageState extends State<ZonesManagementPage> {
  final ZonesService _zonesService = ZonesService();
  final RolesService _rolesService = RolesService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ZoneSummary> _zones = const [];
  List<RoleSummary> _roles = const [];
  final Map<String, Set<int>> _sessionAssignedRoleIds = {};

  String _localizedZoneName(String value, LanguageProvider lang) {
    final lower = value.toLowerCase();
    if (lower.contains('zone a')) return lang.getText('zoneAEngineeringOnly');
    if (lower.contains('zone b')) return lang.getText('zoneBEngineeringManager');
    if (lower.contains('zone c')) return lang.getText('zoneCOpenAccess');
    return value;
  }

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    final lang = context.read<LanguageProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _zonesService.getZones(),
        _rolesService.getRoles(),
      ]);
      final zoneSummaries = results[0] as List<ZoneSummary>;
      final zones = await Future.wait(
        zoneSummaries.map((zone) async {
          try {
            return await _zonesService.getZone(zone.id);
          } catch (_) {
            return zone;
          }
        }),
      );
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _roles = results[1] as List<RoleSummary>;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = lang.getText('failedToLoadZones');
        _isLoading = false;
      });
    }
  }

  Future<void> _editZone(ZoneSummary zone) async {
    final lang = context.read<LanguageProvider>();
    final name = await _showZoneNameDialog(
      context,
      title: lang.getText('edit'),
      initialValue: zone.name,
    );
    if (name == null) return;
    await _runMutation(() => _zonesService.updateZone(id: zone.id, name: name));
  }

  Future<void> _deleteZone(ZoneSummary zone) async {
    final lang = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(lang.getText('deleteZoneQuestion')),
            content: Text(
              lang.getText('willDeleteItem').replaceAll(
                    '{name}',
                    _localizedZoneName(zone.name, lang),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(lang.getText('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(lang.getText('delete')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await _runMutation(() => _zonesService.deleteZone(zone.id));
  }

  Future<void> _assignRole(ZoneSummary zone) async {
    final lang = context.read<LanguageProvider>();
    final selectedRoles = await _pickRoles(
      context,
      roles: _roles,
      title: lang.getText('assignRole'),
      selectedRoleIds: _assignedRoleIds(zone),
    );
    if (selectedRoles == null || selectedRoles.isEmpty) return;
    try {
      for (final role in selectedRoles) {
        await _zonesService.assignRoleToZone(
          zoneId: zone.id,
          roleId: role.id,
        );
      }
      if (!mounted) return;
      setState(() {
        final assigned = _sessionAssignedRoleIds.putIfAbsent(
          zone.id,
          () => <int>{},
        );
        assigned.addAll(selectedRoles.map((role) => role.id));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('zoneSaved'))),
      );
      await _loadZones();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _removeRole(ZoneSummary zone) async {
    final lang = context.read<LanguageProvider>();
    final role = await _pickRole(
      context,
      roles: _roles,
      title: lang.getText('removeRole'),
    );
    if (role == null) return;
    try {
      await _zonesService.removeRoleFromZone(zoneId: zone.id, roleId: role.id);
      if (!mounted) return;
      setState(() {
        _sessionAssignedRoleIds[zone.id]?.remove(role.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('zoneSaved'))),
      );
      await _loadZones();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _runMutation(Future<dynamic> Function() task) async {
    try {
      await task();
      if (!mounted) return;
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('zoneSaved'))),
      );
      await _loadZones();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF020B1F) : const Color(0xFFF6FAFF);
    final bgEnd = isDark ? const Color(0xFF03142D) : const Color(0xFFEEF6FF);
    final card = isDark
        ? const Color.fromRGBO(5, 18, 45, 0.72)
        : const Color.fromRGBO(255, 255, 255, 0.86);
    final border = isDark
        ? const Color.fromRGBO(56, 189, 248, 0.22)
        : const Color.fromRGBO(59, 130, 246, 0.16);
    final text = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF061B5B);
    final muted = isDark ? const Color(0xFF9DB2D8) : const Color(0xFF6678A5);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg, bgEnd],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1100 ? 2 : 1;
          final cardHeight = width < 520
              ? 390.0
              : width < 760
                  ? 340.0
                  : 285.0;

          return GridView.builder(
            padding: EdgeInsets.all(width < 560 ? 14 : 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: cardHeight,
            ),
            itemCount: _isLoading || _errorMessage != null || _zones.isEmpty
                ? 2
                : _zones.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFBBF24)
                                  .withValues(alpha: 0.14),
                            ),
                            child: const Icon(
                              Icons.location_city_outlined,
                              color: Color(0xFFFBBF24),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              lang.getText('zones'),
                              style: TextStyle(
                                color: text,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang.getText('zonesSubtitle'),
                        style: TextStyle(color: muted, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loadZones,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(lang.getText('refresh')),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_errorMessage != null || _zones.isEmpty) {
                return _StateCard(
                  message: _errorMessage ?? lang.getText('noMonitoredZones'),
                  text: text,
                  muted: muted,
                  onRetry: _loadZones,
                );
              }

              final zone = _zones[index - 1];
              final severity = _severityFromZone(zone);
              final accent = severity == 'High'
                  ? const Color(0xFFEF4444)
                  : severity == 'Medium'
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF38BDF8);
              final assignedRoleNames = _assignedRoleNames(zone, lang);

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
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
                            color: accent.withValues(alpha: 0.14),
                          ),
                          child: Icon(Icons.place_outlined, color: accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _localizedZoneName(zone.name, lang),
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      lang.getText('monitoredAccessArea'),
                      style: TextStyle(color: muted, height: 1.45),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: assignedRoleNames.isEmpty
                          ? [
                              _RoleAccessChip(
                                label: lang.getText('noAssignedRoles'),
                                color: muted,
                              ),
                            ]
                          : assignedRoleNames
                              .map(
                                (roleName) => _RoleAccessChip(
                                  label: roleName,
                                  color: accent,
                                ),
                              )
                              .toList(),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _editZone(zone),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(lang.getText('edit')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _assignRole(zone),
                          icon: const Icon(Icons.group_add_outlined, size: 18),
                          label: Text(lang.getText('assignRole')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _removeRole(zone),
                          icon:
                              const Icon(Icons.group_remove_outlined, size: 18),
                          label: Text(lang.getText('removeRole')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _deleteZone(zone),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          label: Text(lang.getText('delete')),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _severityFromZone(ZoneSummary zone) {
    final status = zone.status?.toLowerCase();
    if (status == 'emergency' || status == 'high') return 'High';
    if (status == 'warning' || status == 'medium') return 'Medium';
    return 'Low';
  }

  Set<int> _assignedRoleIds(ZoneSummary zone) {
    final ids = <int>{
      ...zone.roleIds,
      ...?_sessionAssignedRoleIds[zone.id],
    };
    final normalizedNames = zone.roleNames.map(_normalizeRoleName).toSet();
    for (final role in _roles) {
      if (normalizedNames.contains(_normalizeRoleName(role.roleName))) {
        ids.add(role.id);
      }
    }
    return ids;
  }

  List<String> _assignedRoleNames(ZoneSummary zone, LanguageProvider lang) {
    final names = <String>[];
    final roleIds = _assignedRoleIds(zone);
    for (final role in _roles) {
      if (roleIds.contains(role.id)) {
        names.add(_localizedZoneRoleName(role.roleName, lang));
      }
    }
    for (final roleName in zone.roleNames) {
      final normalized = _normalizeRoleName(roleName);
      final alreadyAdded = names.any(
        (name) => _normalizeRoleName(name) == normalized,
      );
      if (!alreadyAdded) {
        names.add(_localizedZoneRoleName(roleName, lang));
      }
    }
    return names;
  }
}

String _normalizeRoleName(String value) {
  return value.trim().toUpperCase().replaceFirst(RegExp(r'^ROLE_'), '');
}

class _RoleAccessChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleAccessChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String message;
  final Color text;
  final Color muted;
  final VoidCallback onRetry;

  const _StateCard({
    required this.message,
    required this.text,
    required this.muted,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, color: muted, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(lang.getText('retry')),
          ),
        ],
      ),
    );
  }
}

Future<String?> _showZoneNameDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
}) async {
  final lang = context.read<LanguageProvider>();
  final controller = TextEditingController(text: initialValue ?? '');
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: lang.getText('zones'),
            border: const OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? lang.getText('zones')
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.getText('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: Text(lang.getText('save')),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
}

Future<RoleSummary?> _pickRole(
  BuildContext context, {
  required List<RoleSummary> roles,
  required String title,
}) async {
  final lang = context.read<LanguageProvider>();
  if (roles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lang.getText('noRolesAvailable'))),
    );
    return null;
  }

  var selected = roles.first;
  return showDialog<RoleSummary>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(title),
        content: DropdownButtonFormField<RoleSummary>(
          initialValue: selected,
          decoration: InputDecoration(
            labelText: lang.getText('role'),
            border: const OutlineInputBorder(),
          ),
          items: roles
              .map(
                (role) => DropdownMenuItem<RoleSummary>(
                  value: role,
                  child: Text(_localizedZoneRoleName(role.roleName, lang)),
                ),
              )
              .toList(),
          onChanged: (role) {
            if (role != null) {
              setDialogState(() => selected = role);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.getText('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text(lang.getText('apply')),
          ),
        ],
      ),
    ),
  );
}

Future<List<RoleSummary>?> _pickRoles(
  BuildContext context, {
  required List<RoleSummary> roles,
  required String title,
  Set<int> selectedRoleIds = const {},
}) async {
  final lang = context.read<LanguageProvider>();
  if (roles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lang.getText('noRolesAvailable'))),
    );
    return null;
  }

  final existingIds = {...selectedRoleIds};
  final selectedIds = {...selectedRoleIds};

  return showDialog<List<RoleSummary>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final newlySelectedCount =
            selectedIds.where((id) => !existingIds.contains(id)).length;

        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: lang.getText('roles'),
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.expand_more_rounded),
                  ),
                  child: Text(
                    newlySelectedCount == 0
                        ? lang.getText('selectedRoles')
                        : '$newlySelectedCount ${lang.getText('roles')}',
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: roles.map((role) {
                        final isSelected = selectedIds.contains(role.id);
                        final isAlreadyAssigned = existingIds.contains(role.id);
                        return CheckboxListTile(
                          value: isSelected,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            _localizedZoneRoleName(role.roleName, lang),
                          ),
                          subtitle: isAlreadyAssigned
                              ? Text(lang.getText('assigned'))
                              : null,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedIds.add(role.id);
                              } else if (!isAlreadyAssigned) {
                                selectedIds.remove(role.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.getText('cancel')),
            ),
            FilledButton(
              onPressed: newlySelectedCount == 0
                  ? null
                  : () => Navigator.pop(
                        context,
                        roles
                            .where(
                              (role) =>
                                  selectedIds.contains(role.id) &&
                                  !existingIds.contains(role.id),
                            )
                            .toList(),
                      ),
              child: Text(lang.getText('apply')),
            ),
          ],
        );
      },
    ),
  );
}
