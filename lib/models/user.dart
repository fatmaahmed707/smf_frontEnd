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
    final rawRoles = json['roles'];
    final parsedRoles = rawRoles is List
        ? rawRoles.map((role) => role.toString()).toList()
        : const <String>[];

    return User(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      name: (json['fullName'] ?? json['username'] ?? json['name'] ?? '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      role: json['role']?.toString() ??
          (parsedRoles.isNotEmpty ? parsedRoles.first : null),
      phone: json['phone']?.toString(),
      department: json['department']?.toString(),
      location: json['location']?.toString(),
      shift: json['shift']?.toString(),
      manager: json['manager']?.toString(),
      provider: json['provider']?.toString(),
      pictureUrl: json['pictureUrl']?.toString(),
      roles: parsedRoles,
    );
  }
}
