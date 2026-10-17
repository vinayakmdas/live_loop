import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_constant.dart';
import '../storage/tocken_storage.dart';

class ApiService {
  final SessionLocalDataSource? sessionLocalDataSource;
  final http.Client? client;
  VoidCallback? onSessionExpired;

  // Single in-flight refresh completer to prevent race conditions from concurrent requests
  Completer<String?>? _refreshCompleter;

  ApiService({
    this.sessionLocalDataSource,
    this.client,
    this.onSessionExpired,
  });

  Future<http.Response> _httpGet(Uri url, {Map<String, String>? headers}) {
    if (client != null) {
      return client!.get(url, headers: headers);
    }
    return http.get(url, headers: headers);
  }

  Future<http.Response> _httpPost(Uri url, {Map<String, String>? headers, Object? body}) {
    if (client != null) {
      return client!.post(url, headers: headers, body: body);
    }
    return http.post(url, headers: headers, body: body);
  }

  Map<String, String> _buildHeaders({
    Map<String, String>? customHeaders,
    String? token,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?customHeaders,
    };

    final effectiveToken = token ?? sessionLocalDataSource?.getToken();
    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveToken';
    }

    return headers;
  }

  /// Automatically refreshes the access token using the stored refresh token.
  /// If multiple requests hit 401 at the same time, this mutex ensures only
  /// a single refresh call is dispatched, preventing token rotation conflicts.
  Future<String?> _refreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final refreshToken = sessionLocalDataSource?.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(null);
        return null;
      }

      final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.refreshEndpoint);
      final response = await _httpPost(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final tokenData = data['data'] ?? data;
        final newAccessToken = tokenData['accessToken']?.toString();
        final newRefreshToken = tokenData['refreshToken']?.toString();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await sessionLocalDataSource?.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          completer.complete(newAccessToken);
          return newAccessToken;
        }
      }

      // Backend rejected the refresh token (expired, revoked, or invalid)
      if (response.statusCode == 401 || response.statusCode == 400) {
        await sessionLocalDataSource?.clearSession();
        onSessionExpired?.call();
      }

      completer.complete(null);
      return null;
    } on SocketException {
      // Temporary network outage: do NOT clear session or log out
      completer.complete(null);
      rethrow;
    } on TimeoutException {
      // Temporary timeout: do NOT clear session or log out
      completer.complete(null);
      rethrow;
    } catch (e) {
      completer.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  bool _isAuthEndpoint(String endpoint) {
    return endpoint == ApiConstants.loginEndpoint ||
        endpoint == ApiConstants.registerEndpoint ||
        endpoint == '/api/auth/google' ||
        endpoint == '/api/auth/forgot-password' ||
        endpoint == '/api/auth/reset-password' ||
        endpoint == ApiConstants.refreshEndpoint;
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    bool isRetry = false,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.baseUrl + endpoint);

      final response = await _httpGet(
        url,
        headers: _buildHeaders(customHeaders: headers, token: token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      }

      // 401 Unauthorized handling
      if (response.statusCode == 401) {
        if (!_isAuthEndpoint(endpoint) && !isRetry) {
          final newAccessToken = await _refreshToken();
          if (newAccessToken != null) {
            // Retry the original request with the fresh token
            return get(
              endpoint,
              headers: headers,
              token: newAccessToken,
              isRetry: true,
            );
          }
        }

        if (!_isAuthEndpoint(endpoint)) {
          await sessionLocalDataSource?.clearSession();
          onSessionExpired?.call();
          throw 'Session expired. Please log in again.';
        }
      }

      final data = jsonDecode(response.body);
      throw data["message"] ?? "An error occurred (Status ${response.statusCode})";
    } on SocketException {
      throw "Unable to connect to the server. Please check your connection or server.";
    } on TimeoutException {
      throw "Connection timed out. Please check if the backend server is running.";
    } on FormatException {
      throw "Invalid response format from server.";
    } catch (e) {
      if (e is String) rethrow;
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    String? token,
    bool isRetry = false,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.baseUrl + endpoint);

      final response = await _httpPost(
        url,
        headers: _buildHeaders(customHeaders: headers, token: token),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      }

      // 401 Unauthorized handling
      if (response.statusCode == 401) {
        if (!_isAuthEndpoint(endpoint) && !isRetry) {
          final newAccessToken = await _refreshToken();
          if (newAccessToken != null) {
            // Retry the original request with the fresh token
            return post(
              endpoint,
              body,
              headers: headers,
              token: newAccessToken,
              isRetry: true,
            );
          }
        }

        if (!_isAuthEndpoint(endpoint)) {
          await sessionLocalDataSource?.clearSession();
          onSessionExpired?.call();
          throw 'Session expired. Please log in again.';
        }
      }

      final data = jsonDecode(response.body);
      throw data["message"] ?? "An error occurred (Status ${response.statusCode})";
    } on SocketException {
      throw "Unable to connect to the server. Please check your connection or server.";
    } on TimeoutException {
      throw "Connection timed out. Please check if the backend server is running.";
    } on FormatException {
      throw "Invalid response format from server.";
    } catch (e) {
      if (e is String) rethrow;
      throw e.toString();
    }
  }
}
