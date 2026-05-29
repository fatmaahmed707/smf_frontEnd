import '../models/monitored_device.dart';
import '../models/monitoring_alert.dart';
import '../models/user.dart';

class MockMonitoringData {
  static const User currentUser = User(
    id: '',
    name: 'Admin User',
    email: 'admin@smf.com',
    role: 'ADMIN',
    department: 'Security Operations',
  );

  static const List<MonitoringAlert> alerts = [
    MonitoringAlert(
      title: 'Unauthorized access attempt',
      zone: 'Zone B Gate 2',
      severity: 'Critical',
      status: 'Acknowledged',
      timeLabel: '2 min ago',
    ),
    MonitoringAlert(
      title: 'Camera feed unstable',
      zone: 'Warehouse North',
      severity: 'Warning',
      status: 'Investigating',
      timeLabel: '9 min ago',
    ),
    MonitoringAlert(
      title: 'Perimeter sensor offline',
      zone: 'Fence Line East',
      severity: 'High',
      status: 'Open',
      timeLabel: '14 min ago',
    ),
    MonitoringAlert(
      title: 'Routine patrol check-in',
      zone: 'Lobby Control',
      severity: 'Info',
      status: 'Closed',
      timeLabel: '21 min ago',
    ),
  ];

  static const List<MonitoredDevice> devices = [
    MonitoredDevice(
      name: 'Thermal Camera 14',
      zone: 'Zone A',
      status: 'Online',
      lastSeen: 'Just now',
      batteryLevel: 97,
    ),
    MonitoredDevice(
      name: 'Door Sensor 08',
      zone: 'Zone B',
      status: 'Warning',
      lastSeen: '1 min ago',
      batteryLevel: 28,
    ),
    MonitoredDevice(
      name: 'Radio Beacon 03',
      zone: 'Building 3',
      status: 'Online',
      lastSeen: '2 min ago',
      batteryLevel: 74,
    ),
    MonitoredDevice(
      name: 'Perimeter Node 11',
      zone: 'Fence East',
      status: 'Offline',
      lastSeen: '12 min ago',
      batteryLevel: 0,
    ),
    MonitoredDevice(
      name: 'Access Panel 02',
      zone: 'Main Lobby',
      status: 'Online',
      lastSeen: 'Just now',
      batteryLevel: 88,
    ),
  ];

  static const List<String> activities = [
    'Admin User acknowledged the Zone B incident',
    'Thermal Camera 14 completed a health check',
    'Door Sensor 08 reported low battery',
    'Patrol Team Alpha entered Building 3',
    'Perimeter Node 11 stopped sending heartbeats',
  ];
}
