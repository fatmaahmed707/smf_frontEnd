import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../models/role_summary.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../services/roles_service.dart';
import '../../services/users_service.dart';

String _localizedRoleDisplayName(String value, LanguageProvider lang) {
  switch (value.trim().replaceFirst(RegExp(r'^ROLE_'), '').toUpperCase()) {
    case 'ADMIN':
      return lang.getText('roleAdmin');
    case 'ENGINEER':
      return lang.getText('roleEngineer');
    case 'MANAGER':
      return lang.getText('roleManager');
    case 'WORKER':
      return lang.getText('roleWorker');
    case 'USER':
      return lang.getText('roleUser');
    default:
      return value;
  }
}

String _localizedUserRoles(User user, LanguageProvider lang) {
  final roles = user.roles.isNotEmpty
      ? user.roles
      : [
          if (user.role?.trim().isNotEmpty == true) user.role!.trim(),
        ];
  if (roles.isEmpty) return _localizedRoleDisplayName('USER', lang);
  return roles.map((role) => _localizedRoleDisplayName(role, lang)).join(', ');
}

class RolesManagementPage extends StatefulWidget {
  const RolesManagementPage({super.key});

  @override
  State<RolesManagementPage> createState() => _RolesManagementPageState();
}

class _RolesManagementPageState extends State<RolesManagementPage> {
  final UsersService _usersService = UsersService();
  final RolesService _rolesService = RolesService();

  bool _isLoading = true;
  String? _errorMessage;
  List<RoleSummary> _roles = const [];
  List<User> _users = const [];
  Map<String, int> _roleUsage = const {};

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final lang = context.read<LanguageProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _rolesService.getRoles(),
        _usersService.getUsers(),
      ]);
      final roles = results[0] as List<RoleSummary>;
      final users = results[1] as List<User>;
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _users = users;
        _roleUsage = _roleUsageFromUsers(users);
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
        _errorMessage = lang.getText('failedToLoadRoles');
        _isLoading = false;
      });
    }
  }

  Map<String, int> _roleUsageFromUsers(List<User> users) {
    final counts = <String, int>{};

    for (final user in users) {
      final roles = user.roles.isNotEmpty
          ? user.roles
          : user.role == null || user.role!.trim().isEmpty
              ? const <String>[]
              : [user.role!];
      for (final role in roles) {
        final normalized = role.trim();
        if (normalized.isEmpty) continue;
        counts[normalized] = (counts[normalized] ?? 0) + 1;
      }
    }

    return counts;
  }

  Future<void> _createRole() async {
    final lang = context.read<LanguageProvider>();
    final roleName =
        await _showRoleNameDialog(context, title: lang.getText('addRole'));
    if (roleName == null) return;
    await _runMutation(() => _rolesService.createRole(roleName));
  }

  Future<void> _editRole(RoleSummary role) async {
    final roleName = await _showRoleNameDialog(
      context,
      title: 'Rename Role',
      initialValue: role.roleName,
    );
    if (roleName == null) return;
    await _runMutation(
      () => _rolesService.updateRole(id: role.id, roleName: roleName),
    );
  }

  Future<void> _deleteRole(RoleSummary role) async {
    final lang = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(lang.getText('deleteRoleQuestion')),
            content: Text(
              lang.getText('willDeleteItem').replaceAll(
                    '{name}',
                    _localizedRoleDisplayName(role.roleName, lang),
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
    await _runMutation(() => _rolesService.deleteRole(role.id));
  }

  Future<void> _editUserRoles(User user) async {
    final lang = context.read<LanguageProvider>();
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('noRolesAvailable'))),
      );
      return;
    }

    final selectedRoles = <String>{
      ...user.roles.where((role) => role.trim().isNotEmpty),
      if (user.roles.isEmpty && user.role?.trim().isNotEmpty == true)
        user.role!.trim(),
    };
    selectedRoles.removeWhere(
      (selected) => !_roles.any((role) => role.roleName == selected),
    );
    if (selectedRoles.isEmpty) selectedRoles.add(_roles.first.roleName);

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(lang.getText('updateUser')),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _roles
                      .map(
                        (role) => CheckboxListTile(
                          value: selectedRoles.contains(role.roleName),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedRoles.add(role.roleName);
                              } else if (selectedRoles.length > 1) {
                                selectedRoles.remove(role.roleName);
                              }
                            });
                          },
                          title: Text(
                            _localizedRoleDisplayName(role.roleName, lang),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(lang.getText('cancel')),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(lang.getText('save')),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!shouldSave) return;

    await _runMutation(
      () => _usersService.updateUser(
        id: user.id,
        username: user.name,
        email: user.email,
        roles: selectedRoles,
      ),
    );
  }

  Future<void> _runMutation(Future<dynamic> Function() task) async {
    try {
      await task();
      if (!mounted) return;
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('roleSaved'))),
      );
      await _loadRoles();
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
          final compact = constraints.maxWidth < 640;
          return SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 14 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: border),
                  ),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _heroContent(
                            text,
                            muted,
                            compact,
                            onRefresh: _isLoading ? null : _loadRoles,
                            onAddRole: _isLoading ? null : _createRole,
                          ),
                        )
                      : Row(
                          children: _heroContent(
                            text,
                            muted,
                            compact,
                            onRefresh: _isLoading ? null : _loadRoles,
                            onAddRole: _isLoading ? null : _createRole,
                          ),
                        ),
                ),
                const SizedBox(height: 22),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  _StatePanel(
                    icon: Icons.warning_amber_rounded,
                    message: _errorMessage!,
                    text: text,
                    muted: muted,
                    onRetry: _loadRoles,
                  )
                else if (_roles.isEmpty)
                  _StatePanel(
                    icon: Icons.admin_panel_settings_outlined,
                    message: lang.getText('noRolesYet'),
                    text: text,
                    muted: muted,
                    onRetry: _loadRoles,
                  )
                else
                  ...[
                    ..._roles.map(
                      (role) => Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: LayoutBuilder(
                          builder: (context, rowConstraints) {
                            final stackRow = rowConstraints.maxWidth < 720;
                            final details = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _localizedRoleDisplayName(
                                    role.roleName,
                                    lang,
                                  ),
                                  style: TextStyle(
                                    color: text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lang.getText('accessGroup'),
                                  style: TextStyle(color: muted),
                                ),
                              ],
                            );
                            final stats = Wrap(
                              spacing: 28,
                              runSpacing: 12,
                              children: [
                                _miniStat(
                                  lang.getText('users'),
                                  (_roleUsage[role.roleName] ?? 0).toString(),
                                  text,
                                  muted,
                                ),
                                _miniStat(
                                  lang.getText('status'),
                                  lang.getText('active'),
                                  text,
                                  muted,
                                ),
                              ],
                            );
                            final actions = Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _editRole(role),
                                  icon:
                                      const Icon(Icons.edit_rounded, size: 18),
                                  label: const Text('Rename'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _deleteRole(role),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  label: Text(lang.getText('delete')),
                                ),
                              ],
                            );

                            if (stackRow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  details,
                                  const SizedBox(height: 16),
                                  stats,
                                  const SizedBox(height: 16),
                                  actions,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(flex: 3, child: details),
                                Expanded(flex: 2, child: stats),
                                actions,
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _userRoleAssignments(
                      users: _users,
                      card: card,
                      border: border,
                      text: text,
                      muted: muted,
                      lang: lang,
                    ),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _heroContent(
    Color text,
    Color muted,
    bool compact, {
    required VoidCallback? onRefresh,
    required VoidCallback? onAddRole,
  }) {
    final controls = _RoleHeroActions(
      onRefresh: onRefresh,
      onAddRole: onAddRole,
    );
    return [
      Container(
        width: compact ? 58 : 72,
        height: compact ? 58 : 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
        ),
        child: Icon(
          Icons.admin_panel_settings_outlined,
          color: const Color(0xFF38BDF8),
          size: compact ? 28 : 34,
        ),
      ),
      SizedBox(width: compact ? 0 : 18, height: compact ? 14 : 0),
      if (!compact)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _heroText(text, muted, compact),
          ),
        )
      else
        ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _heroText(text, muted, compact),
          ),
          const SizedBox(height: 16),
          controls,
        ],
      if (!compact) controls,
    ];
  }

  List<Widget> _heroText(Color text, Color muted, bool compact) {
    final lang = context.watch<LanguageProvider>();
    return [
      Text(
        lang.getText('roles'),
        style: TextStyle(
          color: text,
          fontSize: compact ? 28 : 32,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        lang.getText('rolesSubtitle'),
        style: TextStyle(color: muted, fontSize: 15),
      ),
    ];
  }

  Widget _miniStat(String label, String value, Color text, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style:
              TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: muted)),
      ],
    );
  }

  Widget _userRoleAssignments({
    required List<User> users,
    required Color card,
    required Color border,
    required Color text,
    required Color muted,
    required LanguageProvider lang,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText('users'),
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 14),
          if (users.isEmpty)
            Text(lang.getText('noUsersFound'), style: TextStyle(color: muted))
          else
            ...users.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stack = constraints.maxWidth < 700;
                    final identity = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? lang.getText('user') : user.name,
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(user.email, style: TextStyle(color: muted)),
                      ],
                    );
                    final roleText = Text(
                      _localizedUserRoles(user, lang),
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                    final action = OutlinedButton.icon(
                      onPressed: () => _editUserRoles(user),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(lang.getText('edit')),
                    );

                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          identity,
                          const SizedBox(height: 8),
                          roleText,
                          const SizedBox(height: 8),
                          action,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 2, child: identity),
                        Expanded(flex: 2, child: roleText),
                        action,
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleHeroActions extends StatelessWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onAddRole;

  const _RoleHeroActions({
    required this.onRefresh,
    required this.onAddRole,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton(
          onPressed: onRefresh,
          child: const Icon(Icons.refresh_rounded, size: 20),
        ),
        FilledButton.icon(
          onPressed: onAddRole,
          icon: const Icon(Icons.add_rounded),
          label: Text(lang.getText('addRole')),
        ),
      ],
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color text;
  final Color muted;
  final VoidCallback onRetry;

  const _StatePanel({
    required this.icon,
    required this.message,
    required this.text,
    required this.muted,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: muted, size: 36),
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
      ),
    );
  }
}

Future<String?> _showRoleNameDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
}) async {
  final lang = context.read<LanguageProvider>();
  final controller = TextEditingController(text: initialValue ?? '');
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: lang.getText('role'),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? lang.getText('role')
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
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(lang.getText('save')),
          ),
        ],
      ),
    ),
  );

  controller.dispose();
  return result;
}
