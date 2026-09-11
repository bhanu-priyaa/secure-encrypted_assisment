import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'auth_tokens.dart';
import 'token_store.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required Dio refreshDio,
    required Dio retryDio,
    required Future<void> Function() onSessionExpired,
  }) : _tokens = tokenStore,
       _refreshDio = refreshDio,
       _retryDio = retryDio,
       _onSessionExpired = onSessionExpired;

  static const retriedFlag = 'auth_retried';

  final TokenStore _tokens;
  final Dio _refreshDio;
  final Dio _retryDio;
  final Future<void> Function() _onSessionExpired;

  Future<bool>? _inFlightRefresh;

  int refreshCallCount = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[retriedFlag] == true;

    if (!isUnauthorized || alreadyRetried) {
      return handler.next(err);
    }

    final refreshed = await _refreshSingleFlight();
    if (!refreshed) {
      await _onSessionExpired();
      return handler.next(err);
    }

    try {
      handler.resolve(await _retry(err.requestOptions));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _refreshSingleFlight() {
    return _inFlightRefresh ??= _performRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = _tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    refreshCallCount++;
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        ApiConfig.refreshPath,
        data: {'refreshToken': refreshToken, 'expiresInMins': ApiConfig.sessionMinutes},
      );

      final data = res.data;
      if (data == null) return false;

      final tokens = AuthTokens.fromJson(data);
      if (!tokens.isValid) return false;

      await _tokens.save(tokens);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options) {
    final token = _tokens.accessToken;
    return _retryDio.fetch<dynamic>(
      options.copyWith(
        extra: {...options.extra, retriedFlag: true},
        headers: {
          ...options.headers,
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}
