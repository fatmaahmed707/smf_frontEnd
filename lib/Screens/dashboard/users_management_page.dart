import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device_record.dart';
import '../../models/role_summary.dart';
import '../../models/smf_device.dart';
import '../../models/user.dart';
import '../../models/worker_profile.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../services/devices_service.dart';
import 'package:smf_main/services/frontend_report_snapshot.dart';
import '../../services/roles_service.dart';
import '../../services/smf_devices_service.dart';
import '../../services/users_service.dart';
import '../../services/workers_service.dart';

String _localizedUserRole(String value, LanguageProvider lang) {
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
  if (roles.isEmpty) return _localizedUserRole('USER', lang);
  return roles.map((role) => _localizedUserRole(role, lang)).join(', ');
}

String _deviceOptionLabel(SmfDevice device, LanguageProvider lang) {
  final label = device.label.trim().isEmpty
      ? lang.getText('unlabeled')
      : device.label.trim();
  final mac = device.macAddress.trim();
  return mac.isEmpty ? label : '$label - $mac';
}

String _assignedDevicesLabel(
  List<DeviceRecord> devices,
  LanguageProvider lang,
) {
  if (devices.isEmpty) return lang.getText('unassigned');
  return devices
      .map((device) => _singleAssignedDeviceLabel(device, lang))
      .join(', ');
}

String _singleAssignedDeviceLabel(DeviceRecord device, LanguageProvider lang) {
  final label = device.displayLabel.trim().isNotEmpty
      ? device.displayLabel.trim()
      : device.label.trim();
  final mac = device.macAddress.trim();
  if (label.isNotEmpty && mac.isNotEmpty) return '$label - $mac';
  if (label.isNotEmpty) return label;
  if (mac.isNotEmpty) return mac;
  return device.id.isEmpty ? lang.getText('unassigned') : device.id;
}

String _displayValue(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? '-' : trimmed;
}

String _displayDate(DateTime? value) {
  if (value == null) return '-';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _displayDateTime(DateTime? value) {
  if (value == null) return '-';
  final date = _displayDate(value);
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$date $hour:$minute';
}

class _DeviceAssignmentOption {
  final String id;
  final String label;
  final SmfDevice? smfDevice;
  final DeviceRecord? deviceRecord;

  const _DeviceAssignmentOption.register({
    required this.id,
    required this.label,
    required SmfDevice this.smfDevice,
  }) : deviceRecord = null;

  const _DeviceAssignmentOption.reassign({
    required this.id,
    required this.label,
    required DeviceRecord this.deviceRecord,
    required SmfDevice this.smfDevice,
  });

  bool get isExistingDevice => deviceRecord != null;
}

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  final UsersService _usersService = UsersService();
  final DevicesService _devicesService = DevicesService();
  final RolesService _rolesService = RolesService();
  final SmfDevicesService _smfDevicesService = SmfDevicesService();
  final WorkersService _workersService = WorkersService();

  bool _isLoading = true;
  List<User> _users = const [];
  List<RoleSummary> _roles = const [];
  List<DeviceRecord> _assignedDevices = const [];
  List<SmfDevice> _allSmfDevices = const [];
  List<SmfDevice> _availableDevices = const [];
  String? _errorMessage;
  String _searchQuery = '';
  int _currentPage = 1;

  static const int _usersPerPage = 10;

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
      final results = await Future.wait([
        _usersService.getUsers(),
        _rolesService.getRoles(),
        _devicesService.getDevices(),
        _smfDevicesService.getAllDevices(),
        _smfDevicesService.getUnregisteredDevices(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _users = results[0] as List<User>;
        _roles = results[1] as List<RoleSummary>;
        _assignedDevices = results[2] as List<DeviceRecord>;
        _allSmfDevices = results[3] as List<SmfDevice>;
        _availableDevices = results[4] as List<SmfDevice>;
        _isLoading = false;
      });
      _updateReportSnapshot();
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
            context.read<LanguageProvider>().getText('failedToLoadUsers');
        _isLoading = false;
      });
    }
  }

  void _updateReportSnapshot() {
    FrontendReportSnapshot.instance.updateUsersManagement(
      users: _users,
      assignedDevices: _assignedDevices,
      smfDevices: _allSmfDevices,
      availableSmfDevices: _availableDevices,
      searchQuery: _searchQuery,
      currentPage: _currentPage,
    );
  }

  List<DeviceRecord> _assignedDevicesFor(User user) {
    return _assignedDevices.where((device) => device.ownerId == user.id).map(
      (device) {
        final smfDevice = _smfDeviceFor(device);
        return smfDevice == null
            ? device
            : device.copyWithDisplayLabel(smfDevice.label);
      },
    ).toList();
  }

  SmfDevice? _smfDeviceFor(DeviceRecord device) {
    final deviceMac = device.macAddress.trim().toLowerCase();
    if (deviceMac.isEmpty) return null;
    for (final smfDevice in _allSmfDevices) {
      if (smfDevice.macAddress.trim().toLowerCase() == deviceMac) {
        return smfDevice;
      }
    }
    return null;
  }

  List<_DeviceAssignmentOption> _assignmentOptionsFor(User user) {
    final options = <_DeviceAssignmentOption>[];

    for (final device in _availableDevices) {
      if (device.label.trim().isEmpty) continue;
      options.add(
        _DeviceAssignmentOption.register(
          id: 'register:${device.id}',
          label: '${_deviceOptionLabel(device, context.read<LanguageProvider>())} (new)',
          smfDevice: device,
        ),
      );
    }

    for (final device in _assignedDevices) {
      if (device.ownerId == user.id || device.id.isEmpty) continue;
      final smfDevice = _smfDeviceFor(device);
      if (smfDevice == null || smfDevice.label.trim().isEmpty) continue;
      String? currentOwner;
      for (final owner in _users) {
        if (owner.id == device.ownerId) {
          currentOwner = owner.name.isEmpty ? owner.email : owner.name;
          break;
        }
      }
      final ownerSuffix = currentOwner == null ? '' : ' - assigned to $currentOwner';
      options.add(
        _DeviceAssignmentOption.reassign(
          id: 'reassign:${device.id}',
          label:
              '${_deviceOptionLabel(smfDevice, context.read<LanguageProvider>())}$ownerSuffix',
          deviceRecord: device,
          smfDevice: smfDevice,
        ),
      );
    }

    return options;
  }

  Future<void> _assignDevice(User user) async {
    final lang = context.read<LanguageProvider>();
    final options = _assignmentOptionsFor(user);
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('noAvailableDevices'))),
      );
      return;
    }

    _DeviceAssignmentOption selectedOption = options.first;
    final shouldAssign = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(
                selectedOption.isExistingDevice
                    ? 'Assign / Reassign Device'
                    : lang.getText('assignDevice'),
              ),
              content: SizedBox(
                width: 420,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedOption.id,
                  items: options
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    final match = options.firstWhere(
                      (option) => option.id == value,
                      orElse: () => selectedOption,
                    );
                    setDialogState(() => selectedOption = match);
                  },
                  decoration: InputDecoration(
                    labelText: lang.getText('availableDevices'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(lang.getText('cancel')),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: Text(lang.getText('assign')),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!shouldAssign) return;

    try {
      if (selectedOption.isExistingDevice) {
        await _devicesService.updateDevice(
          id: selectedOption.deviceRecord!.id,
          smfDeviceLabel: selectedOption.smfDevice!.label,
          ownerId: user.id,
          zoneId: selectedOption.deviceRecord!.zoneId,
        );
      } else {
        await _devicesService.registerDevice(
          smfDeviceLabel: selectedOption.smfDevice!.label,
          ownerId: user.id,
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('deviceAssigned'))),
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

  Future<void> _showCreateWorkerUserDialog() async {
    final lang = context.read<LanguageProvider>();
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('noRolesAvailable'))),
      );
      return;
    }

    final created = await _showWorkerUserFormDialog(
      context,
      roles: _roles,
      availableDevices: _availableDevices,
      onSubmit: ({
        required String username,
        required String email,
        required String password,
        required String roleName,
        required String? smfDeviceLabel,
        required Map<String, String> workerFields,
      }) async {
        final user = await _usersService.createUser(
          username: username,
          email: email,
          password: password,
          roles: {roleName},
        );
        final worker = await _workersService.createWorker(
          userId: user.id,
          fields: workerFields,
        );
        FrontendReportSnapshot.instance.cacheWorkerProfile(user.id, worker);
        if (smfDeviceLabel != null && smfDeviceLabel.isNotEmpty) {
          await _devicesService.registerDevice(
            smfDeviceLabel: smfDeviceLabel,
            ownerId: user.id,
          );
        }
      },
    );

    if (created == true) {
      await _load();
    }
  }

  Future<void> _editWorkerProfile(User user) async {
    try {
      final worker = await _workersService.getWorker(user.id);
      FrontendReportSnapshot.instance.cacheWorkerProfile(user.id, worker);
      if (!mounted) return;
      final updated = await _showWorkerProfileEditDialog(
        context,
        user: user,
        worker: worker,
        onSubmit: (fields) async {
          final updated = await _workersService.updateWorker(
            id: user.id,
            fields: fields,
          );
          FrontendReportSnapshot.instance.cacheWorkerProfile(user.id, updated);
        },
      );
      if (updated == true) {
        await _load();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _deleteWorkerProfile(User user) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete worker information?'),
            content: Text(
              'This deletes the worker profile information for ${user.name.isEmpty ? user.email : user.name}. The user account is not deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.read<LanguageProvider>().getText('cancel')),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(context.read<LanguageProvider>().getText('delete')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      await _workersService.deleteWorker(user.id);
      FrontendReportSnapshot.instance.removeWorkerProfile(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker information deleted.')),
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _showDetails(User user) async {
    WorkerProfile? worker;
    String? workerError;
    try {
      final details = await _usersService.getUser(user.id);
      try {
        worker = await _workersService.getWorker(user.id);
        FrontendReportSnapshot.instance.cacheWorkerProfile(user.id, worker);
      } on ApiException catch (error) {
        workerError = error.message;
      }
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => _WorkerProfileDialog(
          user: details,
          worker: worker,
          workerError: workerError,
          assignedDevices: _assignedDevicesFor(user),
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

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.role ?? '').toLowerCase().contains(query);
    }).toList();

    final calculatedTotalPages = (filteredUsers.length / _usersPerPage).ceil();
    final totalPages = calculatedTotalPages < 1 ? 1 : calculatedTotalPages;
    final currentPage = _currentPage < 1
        ? 1
        : _currentPage > totalPages
            ? totalPages
            : _currentPage;
    final startIndex = (currentPage - 1) * _usersPerPage;
    final visibleUsers = filteredUsers
        .skip(startIndex)
        .take(_usersPerPage)
        .toList();

    return _UsersConsole(
      users: visibleUsers,
      totalUsers: _users.length,
      currentPage: currentPage,
      totalPages: totalPages,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      searchQuery: _searchQuery,
      onSearchChanged: (value) => setState(() {
        _searchQuery = value;
        _currentPage = 1;
        FrontendReportSnapshot.instance.updateUsersViewState(
          searchQuery: _searchQuery,
          currentPage: _currentPage,
        );
      }),
      onPageChanged: (page) => setState(() {
        _currentPage = page;
        FrontendReportSnapshot.instance.updateUsersViewState(
          searchQuery: _searchQuery,
          currentPage: _currentPage,
        );
      }),
      onRefresh: _isLoading ? null : _load,
      onAddUser: _isLoading ? null : _showCreateWorkerUserDialog,
      onDetails: _showDetails,
      onEditProfile: _editWorkerProfile,
      onDeleteProfile: _deleteWorkerProfile,
      onAssignDevice: _assignDevice,
      assignedDevicesFor: _assignedDevicesFor,
    );
  }
}

typedef _WorkerUserSubmit = Future<void> Function({
  required String username,
  required String email,
  required String password,
  required String roleName,
  required String? smfDeviceLabel,
  required Map<String, String> workerFields,
});

Future<bool?> _showWorkerUserFormDialog(
  BuildContext context, {
  required List<RoleSummary> roles,
  required List<SmfDevice> availableDevices,
  required _WorkerUserSubmit onSubmit,
}) async {
  final lang = context.read<LanguageProvider>();
  final formKey = GlobalKey<FormState>();
  final fields = {
    'full_name_ar': TextEditingController(),
    'full_name_en': TextEditingController(),
    'date_of_birth': TextEditingController(),
    'address_ar': TextEditingController(),
    'address_en': TextEditingController(),
    'phone': TextEditingController(),
    'role_ar': TextEditingController(),
    'role_en': TextEditingController(),
    'company_ar': TextEditingController(),
    'company_en': TextEditingController(),
    'work_location_ar': TextEditingController(),
    'work_location_en': TextEditingController(),
    'medical_condition_ar': TextEditingController(),
    'medical_condition_en': TextEditingController(),
    'clinical_notes_ar': TextEditingController(),
    'clinical_notes_en': TextEditingController(),
    'emergency_contact_name': TextEditingController(),
    'emergency_contact_relation': TextEditingController(),
    'emergency_phone': TextEditingController(),
    'username': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
  };
  var tabIndex = 0;
  var selectedRole = roles.first.roleName;
  var selectedDeviceLabel = '';
  var isSaving = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final sections = [
          _WorkerFormSection(
            title: 'Personal',
            children: [
              _workerField(context, fields['full_name_ar']!, 'Full Name (AR)'),
              _workerField(
                context,
                fields['full_name_en']!,
                'Full Name (EN)',
                required: true,
              ),
              _workerField(
                context,
                fields['date_of_birth']!,
                'Date of Birth',
                hint: 'YYYY-MM-DD',
                date: true,
              ),
              _workerField(context, fields['address_ar']!, 'Address (AR)'),
              _workerField(context, fields['address_en']!, 'Address (EN)'),
              _workerField(context, fields['phone']!, 'Phone'),
            ],
          ),
          _WorkerFormSection(
            title: 'Work',
            children: [
              _workerField(context, fields['role_ar']!, 'Role (AR)'),
              _workerField(context, fields['role_en']!, 'Role (EN)'),
              _workerField(context, fields['company_ar']!, 'Company (AR)'),
              _workerField(context, fields['company_en']!, 'Company (EN)'),
              _workerField(
                  context, fields['work_location_ar']!, 'Work Location (AR)'),
              _workerField(
                  context, fields['work_location_en']!, 'Work Location (EN)'),
            ],
          ),
          _WorkerFormSection(
            title: 'Medical',
            children: [
              _workerField(
                context,
                fields['medical_condition_ar']!,
                'Medical Condition (AR)',
              ),
              _workerField(
                context,
                fields['medical_condition_en']!,
                'Medical Condition (EN)',
              ),
              _workerField(
                  context, fields['clinical_notes_ar']!, 'Clinical Notes (AR)'),
              _workerField(
                  context, fields['clinical_notes_en']!, 'Clinical Notes (EN)'),
            ],
          ),
          _WorkerFormSection(
            title: 'Emergency',
            children: [
              _workerField(
                context,
                fields['emergency_contact_name']!,
                'Emergency Contact Name',
              ),
              _workerField(
                context,
                fields['emergency_contact_relation']!,
                'Emergency Contact Relationship',
              ),
              _workerField(context, fields['emergency_phone']!, 'Emergency Phone'),
            ],
          ),
          _WorkerFormSection(
            title: 'System',
            children: [
              _workerField(context, fields['username']!, 'Username',
                  required: true),
              _workerField(
                context,
                fields['email']!,
                'Email',
                required: true,
                email: true,
              ),
              _workerField(
                context,
                fields['password']!,
                'Password',
                required: true,
                obscure: true,
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                items: roles
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role.roleName,
                        child: Text(_localizedUserRole(role.roleName, lang)),
                      ),
                    )
                    .toList(),
                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value != null) selectedRole = value;
                      },
                decoration: const InputDecoration(
                  labelText: 'Account Role',
                  border: OutlineInputBorder(),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedDeviceLabel,
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('No device'),
                  ),
                  ...availableDevices
                      .where((device) => device.label.trim().isNotEmpty)
                      .map(
                        (device) => DropdownMenuItem<String>(
                          value: device.label,
                          child: Text(_deviceOptionLabel(device, lang)),
                        ),
                      ),
                ],
                onChanged: isSaving
                    ? null
                    : (value) {
                        selectedDeviceLabel = value ?? '';
                      },
                decoration: const InputDecoration(
                  labelText: 'Optional Device Assignment',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ];

        return Dialog(
          backgroundColor: const Color(0xFF0A1A35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0x5538BDF8)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 18, 22, 10),
                  child: Row(
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          color: Color(0xFF38BDF8)),
                      SizedBox(width: 10),
                      Text(
                        'Add New User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: SegmentedButton<int>(
                    selected: {tabIndex},
                    onSelectionChanged: isSaving
                        ? null
                        : (value) {
                            setDialogState(() => tabIndex = value.first);
                          },
                    segments: [
                      for (var i = 0; i < sections.length; i++)
                        ButtonSegment<int>(
                          value: i,
                          label: Text(sections[i].title),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                      child: sections[tabIndex],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0x3338BDF8))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            isSaving ? null : () => Navigator.pop(context, false),
                        child: Text(lang.getText('cancel')),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSaving = true);
                                try {
                                  final workerFields = {
                                    for (final entry in fields.entries)
                                      if (!{
                                            'username',
                                            'email',
                                            'password',
                                          }.contains(entry.key) &&
                                          entry.value.text.trim().isNotEmpty)
                                        entry.key: entry.value.text.trim(),
                                  };
                                  await onSubmit(
                                    username: fields['username']!.text.trim(),
                                    email: fields['email']!.text.trim(),
                                    password: fields['password']!.text,
                                    roleName: selectedRole,
                                    smfDeviceLabel:
                                        selectedDeviceLabel.isEmpty
                                            ? null
                                            : selectedDeviceLabel,
                                    workerFields: workerFields,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                } on ApiException catch (error) {
                                  setDialogState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error.message)),
                                    );
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(lang.getText('save')),
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
  );

  for (final controller in fields.values) {
    controller.dispose();
  }
  return result;
}

Future<bool?> _showWorkerProfileEditDialog(
  BuildContext context, {
  required User user,
  required WorkerProfile worker,
  required Future<void> Function(Map<String, String> fields) onSubmit,
}) async {
  final lang = context.read<LanguageProvider>();
  final formKey = GlobalKey<FormState>();
  final fields = {
    'full_name_ar': TextEditingController(text: worker.fullNameAr),
    'full_name_en': TextEditingController(text: worker.fullNameEn),
    'date_of_birth': TextEditingController(text: _displayDate(worker.dateOfBirth)),
    'address_ar': TextEditingController(text: worker.addressAr),
    'address_en': TextEditingController(text: worker.addressEn),
    'phone': TextEditingController(text: worker.phone),
    'role_ar': TextEditingController(text: worker.roleAr),
    'role_en': TextEditingController(text: worker.roleEn),
    'company_ar': TextEditingController(text: worker.companyAr),
    'company_en': TextEditingController(text: worker.companyEn),
    'work_location_ar': TextEditingController(text: worker.workLocationAr),
    'work_location_en': TextEditingController(text: worker.workLocationEn),
    'medical_condition_ar': TextEditingController(text: worker.medicalConditionAr),
    'medical_condition_en': TextEditingController(text: worker.medicalConditionEn),
    'clinical_notes_ar': TextEditingController(text: worker.clinicalNotesAr),
    'clinical_notes_en': TextEditingController(text: worker.clinicalNotesEn),
    'emergency_contact_name':
        TextEditingController(text: worker.emergencyContactName),
    'emergency_contact_relation':
        TextEditingController(text: worker.emergencyContactRelation),
    'emergency_phone': TextEditingController(text: worker.emergencyPhone),
  };
  var tabIndex = 0;
  var isSaving = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final sections = [
          _WorkerFormSection(
            title: 'Personal',
            children: [
              _workerField(context, fields['full_name_ar']!, 'Full Name (AR)'),
              _workerField(
                context,
                fields['full_name_en']!,
                'Full Name (EN)',
                required: true,
              ),
              _workerField(
                context,
                fields['date_of_birth']!,
                'Date of Birth',
                hint: 'YYYY-MM-DD',
                date: true,
              ),
              _workerField(context, fields['address_ar']!, 'Address (AR)'),
              _workerField(context, fields['address_en']!, 'Address (EN)'),
              _workerField(context, fields['phone']!, 'Phone'),
            ],
          ),
          _WorkerFormSection(
            title: 'Work',
            children: [
              _workerField(context, fields['role_ar']!, 'Role (AR)'),
              _workerField(context, fields['role_en']!, 'Role (EN)'),
              _workerField(context, fields['company_ar']!, 'Company (AR)'),
              _workerField(context, fields['company_en']!, 'Company (EN)'),
              _workerField(
                  context, fields['work_location_ar']!, 'Work Location (AR)'),
              _workerField(
                  context, fields['work_location_en']!, 'Work Location (EN)'),
            ],
          ),
          _WorkerFormSection(
            title: 'Medical',
            children: [
              _workerField(
                context,
                fields['medical_condition_ar']!,
                'Medical Condition (AR)',
              ),
              _workerField(
                context,
                fields['medical_condition_en']!,
                'Medical Condition (EN)',
              ),
              _workerField(
                  context, fields['clinical_notes_ar']!, 'Clinical Notes (AR)'),
              _workerField(
                  context, fields['clinical_notes_en']!, 'Clinical Notes (EN)'),
            ],
          ),
          _WorkerFormSection(
            title: 'Emergency',
            children: [
              _workerField(
                context,
                fields['emergency_contact_name']!,
                'Emergency Contact Name',
              ),
              _workerField(
                context,
                fields['emergency_contact_relation']!,
                'Emergency Contact Relationship',
              ),
              _workerField(context, fields['emergency_phone']!, 'Emergency Phone'),
            ],
          ),
        ];

        return Dialog(
          backgroundColor: const Color(0xFF0A1A35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0x5538BDF8)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980, maxHeight: 700),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Update Worker Info - ${user.name.isEmpty ? user.email : user.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: SegmentedButton<int>(
                    selected: {tabIndex},
                    onSelectionChanged: isSaving
                        ? null
                        : (value) {
                            setDialogState(() => tabIndex = value.first);
                          },
                    segments: [
                      for (var i = 0; i < sections.length; i++)
                        ButtonSegment<int>(
                          value: i,
                          label: Text(sections[i].title),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                      child: sections[tabIndex],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0x3338BDF8))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            isSaving ? null : () => Navigator.pop(context, false),
                        child: Text(lang.getText('cancel')),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSaving = true);
                                try {
                                  final payload = {
                                    for (final entry in fields.entries)
                                      if (entry.key != 'date_of_birth' ||
                                          entry.value.text.trim().isNotEmpty)
                                        entry.key: entry.value.text.trim(),
                                  };
                                  await onSubmit(payload);
                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                } on ApiException catch (error) {
                                  setDialogState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error.message)),
                                    );
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(lang.getText('save')),
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
  );

  for (final controller in fields.values) {
    controller.dispose();
  }
  return result;
}

Widget _workerField(
  BuildContext context,
  TextEditingController controller,
  String label, {
  bool required = false,
  bool email = false,
  bool obscure = false,
  bool date = false,
  String? hint,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscure,
    readOnly: date,
    onTap: date
        ? () async {
            final now = DateTime.now();
            final current = DateTime.tryParse(controller.text.trim());
            final picked = await showDatePicker(
              context: context,
              initialDate: current ?? DateTime(now.year - 25, now.month, now.day),
              firstDate: DateTime(1900),
              lastDate: now,
            );
            if (picked == null) return;
            final month = picked.month.toString().padLeft(2, '0');
            final day = picked.day.toString().padLeft(2, '0');
            controller.text = '${picked.year}-$month-$day';
          }
        : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: date ? const Icon(Icons.calendar_month_rounded) : null,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return '$label is required';
      if (email && text.isNotEmpty && !text.contains('@')) {
        return 'Enter a valid email';
      }
      if (date &&
          text.isNotEmpty &&
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
        return 'Use YYYY-MM-DD';
      }
      return null;
    },
  );
}

class _WorkerFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _WorkerFormSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final child in children)
          SizedBox(
            width: 430,
            child: child,
          ),
      ],
    );
  }
}

class _WorkerProfileDialog extends StatelessWidget {
  final User user;
  final WorkerProfile? worker;
  final String? workerError;
  final List<DeviceRecord> assignedDevices;

  const _WorkerProfileDialog({
    required this.user,
    required this.worker,
    required this.workerError,
    required this.assignedDevices,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final lastSeen = assignedDevices
        .map((device) => device.lastSeenTimestamp)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (latest, value) {
      if (latest == null || value.isAfter(latest)) return value;
      return latest;
    });

    return Dialog(
      backgroundColor: const Color(0xFF061936),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x5538BDF8)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 10),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      worker?.fullNameEn.trim().isNotEmpty == true
                          ? worker!.fullNameEn
                          : user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (workerError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ProfileSection(
                          title: 'Worker Profile',
                          rows: {'Status': workerError!},
                        ),
                      ),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _ProfileSection(
                          title: 'Personal Information',
                          rows: {
                            'ID': user.id,
                            'Full Name (AR)': _displayValue(worker?.fullNameAr),
                            'Full Name (EN)': _displayValue(
                              worker?.fullNameEn ?? user.name,
                            ),
                            'Date of Birth': _displayDate(worker?.dateOfBirth),
                            'Phone': _displayValue(worker?.phone),
                            'Address (AR)': _displayValue(worker?.addressAr),
                            'Address (EN)': _displayValue(worker?.addressEn),
                          },
                        ),
                        _ProfileSection(
                          title: 'Work Information',
                          rows: {
                            'Role (AR)': _displayValue(worker?.roleAr),
                            'Role (EN)': _displayValue(worker?.roleEn),
                            'Company (AR)': _displayValue(worker?.companyAr),
                            'Company (EN)': _displayValue(worker?.companyEn),
                            'Work Location (AR)':
                                _displayValue(worker?.workLocationAr),
                            'Work Location (EN)':
                                _displayValue(worker?.workLocationEn),
                          },
                        ),
                        _ProfileSection(
                          title: 'Medical Information',
                          rows: {
                            'Medical Condition (AR)':
                                _displayValue(worker?.medicalConditionAr),
                            'Medical Condition (EN)':
                                _displayValue(worker?.medicalConditionEn),
                            'Clinical Notes (AR)':
                                _displayValue(worker?.clinicalNotesAr),
                            'Clinical Notes (EN)':
                                _displayValue(worker?.clinicalNotesEn),
                          },
                        ),
                        _ProfileSection(
                          title: 'Emergency Contact',
                          rows: {
                            'Emergency Contact Name':
                                _displayValue(worker?.emergencyContactName),
                            'Emergency Contact Relationship':
                                _displayValue(worker?.emergencyContactRelation),
                            'Emergency Phone':
                                _displayValue(worker?.emergencyPhone),
                          },
                        ),
                        _ProfileSection(
                          title: 'System Information',
                          rows: {
                            'User ID': user.id,
                            'Worker Profile ID': _displayValue(worker?.id),
                            'Email': user.email,
                            'Username': user.name,
                            'Account Role': _localizedUserRoles(user, lang),
                            'Assigned Device(s)':
                                _assignedDevicesLabel(assignedDevices, lang),
                            'Account Status': lang.getText('active'),
                            'Last Seen': _displayDateTime(lastSeen),
                            'Created At': _displayDateTime(worker?.createdAt),
                            'Updated At': _displayDateTime(worker?.updatedAt),
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final Map<String, String> rows;

  const _ProfileSection({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x3338BDF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Color(0xFF9DB2D8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _UsersConsole extends StatelessWidget {
  final List<User> users;
  final int totalUsers;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onRefresh;
  final VoidCallback? onAddUser;
  final ValueChanged<User> onDetails;
  final ValueChanged<User> onEditProfile;
  final ValueChanged<User> onDeleteProfile;
  final ValueChanged<User> onAssignDevice;
  final List<DeviceRecord> Function(User user) assignedDevicesFor;

  const _UsersConsole({
    required this.users,
    required this.totalUsers,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.errorMessage,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onPageChanged,
    required this.onRefresh,
    required this.onAddUser,
    required this.onDetails,
    required this.onEditProfile,
    required this.onDeleteProfile,
    required this.onAssignDevice,
    required this.assignedDevicesFor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _UsersPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(14),
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UsersToolbar(
                palette: palette,
                searchQuery: searchQuery,
                onSearchChanged: onSearchChanged,
                onRefresh: onRefresh,
                onAddUser: onAddUser,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? _ErrorPanel(message: errorMessage!)
                        : _UsersTable(
                            palette: palette,
                            users: users,
                            onDetails: onDetails,
                            onEditProfile: onEditProfile,
                            onDeleteProfile: onDeleteProfile,
                            onAssignDevice: onAssignDevice,
                            assignedDevicesFor: assignedDevicesFor,
                          ),
              ),
              const SizedBox(height: 12),
              _UsersFooter(
                palette: palette,
                totalUsers: totalUsers,
                currentPage: currentPage,
                totalPages: totalPages,
                onPageChanged: onPageChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersToolbar extends StatelessWidget {
  final _UsersPalette palette;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onRefresh;
  final VoidCallback? onAddUser;

  const _UsersToolbar({
    required this.palette,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onAddUser,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final searchField = SizedBox(
          width: compact ? double.infinity : 260,
          height: 42,
          child: TextField(
            onChanged: onSearchChanged,
            style: TextStyle(color: palette.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded,
                  color: palette.textMuted, size: 20),
              hintText: lang.getText('searchUsers'),
              hintStyle: TextStyle(color: palette.textMuted),
              filled: true,
              fillColor: palette.control,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: palette.tableBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: palette.tableBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: palette.blue),
              ),
            ),
          ),
        );
        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _IconSquareButton(
              palette: palette,
              icon: Icons.refresh_rounded,
              onPressed: onRefresh,
            ),
            FilledButton.icon(
              onPressed: onAddUser,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Add New User'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.getText('usersManagement'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              searchField,
              const SizedBox(height: 12),
              actions,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                lang.getText('usersManagement'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            searchField,
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class _UsersTable extends StatelessWidget {
  final _UsersPalette palette;
  final List<User> users;
  final ValueChanged<User> onDetails;
  final ValueChanged<User> onEditProfile;
  final ValueChanged<User> onDeleteProfile;
  final ValueChanged<User> onAssignDevice;
  final List<DeviceRecord> Function(User user) assignedDevicesFor;

  const _UsersTable({
    required this.palette,
    required this.users,
    required this.onDetails,
    required this.onEditProfile,
    required this.onDeleteProfile,
    required this.onAssignDevice,
    required this.assignedDevicesFor,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: palette.tableBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth =
                constraints.maxWidth < 1360 ? 1360.0 : constraints.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Center(
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        _UsersTableHeader(palette: palette),
                        Expanded(
                          child: users.isEmpty
                              ? Center(
                                  child: Text(
                                    lang.getText('noUsersFound'),
                                    style: TextStyle(
                                      color: palette.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: users.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: palette.tableBorder,
                                  ),
                                  itemBuilder: (context, index) =>
                                      _UsersTableRow(
                                    palette: palette,
                                    user: users[index],
                                    index: index,
                                    onDetails: onDetails,
                                    onEditProfile: onEditProfile,
                                    onDeleteProfile: onDeleteProfile,
                                    onAssignDevice: onAssignDevice,
                                    assignedDevices:
                                        assignedDevicesFor(users[index]),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UsersTableHeader extends StatelessWidget {
  final _UsersPalette palette;

  const _UsersTableHeader({required this.palette});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      height: 48,
      color: palette.header,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _UsersHeaderCell(lang.getText('user'), width: 260, palette: palette),
          _UsersHeaderCell(lang.getText('role'), width: 180, palette: palette),
          _UsersHeaderCell(lang.getText('status'), width: 140, palette: palette),
          _UsersHeaderCell(lang.getText('lastSeen'), width: 210, palette: palette),
          _UsersHeaderCell(lang.getText('assignedDevice'), width: 300, palette: palette),
          _UsersHeaderCell(lang.getText('actions'), width: 190, palette: palette),
        ],
      ),
    );
  }
}

class _UsersHeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final _UsersPalette palette;

  const _UsersHeaderCell(
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

class _UsersTableRow extends StatelessWidget {
  final _UsersPalette palette;
  final User user;
  final int index;
  final ValueChanged<User> onDetails;
  final ValueChanged<User> onEditProfile;
  final ValueChanged<User> onDeleteProfile;
  final ValueChanged<User> onAssignDevice;
  final List<DeviceRecord> assignedDevices;

  const _UsersTableRow({
    required this.palette,
    required this.user,
    required this.index,
    required this.onDetails,
    required this.onEditProfile,
    required this.onDeleteProfile,
    required this.onAssignDevice,
    required this.assignedDevices,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final roles = _normalizedRoles(user);
    final accent = _roleColor(roles.first);
    return Container(
      height: 58,
      color: palette.row,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: Row(
              children: [
                _UserAvatar(
                  letter: _avatarLetter(user, index),
                  color: accent,
                  palette: palette,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? lang.getText('user') : user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 180,
            child: _RolePills(roles: roles, palette: palette),
          ),
          SizedBox(
            width: 140,
            child: _StatusPill(palette: palette),
          ),
          SizedBox(
            width: 210,
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 15, color: palette.textMuted),
                const SizedBox(width: 7),
                Text(
                  _lastActive(context, index),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 300,
            child: Text(
              _assignedDevicesLabel(assignedDevices, lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: assignedDevices.isEmpty
                    ? palette.textMuted
                    : palette.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 178,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _UserActionButton(
                  icon: Icons.visibility_outlined,
                  color: palette.blue,
                  palette: palette,
                  tooltip: lang.getText('details'),
                  onPressed: () => onDetails(user),
                ),
                const SizedBox(width: 8),
                _UserActionButton(
                  icon: Icons.edit_note_rounded,
                  color: palette.blue,
                  palette: palette,
                  tooltip: 'Update worker info',
                  onPressed: () => onEditProfile(user),
                ),
                const SizedBox(width: 8),
                _UserActionButton(
                  icon: Icons.link_rounded,
                  color: palette.blue,
                  palette: palette,
                  tooltip: assignedDevices.isEmpty
                      ? lang.getText('assignDevice')
                      : 'Assign / Reassign Device',
                  onPressed: () => onAssignDevice(user),
                ),
                const SizedBox(width: 8),
                _UserActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFFF3B43),
                  palette: palette,
                  tooltip: 'Delete worker info',
                  onPressed: () => onDeleteProfile(user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _normalizedRoles(User user) {
    final values = user.roles.isNotEmpty
        ? user.roles
        : [
            user.role?.trim().isNotEmpty == true ? user.role!.trim() : 'USER',
          ];
    final normalized = values
        .where((role) => role.trim().isNotEmpty)
        .map((role) => role.replaceAll('ROLE_', '').toUpperCase())
        .toList();
    return normalized.isEmpty ? ['USER'] : normalized;
  }

  static String _avatarLetter(User user, int index) {
    final source = user.name.trim().isNotEmpty ? user.name.trim() : user.email;
    if (source.isEmpty) return String.fromCharCode(65 + index % 26);
    return source[0].toUpperCase();
  }

  static Color _roleColor(String role) {
    if (role.contains('ENGINEER')) return const Color(0xFF168BFF);
    if (role.contains('MANAGER')) return const Color(0xFF19D389);
    if (role.contains('WORKER')) return const Color(0xFFFFA51F);
    if (role.contains('ADMIN')) return const Color(0xFFFF3B43);
    if (role.contains('SUPERVISOR')) return const Color(0xFF8B5CF6);
    return const Color(0xFF168BFF);
  }

  static String _lastActive(BuildContext context, int index) {
    final lang = context.read<LanguageProvider>();
    final values = [
      '${lang.getText('today')}, 08:42 AM',
      '${lang.getText('today')}, 07:15 AM',
      '${lang.getText('yesterday')}, 11:32 PM',
      '${lang.getText('yesterday')}, 09:20 PM',
      'May 20, 2025, 04:10 PM',
    ];
    return values[index % values.length];
  }
}

class _UserAvatar extends StatelessWidget {
  final String letter;
  final Color color;
  final _UsersPalette palette;

  const _UserAvatar({
    required this.letter,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: palette.isDark ? 0.18 : 0.10),
        border: Border.all(color: color, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: palette.isDark ? 0.34 : 0.12),
            blurRadius: 14,
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RolePills extends StatelessWidget {
  final List<String> roles;
  final _UsersPalette palette;

  const _RolePills({
    required this.roles,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: roles
            .map(
              (role) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _RolePill(
                  role: role,
                  color: _UsersTableRow._roleColor(role),
                  palette: palette,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  final Color color;
  final _UsersPalette palette;

  const _RolePill({
    required this.role,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.62)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon(role), color: color, size: 13),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _localizedUserRole(role, lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    if (role.contains('MANAGER')) return Icons.verified_user_rounded;
    if (role.contains('WORKER')) return Icons.person_rounded;
    if (role.contains('ADMIN')) return Icons.shield_rounded;
    if (role.contains('SUPERVISOR')) return Icons.groups_rounded;
    return Icons.settings_rounded;
  }
}

class _StatusPill extends StatelessWidget {
  final _UsersPalette palette;

  const _StatusPill({required this.palette});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    const green = Color(0xFF19D389);
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: green.withValues(alpha: palette.isDark ? 0.17 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: green, size: 7),
          const SizedBox(width: 5),
          Text(
            lang.getText('active'),
            style: const TextStyle(
              color: green,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final _UsersPalette palette;
  final String tooltip;
  final VoidCallback? onPressed;

  const _UserActionButton({
    required this.icon,
    required this.color,
    required this.palette,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 30,
        height: 30,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                onPressed == null ? palette.textMuted : color,
            backgroundColor: palette.actionBackground,
            side: BorderSide(
              color: (onPressed == null ? palette.textMuted : color)
                  .withValues(alpha: 0.58),
            ),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Icon(icon, size: 15),
        ),
      ),
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  final _UsersPalette palette;
  final IconData icon;
  final VoidCallback? onPressed;

  const _IconSquareButton({
    required this.palette,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          backgroundColor: palette.control,
          padding: EdgeInsets.zero,
          side: BorderSide(color: palette.tableBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _UsersFooter extends StatelessWidget {
  final _UsersPalette palette;
  final int totalUsers;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _UsersFooter({
    required this.palette,
    required this.totalUsers,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final count = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_rounded, color: palette.blue, size: 16),
            const SizedBox(width: 8),
            Text(
              lang
                  .getText('totalUsers')
                  .replaceAll('{count}', totalUsers.toString()),
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
        final pager = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PageButton(
              icon: Icons.keyboard_double_arrow_left,
              palette: palette,
              onPressed:
                  currentPage > 1 ? () => onPageChanged(1) : null,
            ),
            const SizedBox(width: 8),
            _PageButton(
              icon: Icons.chevron_left_rounded,
              palette: palette,
              onPressed: currentPage > 1
                  ? () => onPageChanged(currentPage - 1)
                  : null,
            ),
            ...List.generate(
              totalPages,
              (index) {
                final page = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _PageNumberButton(
                    page: page,
                    isSelected: page == currentPage,
                    palette: palette,
                    onPressed: page == currentPage
                        ? null
                        : () => onPageChanged(page),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _PageButton(
              icon: Icons.chevron_right_rounded,
              palette: palette,
              onPressed: currentPage < totalPages
                  ? () => onPageChanged(currentPage + 1)
                  : null,
            ),
            const SizedBox(width: 8),
            _PageButton(
              icon: Icons.keyboard_double_arrow_right,
              palette: palette,
              onPressed: currentPage < totalPages
                  ? () => onPageChanged(totalPages)
                  : null,
            ),
          ],
        );

        if (compact) {
          return Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 18,
            runSpacing: 12,
            children: [count, pager],
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.centerLeft, child: count),
            pager,
          ],
        );
      },
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  final int page;
  final bool isSelected;
  final _UsersPalette palette;
  final VoidCallback? onPressed;

  const _PageNumberButton({
    required this.page,
    required this.isSelected,
    required this.palette,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : palette.textPrimary,
          backgroundColor: isSelected ? palette.blue : palette.control,
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: isSelected ? palette.blue : palette.tableBorder,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          '$page',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final _UsersPalette palette;
  final VoidCallback? onPressed;

  const _PageButton({
    required this.icon,
    required this.palette,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: onPressed == null
              ? palette.textMuted.withValues(alpha: 0.45)
              : palette.textPrimary,
          backgroundColor: palette.control,
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: onPressed == null
                ? palette.tableBorder.withValues(alpha: 0.55)
                : palette.tableBorder,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _UsersPalette {
  final bool isDark;
  final Color panel;
  final Color header;
  final Color row;
  final Color control;
  final Color border;
  final Color tableBorder;
  final Color shadow;
  final Color textPrimary;
  final Color textMuted;
  final Color headerText;
  final Color blue;
  final Color actionBackground;

  const _UsersPalette({
    required this.isDark,
    required this.panel,
    required this.header,
    required this.row,
    required this.control,
    required this.border,
    required this.tableBorder,
    required this.shadow,
    required this.textPrimary,
    required this.textMuted,
    required this.headerText,
    required this.blue,
    required this.actionBackground,
  });

  factory _UsersPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _UsersPalette(
        isDark: true,
        panel: Color(0xCC061936),
        header: Color(0xFF0A1A35),
        row: Color(0xB30A1D3A),
        control: Color(0x99071530),
        border: Color(0x8038BDF8),
        tableBorder: Color(0x332E8BFF),
        shadow: Color(0x4D000000),
        textPrimary: Color(0xFFF8FAFC),
        textMuted: Color(0xFF9DB2D8),
        headerText: Color(0xFF91A3C2),
        blue: Color(0xFF168BFF),
        actionBackground: Colors.transparent,
      );
    }

    return const _UsersPalette(
      isDark: false,
      panel: Color(0xF7FFFFFF),
      header: Color(0xFFF8FBFF),
      row: Color(0xF7FFFFFF),
      control: Color(0xFFFFFFFF),
      border: Color(0xFFBFD8FF),
      tableBorder: Color(0xFFD8E6FF),
      shadow: Color(0x140B4AA2),
      textPrimary: Color(0xFF061942),
      textMuted: Color(0xFF365174),
      headerText: Color(0xFF597199),
      blue: Color(0xFF147BFF),
      actionBackground: Color(0xFFFFFFFF),
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
