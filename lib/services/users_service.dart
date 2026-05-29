import '../models/user.dart';
import 'api_service.dart';
import 'auth_service.dart';

class UsersService {
  UsersService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<User>> getUsers() async {
    final response = await _apiService.get(
      '/users/',
      headers: await AuthService.instance.authHeaders(),
    );

    final rawData = response.data;
    final rawUsers = rawData is List
        ? rawData
        : rawData is Map<String, dynamic>
            ? rawData['users'] as List<dynamic>? ??
                rawData['items'] as List<dynamic>? ??
                rawData['content'] as List<dynamic>? ??
                const []
            : const <dynamic>[];
    return rawUsers
        .whereType<Map<String, dynamic>>()
        .map(User.fromJson)
        .toList();
  }

  Future<User> getUser(String id) async {
    final response = await _apiService.get(
      '/users/$id',
      headers: await AuthService.instance.authHeaders(),
    );

    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> createUser({
    required String username,
    required String email,
    required String password,
    required Set<String> roles,
  }) async {
    final response = await _apiService.post(
      '/users/',
      headers: await AuthService.instance.authHeaders(),
      body: {
        'username': username,
        'email': email,
        'password': password,
        'roles': roles.toList(),
      },
    );

    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> updateUser({
    required String id,
    required String username,
    required String email,
    String? password,
    required Set<String> roles,
  }) async {
    final response = await _apiService.put(
      '/users/$id',
      headers: await AuthService.instance.authHeaders(),
      body: {
        'username': username,
        'email': email,
        if (password != null) 'password': password,
        'roles': roles.toList(),
      },
    );

    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    await _apiService.delete(
      '/users/$id',
      headers: await AuthService.instance.authHeaders(),
    );
  }
}
