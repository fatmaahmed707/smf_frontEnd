class SmfDevice {
  final String id;
  final String macAddress;
  final String label;
  final bool isRegistered;
  final DateTime? createdAt;

  const SmfDevice({
    required this.id,
    required this.macAddress,
    required this.label,
    required this.isRegistered,
    required this.createdAt,
  });

  factory SmfDevice.fromJson(Map<String, dynamic> json) {
    return SmfDevice(
      id: (json['id'] ?? '').toString(),
      macAddress: (json['macAddress'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      isRegistered: json['registered'] == true || json['isRegistered'] == true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
