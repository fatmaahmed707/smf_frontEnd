class RoleSummary {
  final int id;
  final String roleName;

  const RoleSummary({
    required this.id,
    required this.roleName,
  });

  factory RoleSummary.fromJson(Map<String, dynamic> json) {
    return RoleSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      roleName: (json['roleName'] ?? '').toString(),
    );
  }
}
