import 'dart:convert';
import 'dart:io' show Platform, SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final DateTime? time;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.time,
  });
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    final host = kIsWeb
        ? 'localhost'
        : Platform.isAndroid
            ? '10.0.2.2'
            : 'localhost';

    return 'http://$host:8080/api/v1';
  }

  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, String>? headers,
    String? accessToken,
  }) {
    return _send(
      method: 'GET',
      path: path,
      headers: headers,
      accessToken: accessToken,
    );
  }

  Future<ApiResponse<dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    String? accessToken,
  }) {
    return _send(
      method: 'POST',
      path: path,
      headers: headers,
      body: body,
      accessToken: accessToken,
    );
  }

  Future<ApiResponse<dynamic>> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    String? accessToken,
  }) {
    return _send(
      method: 'PUT',
      path: path,
      headers: headers,
      body: body,
      accessToken: accessToken,
    );
  }

  Future<ApiResponse<dynamic>> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
    String? accessToken,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      headers: headers,
      body: body,
      accessToken: accessToken,
    );
  }

  Future<ApiResponse<dynamic>> _send({
    required String method,
    required String path,
    Map<String, String>? headers,
    Object? body,
    String? accessToken,
    bool hasRetriedAfterRefresh = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
      if (headers != null) ...headers,
    };

    late http.Response response;

    try {
      response = await _sendHttpRequest(
        method: method,
        uri: uri,
        headers: requestHeaders,
        body: body,
      );
    } on http.ClientException catch (error) {
      throw ApiException('Network error: ${error.message}');
    } on SocketException {
      throw const ApiException('Unable to reach backend server');
    }

    if (_shouldRefreshSession(response, path, hasRetriedAfterRefresh)) {
      final refreshed = await AuthService.instance.refreshSession();
      if (refreshed) {
        return _send(
          method: method,
          path: path,
          headers: await AuthService.instance.authHeaders(),
          body: body,
          accessToken: accessToken,
          hasRetriedAfterRefresh: true,
        );
      }
    }

    return _parseResponse(response);
  }

  Future<http.Response> _sendHttpRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) {
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'PUT':
        return _client.put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'DELETE':
        return _client.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      default:
        throw const ApiException('Unsupported HTTP method');
    }
  }

  bool _shouldRefreshSession(
    http.Response response,
    String path,
    bool hasRetriedAfterRefresh,
  ) {
    if (hasRetriedAfterRefresh) return false;
    if (response.statusCode != 401 && response.statusCode != 403) {
      return false;
    }
    return !_isAuthEndpoint(path);
  }

  bool _isAuthEndpoint(String path) {
    return path.startsWith('/auth/login') ||
        path.startsWith('/auth/google') ||
        path.startsWith('/auth/register') ||
        path.startsWith('/auth/refresh') ||
        path.startsWith('/auth/logout');
  }

  ApiResponse<dynamic> _parseResponse(http.Response response) {
    final rawBody = response.body.trim();
    final decoded = rawBody.isEmpty ? null : jsonDecode(rawBody);

    if (decoded is Map<String, dynamic> && decoded.containsKey('success')) {
      final apiResponse = ApiResponse<dynamic>(
        success: decoded['success'] == true,
        message: decoded['message']?.toString() ?? 'Request completed',
        data: decoded['data'],
        time: decoded['time'] == null
            ? null
            : DateTime.tryParse(decoded['time'].toString()),
      );

      if (response.statusCode >= 400 || !apiResponse.success) {
        throw ApiException(
          apiResponse.message,
          statusCode: response.statusCode,
        );
      }

      return apiResponse;
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        'Request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return ApiResponse<dynamic>(
      success: true,
      message: 'Request completed',
      data: decoded,
    );
  }
}