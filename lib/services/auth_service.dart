import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/auth_session.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  final ApiService _apiService = ApiService();

  String? _accessToken;
  String? _refreshToken;
  String? _userId;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  bool get isAuthenticated =>
      _accessToken != null &&
      _accessToken!.isNotEmpty &&
      _refreshToken != null &&
      _refreshToken!.isNotEmpty;

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _apiService.post(
      '/auth/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    final session = AuthSession.fromJson(
      response.data as Map<String, dynamic>,
    );
    await _persistSession(session);
    return session;
  }

  Future<AuthSession> authenticateWithGoogleIdToken({
    required String idToken,
  }) async {
    final response = await _apiService.post(
      '/auth/google',
      body: {
        'idToken': idToken,
      },
    );

    final session = AuthSession.fromJson(
      response.data as Map<String, dynamic>,
    );
    await _persistSession(session);
    return session;
  }

  Future<void> logout() async {
    final currentRefreshToken = _refreshToken;
    try {
      if (currentRefreshToken != null && currentRefreshToken.isNotEmpty) {
        await _apiService.post(
          '/auth/logout',
          body: {
            'refreshToken': currentRefreshToken,
          },
        );
      }
    } finally {
      await clearSession();
    }
  }

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    _userId = prefs.getString(_userIdKey);

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      await clearSession();
      return false;
    }

    return refreshSession();
  }

  Future<bool> refreshSession() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      await clearSession();
      return false;
    }

    try {
      final response = await _apiService.post(
        '/auth/refresh',
        body: {
          'refreshToken': _refreshToken,
        },
      );

      final session = AuthSession.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _persistSession(session);
      return true;
    } on ApiException {
      await clearSession();
      return false;
    }
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
  }

  Future<Map<String, String>> authHeaders() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw const ApiException('No active session');
    }

    return {
      'Authorization': 'Bearer $_accessToken',
    };
  }

  User? userFromAccessToken() {
    final claims = _decodeJwtClaims(_accessToken);
    if (claims == null) return null;

    final rawRoles = claims['roles'];
    final roles = rawRoles is List
        ? rawRoles.map((role) => role.toString()).toList()
        : <String>[];
    final email = (claims['email'] ?? claims['emailAddress'] ?? '').toString();
    final name = (claims['displayName'] ??
            claims['fullName'] ??
            claims['full_name'] ??
            claims['username'] ??
            claims['name'] ??
            email.split('@').first)
        .toString();

    return User(
      id: (claims['sub'] ?? claims['id'] ?? _userId ?? '').toString(),
      name: name,
      email: email,
      role: claims['role']?.toString() ??
          (roles.isNotEmpty ? roles.first : null),
      roles: roles,
    );
  }

  Map<String, dynamic>? _decodeJwtClaims(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final claims = jsonDecode(decoded);
      return claims is Map<String, dynamic> ? claims : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSession(AuthSession session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _userId = session.userId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, session.accessToken);
    await prefs.setString(_refreshTokenKey, session.refreshToken);
    await prefs.setString(_userIdKey, session.userId);
  }
}
