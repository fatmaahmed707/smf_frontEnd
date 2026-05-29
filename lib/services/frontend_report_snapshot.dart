import 'package:smf_main/models/device_record.dart';
import 'package:smf_main/models/smf_device.dart';
import 'package:smf_main/models/user.dart';
import 'package:smf_main/models/worker_profile.dart';

class FrontendReportSnapshot {
  FrontendReportSnapshot._();

  static final FrontendReportSnapshot instance = FrontendReportSnapshot._();

  List<User> users = const [];
  List<DeviceRecord> assignedDevices = const [];
  List<SmfDevice> smfDevices = const [];
  List<SmfDevice> availableSmfDevices = const [];
  final Map<String, WorkerProfile> workerProfilesByUserId = {};
  String usersSearchQuery = '';
  int usersCurrentPage = 1;
  DateTime? usersLoadedAt;

  void updateUsersManagement({
    required List<User> users,
    required List<DeviceRecord> assignedDevices,
    required List<SmfDevice> smfDevices,
    required List<SmfDevice> availableSmfDevices,
    required String searchQuery,
    required int currentPage,
  }) {
    this.users = List.unmodifiable(users);
    this.assignedDevices = List.unmodifiable(assignedDevices);
    this.smfDevices = List.unmodifiable(smfDevices);
    this.availableSmfDevices = List.unmodifiable(availableSmfDevices);
    usersSearchQuery = searchQuery;
    usersCurrentPage = currentPage;
    usersLoadedAt = DateTime.now();
  }

  void updateUsersViewState({
    required String searchQuery,
    required int currentPage,
  }) {
    usersSearchQuery = searchQuery;
    usersCurrentPage = currentPage;
  }

  void cacheWorkerProfile(String userId, WorkerProfile profile) {
    workerProfilesByUserId[userId] = profile;
  }

  void removeWorkerProfile(String userId) {
    workerProfilesByUserId.remove(userId);
  }
}
