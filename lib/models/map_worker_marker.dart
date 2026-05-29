class MapWorkerMarker {
  final String id;
  final String name;
  final String status;
  final String? avatarUrl;
  final String? role;
  final String? locationLabel;
  final double offsetDx;
  final double offsetDy;
  final String? deviceLabel;

  const MapWorkerMarker({
    required this.id,
    required this.name,
    required this.status,
    required this.offsetDx,
    required this.offsetDy,
    this.avatarUrl,
    this.role,
    this.locationLabel,
    this.deviceLabel,
  });
}
