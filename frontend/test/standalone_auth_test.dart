import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/api_constant.dart';
import 'package:frontend/core/constants/api_service.dart';
import 'package:frontend/core/storage/tocken_storage.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

void assertEqual(dynamic actual, dynamic expected, String message) {
  if (actual != expected) {
    throw Exception('FAILED: $message. Expected: $expected, Actual: $actual');
  }
}

void assertTrue(bool condition, String message) {
  if (!condition) {
    throw Exception('FAILED: $message');
  }
}

Future<void> main() async {
  print('=== Running Authentication & Token Refresh Test Suite ===');

  SharedPreferences.setMockInitialValues({
    'session_user_id': 'user_123',
    'session_name': 'Test User',
    'session_username': 'testuser',
    'session_email': 'test@example.com',
    'session_access_token': 'expired_access_token',
    'session_refresh_token': 'valid_refresh_token',
  });
  final prefs = await SharedPreferences.getInstance();
  final sessionLocalDataSource = SessionLocalDataSource(prefs: prefs);

  // ── TEST 1: SessionLocalDataSource token storage & retrieval ──
  print('\n[Test 1] Testing SessionLocalDataSource storage & retrieval...');
  final initialUser = sessionLocalDataSource.getSession();
  assertTrue(initialUser != null, 'Initial user session must not be null');
  assertEqual(initialUser!.id, 'user_123', 'User ID must match');
  assertEqual(initialUser.token, 'expired_access_token', 'Access token must match');
  assertEqual(initialUser.refreshToken, 'valid_refresh_token', 'Refresh token must match');
  assertEqual(sessionLocalDataSource.getToken(), 'expired_access_token', 'getToken() must return access token');
  assertEqual(sessionLocalDataSource.getRefreshToken(), 'valid_refresh_token', 'getRefreshToken() must return refresh token');
  print('✅ [Test 1 Passed]');

  // ── TEST 2: Automatic Token Refresh & Request Retry on 401 ──
  print('\n[Test 2] Testing automatic token refresh and request retry on 401...');
  int requestCount = 0;
  int refreshCount = 0;

  final mockClient = MockClient((request) async {
    if (request.url.path == ApiConstants.refreshEndpoint) {
      refreshCount++;
      final body = jsonDecode(request.body);
      assertEqual(body['refreshToken'], 'valid_refresh_token', 'Must send valid refresh token to refresh endpoint');
      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Token refreshed successfully',
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
      if (authHeader == 'Bearer expired_access_token') {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Not authorized, token invalid or expired'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }
      if (authHeader == 'Bearer fresh_access_token') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Meetings retrieved',
            'data': {'meetings': [{'id': 'm1', 'name': 'Team Sync'}]},
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
  assertTrue(result['success'] == true, 'Result success must be true');
  assertEqual(refreshCount, 1, 'Exactly one refresh request should have been dispatched');
  assertEqual(requestCount, 2, 'Two endpoint requests should occur (1st failed + 2nd retried)');
  assertEqual(sessionLocalDataSource.getToken(), 'fresh_access_token', 'Saved access token must be updated');
  assertEqual(sessionLocalDataSource.getRefreshToken(), 'fresh_rotated_refresh_token', 'Saved refresh token must be rotated');
  print('✅ [Test 2 Passed]');

  // ── TEST 3: Concurrent 401 Requests Mutex / Lock ──
  print('\n[Test 3] Testing concurrency: 3 simultaneous 401 requests trigger only 1 refresh...');
  int concurrentRefreshCount = 0;

  // Set tokens back to an expired state
  await sessionLocalDataSource.saveTokens(
    accessToken: 'old_expired_token',
    refreshToken: 'concurrent_refresh_token',
  );

  final concurrentMockClient = MockClient((request) async {
    if (request.url.path == ApiConstants.refreshEndpoint) {
      concurrentRefreshCount++;
      // Simulate network delay during refresh
      await Future.delayed(const Duration(milliseconds: 30));
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'accessToken': 'concurrent_fresh_access_token',
            'refreshToken': 'concurrent_fresh_refresh_token',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (request.url.path == ApiConstants.meetingsEndpoint) {
      final auth = request.headers['Authorization'];
      if (auth == 'Bearer old_expired_token') {
        return http.Response(
          jsonEncode({'message': 'Not authorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }
      if (auth == 'Bearer concurrent_fresh_access_token') {
        return http.Response(
          jsonEncode({'success': true, 'data': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
    }

    return http.Response('Not found', 404);
  });

  final concurrentApiService = ApiService(
    sessionLocalDataSource: sessionLocalDataSource,
    client: concurrentMockClient,
  );

  // Dispatch 3 concurrent requests simultaneously
  final future1 = concurrentApiService.get(ApiConstants.meetingsEndpoint);
  final future2 = concurrentApiService.get(ApiConstants.meetingsEndpoint);
  final future3 = concurrentApiService.post(ApiConstants.meetingsEndpoint, {'name': 'Space'});

  final concurrentResults = await Future.wait([future1, future2, future3]);
  assertEqual(concurrentResults.length, 3, 'All 3 requests must complete');
  for (final res in concurrentResults) {
    assertTrue(res['success'] == true, 'Each concurrent request must succeed after token refresh');
  }
  assertEqual(concurrentRefreshCount, 1, 'Only 1 refresh request must be sent despite 3 concurrent 401s');
  assertEqual(sessionLocalDataSource.getToken(), 'concurrent_fresh_access_token', 'Access token updated');
  print('✅ [Test 3 Passed]');

  // ── TEST 4: Expired / Invalid Refresh Token Clears Session & Calls onSessionExpired ──
  print('\n[Test 4] Testing expired refresh token handling & session cleanup...');
  bool sessionExpiredTriggered = false;

  await sessionLocalDataSource.saveTokens(
    accessToken: 'expired_access_token_again',
    refreshToken: 'definitely_expired_refresh_token',
  );

  final expiredMockClient = MockClient((request) async {
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

  final expiredApiService = ApiService(
    sessionLocalDataSource: sessionLocalDataSource,
    client: expiredMockClient,
    onSessionExpired: () {
      sessionExpiredTriggered = true;
    },
  );

  bool exceptionThrown = false;
  try {
    await expiredApiService.get(ApiConstants.meetingsEndpoint);
  } catch (e) {
    exceptionThrown = true;
    assertTrue(e.toString().contains('Session expired'), 'Exception must indicate session expiration');
  }

  assertTrue(exceptionThrown, 'Should throw session expired exception');
  assertTrue(sessionExpiredTriggered, 'onSessionExpired callback must be invoked');
  assertTrue(sessionLocalDataSource.getSession() == null, 'Session must be cleared from storage');
  assertTrue(sessionLocalDataSource.getToken() == null, 'Token must be removed from storage');
  print('✅ [Test 4 Passed]');

  // ── TEST 5: Temporary Network Outage Does NOT Clear Session Or Logout ──
  print('\n[Test 5] Testing temporary network error resilience...');
  // Restore a valid session
  await sessionLocalDataSource.saveSession(const UserEntity(
    id: 'user_123',
    name: 'Persistent User',
    username: 'persist',
    email: 'persist@example.com',
    token: 'saved_access_token',
    refreshToken: 'saved_refresh_token',
  ));

  bool sessionExpiredCalledOnNetworkError = false;

  final networkErrorMockClient = MockClient((request) async {
    throw const SocketException('Network connection failed');
  });

  final networkErrorApiService = ApiService(
    sessionLocalDataSource: sessionLocalDataSource,
    client: networkErrorMockClient,
    onSessionExpired: () {
      sessionExpiredCalledOnNetworkError = true;
    },
  );

  bool networkExceptionCaught = false;
  try {
    await networkErrorApiService.get(ApiConstants.meetingsEndpoint);
  } catch (e) {
    networkExceptionCaught = true;
    assertTrue(e.toString().contains('Unable to connect'), 'Must format network error message user-friendly');
  }

  assertTrue(networkExceptionCaught, 'Must catch network exception');
  assertTrue(!sessionExpiredCalledOnNetworkError, 'Must NOT trigger onSessionExpired on network outage');
  assertTrue(sessionLocalDataSource.getSession() != null, 'Must NOT wipe session on network outage');
  assertEqual(sessionLocalDataSource.getToken(), 'saved_access_token', 'Saved token must remain intact');
  print('✅ [Test 5 Passed]');

  print('\n🎉 ALL 5 AUTHENTICATION & REFRESH TOKEN TESTS PASSED PERFECTLY! 🎉\n');
}
