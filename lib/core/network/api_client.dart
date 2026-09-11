import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'auth_interceptor.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    required TokenStore tokenStore,
    required Future<void> Function() onSessionExpired,
  }) {
    _authenticated = Dio(_options);
    _plain = Dio(_options);

    interceptor = AuthInterceptor(
      tokenStore: tokenStore,
      refreshDio: _plain,
      retryDio: _authenticated,
      onSessionExpired: onSessionExpired,
    );
    _authenticated.interceptors.add(interceptor);
  }

  static BaseOptions get _options => BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    contentType: Headers.jsonContentType,
    validateStatus: (status) => status != null && status >= 200 && status < 300,
  );

  late final Dio _authenticated;
  late final Dio _plain;
  late final AuthInterceptor interceptor;

  Dio get authenticated => _authenticated;

  Dio get plain => _plain;
}
