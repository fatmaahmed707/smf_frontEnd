class MonitoredDevice {
  final String name;
  final String zone;
  final String status;
  final String lastSeen;
  final int batteryLevel;

  const MonitoredDevice({
    required this.name,
    required this.zone,
    required this.status,
    required this.lastSeen,
    required this.batteryLevel,
  });
}
