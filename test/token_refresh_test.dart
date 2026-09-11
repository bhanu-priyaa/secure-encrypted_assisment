import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iboss_assessment/core/constants/app_constants.dart';
import 'package:iboss_assessment/core/network/api_client.dart';
import 'package:iboss_assessment/core/network/auth_interceptor.dart';
import 'package:iboss_assessment/core/network/auth_tokens.dart';
import 'package:iboss_assessment/core/network/token_store.dart';
import 'package:iboss_assessment/core/storage/secure_store.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  final List<String> requestedPaths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requestedPaths.add(options.path);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late _MockSecureStorage storage;
  late TokenStore tokenStore;

  setUp(() async {
    storage = _MockSecureStorage();
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

    tokenStore = TokenStore(SecureStore(storage: storage));
    await tokenStore.save(
      const AuthTokens(accessToken: 'expired-token', refreshToken: 'refresh-token'),
    );
  });

  test('a single 401 triggers exactly one refresh and one retry', () async {
    var sessionExpiredCalls = 0;

    final client = ApiClient(
      tokenStore: tokenStore,
      onSessionExpired: () async => sessionExpiredCalls++,
    );

    final authorizationHeaders = <String?>[];

    final authenticatedAdapter = _RecordingAdapter((options) async {
      authorizationHeaders.add(options.headers['Authorization'] as String?);

      final isFirstAttempt =
          options.extra[AuthInterceptor.retriedFlag] != true;

      if (isFirstAttempt) {
        return _json({'message': 'Token expired'}, 401);
      }
      return _json({'id': 1, 'username': 'emilys'}, 200);
    });

    final refreshAdapter = _RecordingAdapter((options) async {
      return _json({
        'accessToken': 'fresh-token',
        'refreshToken': 'fresh-refresh-token',
      }, 200);
    });

    client.authenticated.httpClientAdapter = authenticatedAdapter;
    client.plain.httpClientAdapter = refreshAdapter;

    final response = await client.authenticated.get<Map<String, dynamic>>(
      ApiConfig.profilePath,
    );

    expect(response.statusCode, 200);
    expect(response.data?['username'], 'emilys');

    expect(client.interceptor.refreshCallCount, 1);
    expect(refreshAdapter.requestedPaths, [ApiConfig.refreshPath]);

    expect(authenticatedAdapter.requestedPaths,
        [ApiConfig.profilePath, ApiConfig.profilePath]);

    expect(authorizationHeaders,
        ['Bearer expired-token', 'Bearer fresh-token']);

    expect(tokenStore.accessToken, 'fresh-token');
    expect(sessionExpiredCalls, 0);
  });
}
