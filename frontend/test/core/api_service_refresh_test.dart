import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/api_constant.dart';
import 'package:frontend/core/constants/api_service.dart';
import 'package:frontend/core/storage/tocken_storage.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionLocalDataSource sessionLocalDataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'session_user_id': 'user_123',
      'session_name': 'Test User',
      'session_username': 'testuser',
      'session_email': 'test@example.com',
      'session_access_token': 'expired_access_token',
      'session_refresh_token': 'valid_refresh_token',
    });
    final prefs = await SharedPreferences.getInstance();
    sessionLocalDataSource = SessionLocalDataSource(prefs: prefs);
  });

  group('SessionLocalDataSource Tests', () {
    test('Stores and retrieves user session with both tokens correctly', () async {
      final user = sessionLocalDataSource.getSession();
      expect(user, isNotNull);
      expect(user!.id, 'user_123');
      expect(user.token, 'expired_access_token');
      expect(user.refreshToken, 'valid_refresh_token');

      // Update tokens
      await sessionLocalDataSource.saveTokens(
        accessToken: 'new_access_token_123',
        refreshToken: 'new_refresh_token_456',
      );

      expect(sessionLocalDataSource.getToken(), 'new_access_token_123');
      expect(sessionLocalDataSource.getRefreshToken(), 'new_refresh_token_456');

      // Clear session
      await sessionLocalDataSource.clearSession();
      expect(sessionLocalDataSource.getSession(), isNull);
      expect(sessionLocalDataSource.getToken(), isNull);
      expect(sessionLocalDataSource.getRefreshToken(), isNull);
    });
  });

  group('ApiService Automatic Token Refresh Tests', () {
    test('Refreshes token on 401 and retries the original request successfully', () async {
      int requestCount = 0;
      int refreshCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path == ApiConstants.refreshEndpoint) {
          refreshCount++;
          final body = jsonDecode(request.body);
          expect(body['refreshToken'], 'valid_refresh_token');

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'fresh_access_token',
                'refreshToken': 'fresh_rotated_refresh_token',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == ApiConstants.meetingsEndpoint) {
          requestCount++;
          final authHeader = request.headers['Authorization'];

          // First attempt sends expired token -> return 401
          if (authHeader == 'Bearer expired_access_token') {
            return http.Response(
              jsonEncode({'success': false, 'message': 'Not authorized, token invalid or expired'}),
              401,
              headers: {'content-type': 'application/json'},
            );
          }

          // Retried attempt with fresh token -> return 200
          if (authHeader == 'Bearer fresh_access_token') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'meetings': []},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }

        return http.Response('Not found', 404);
      });

      final apiService = ApiService(
        sessionLocalDataSource: sessionLocalDataSource,
        client: mockClient,
      );

      final result = await apiService.get(ApiConstants.meetingsEndpoint);

      expect(result['success'], isTrue);
      expect(refreshCount, 1);
      expect(requestCount, 2); // Initial failed attempt + retried successful attempt
      expect(sessionLocalDataSource.getToken(), 'fresh_access_token');
      expect(sessionLocalDataSource.getRefreshToken(), 'fresh_rotated_refresh_token');
    });

    test('Prevents race conditions: Multiple concurrent requests dispatch only 1 refresh call', () async {
      int refreshCallCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path == ApiConstants.refreshEndpoint) {
          refreshCallCount++;
          // Simulate network latency for refresh
          await Future.delayed(const Duration(milliseconds: 50));
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'concurrent_fresh_token',
                'refreshToken': 'concurrent_rotated_refresh',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == ApiConstants.meetingsEndpoint) {
          final auth = request.headers['Authorization'];
          if (auth == 'Bearer expired_access_token') {
            return http.Response(
              jsonEncode({'message': 'Not authorized'}),
              401,
              headers: {'content-type': 'application/json'},
            );
          }
          if (auth == 'Bearer concurrent_fresh_token') {
            return http.Response(
              jsonEncode({'success': true, 'data': 'ok'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }

        return http.Response('Not found', 404);
      });

      final apiService = ApiService(
        sessionLocalDataSource: sessionLocalDataSource,
        client: mockClient,
      );

      // Launch 3 simultaneous requests
      final future1 = apiService.get(ApiConstants.meetingsEndpoint);
      final future2 = apiService.get(ApiConstants.meetingsEndpoint);
      final future3 = apiService.post(ApiConstants.meetingsEndpoint, {'name': 'test'});

      final results = await Future.wait([future1, future2, future3]);

      expect(results.length, 3);
      for (final res in results) {
        expect(res['success'], isTrue);
      }

      // Crucial: Only ONE refresh call was made despite 3 concurrent 401s!
      expect(refreshCallCount, 1);
      expect(sessionLocalDataSource.getToken(), 'concurrent_fresh_token');
    });

    test('When refresh token is expired/invalid, clears session and triggers onSessionExpired', () async {
      bool sessionExpiredCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == ApiConstants.refreshEndpoint) {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Refresh token is invalid or expired'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == ApiConstants.meetingsEndpoint) {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Not authorized'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not found', 404);
      });

      final apiService = ApiService(
        sessionLocalDataSource: sessionLocalDataSource,
        client: mockClient,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      expect(
        () => apiService.get(ApiConstants.meetingsEndpoint),
        throwsA(contains('Session expired')),
      );

      // Wait a moment for async completion
      await Future.delayed(const Duration(milliseconds: 20));

      expect(sessionExpiredCalled, isTrue);
      expect(sessionLocalDataSource.getSession(), isNull);
      expect(sessionLocalDataSource.getToken(), isNull);
    });

    test('Temporary network outage during normal requests does NOT log out or clear session', () async {
      bool sessionExpiredCalled = false;

      final mockClient = MockClient((request) async {
        throw const SocketException('No route to host');
      });

      final apiService = ApiService(
        sessionLocalDataSource: sessionLocalDataSource,
        client: mockClient,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      expect(
        () => apiService.get(ApiConstants.meetingsEndpoint),
        throwsA(contains('Unable to connect')),
      );

      await Future.delayed(const Duration(milliseconds: 20));

      // User session must NOT be cleared on network failure!
      expect(sessionExpiredCalled, isFalse);
      expect(sessionLocalDataSource.getSession(), isNotNull);
      expect(sessionLocalDataSource.getToken(), 'expired_access_token');
    });
  });
}
