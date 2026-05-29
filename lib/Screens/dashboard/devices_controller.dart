import 'package:flutter/material.dart';

import '../../models/device_record.dart';
import '../../models/smf_device.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/devices_service.dart';
import '../../services/smf_devices_service.dart';
import '../../services/users_service.dart';
import '../../services/zones_service.dart';
import '../../models/zone_summary.dart';

class DevicesController extends ChangeNotifier {
  DevicesController({
    DevicesService? devicesService,
    UsersService? usersService,
    SmfDevicesService? smfDevicesService,
    ZonesService? zonesService,
  })  : _devicesService = devicesService ?? DevicesService(),
        _usersService = usersService ?? UsersService(),
        _smfDevicesService = smfDevicesService ?? SmfDevicesService(),
        _zonesService = zonesService ?? ZonesService();

  final DevicesService _devicesService;
  final UsersService _usersService;
  final SmfDevicesService _smfDevicesService;
  final ZonesService _zonesService;

  List<DeviceRecord> _devices = const [];
  List<User> _users = const [];
  List<SmfDevice> _availableSmfDevices = const [];
  List<SmfDevice> _registrySmfDevices = const [];
  List<ZoneSummary> _zones = const [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<DeviceRecord> get devices => _devices;
  List<User> get users => _users;
  List<SmfDevice> get availableSmfDevices => _availableSmfDevices;
  List<SmfDevice> get registrySmfDevices => _registrySmfDevices;
  List<ZoneSummary> get zones => _zones;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        refreshDevices(),
        refreshRegistrationDependencies(),
      ]);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Failed to load device data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDevices() async {
    _devices = await _devicesService.getDevices();
    notifyListeners();
  }

  Future<void> refreshRegistrationDependencies() async {
    final results = await Future.wait([
      _usersService.getUsers(),
      _smfDevicesService.getUnregisteredDevices(),
      _smfDevicesService.getAllDevices(),
      _zonesService.getZones(),
    ]);

    _users = results[0] as List<User>;
    _availableSmfDevices = results[1] as List<SmfDevice>;
    _registrySmfDevices = results[2] as List<SmfDevice>;
    _zones = results[3] as List<ZoneSummary>;
    notifyListeners();
  }

  Future<DeviceRecord> fetchDevice(String id) {
    return _devicesService.getDevice(id);
  }

  Future<bool> registerDevice({
    required String smfDeviceLabel,
    required String ownerId,
    String? zoneId,
  }) async {
    return _runMutation(() async {
      await _devicesService.registerDevice(
        smfDeviceLabel: smfDeviceLabel,
        ownerId: ownerId,
        zoneId: zoneId,
      );
      await initialize();
    });
  }

  Future<bool> updateDevice({
    required String id,
    required String smfDeviceLabel,
    required String ownerId,
    String? zoneId,
  }) async {
    return _runMutation(() async {
      await _devicesService.updateDevice(
        id: id,
        smfDeviceLabel: smfDeviceLabel,
        ownerId: ownerId,
        zoneId: zoneId,
      );
      await initialize();
    });
  }

  Future<bool> deleteDevice(String id) async {
    return _runMutation(() async {
      await _devicesService.deleteDevice(id);
      await initialize();
    });
  }

  Future<bool> _runMutation(Future<void> Function() task) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await task();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'The device request failed.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
