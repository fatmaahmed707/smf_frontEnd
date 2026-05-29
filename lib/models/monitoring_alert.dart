class MonitoringAlert {
  final String title;
  final String zone;
  final String severity;
  final String status;
  final String timeLabel;

  const MonitoringAlert({
    required this.title,
    required this.zone,
    required this.severity,
    required this.status,
    required this.timeLabel,
  });
}
