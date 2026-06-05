class User {
  final String id;
  final String name;
  final String email;
  final String? role;
  final String? phone;
  final String? department;
  final String? location;
  final String? shift;
  final String? manager;
  final String? provider;
  final String? pictureUrl;
  final List<String> roles;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.phone,
    this.department,
    this.location,
    this.shift,
    this.manager,
    this.provider,
    this.pictureUrl,
    this.roles = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};
    final mergedJson = <String, dynamic>{...nestedUser, ...json};

    final rawRoles = mergedJson['roles'] ?? mergedJson['roleNames'];
    final parsedRoles = rawRoles is List
        ? rawRoles
            .map((role) => role.toString().replaceFirst(RegExp(r'^ROLE_'), ''))
            .where((role) => role.trim().isNotEmpty)
            .toList()
        : const <String>[];

    String pickValue(List<String> keys) {
      for (final key in keys) {
        final value = mergedJson[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    final normalizedRole = pickValue(['role', 'userRole', 'roleName']);

    return User(
      id: pickValue(['id', 'userId', 'user_id']),
      name: pickValue([
        'fullName',
        'displayName',
        'full_name',
        'full_name_en',
        'fullNameEn',
        'username',
        'userName',
        'name',
      ]),
      email: pickValue(['email', 'emailAddress', 'email_address']),
      role: normalizedRole.isNotEmpty
          ? normalizedRole.replaceFirst(RegExp(r'^ROLE_'), '')
          : (parsedRoles.isNotEmpty ? parsedRoles.first : null),
      phone: pickValue(['phone', 'phoneNumber', 'phone_number']),
      department: pickValue(['department', 'company']),
      location: pickValue(['location', 'workLocation', 'work_location']),
      shift: pickValue(['shift', 'workShift']),
      manager: pickValue(['manager', 'managerName']),
      provider: pickValue(['provider', 'authProvider']),
      pictureUrl: pickValue(['pictureUrl', 'avatarUrl', 'photoUrl']),
      roles: parsedRoles,
    );
  }
}
