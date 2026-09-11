import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

class LoginResult {
  const LoginResult({required this.tokens, required this.user});

  final AuthTokens tokens;
  final User user;
}

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<LoginResult> login({required String username, required String password}) async {
    try {
      final res = await _client.plain.post<Map<String, dynamic>>(
        ApiConfig.loginPath,
        data: {
          'username': username,
          'password': password,
          'expiresInMins': ApiConfig.sessionMinutes,
        },
      );

      final data = res.data;
      if (data == null) {
        throw const Failure(FailureKind.server, 'The server returned an empty response.');
      }

      final tokens = AuthTokens.fromJson(data);
      if (!tokens.isValid) {
        throw const Failure(
          FailureKind.server,
          'The server did not return a valid session.',
        );
      }

      return LoginResult(tokens: tokens, user: UserModel.fromJson(data));
    } on DioException catch (e) {
      throw _mapLoginError(e);
    }
  }

  Future<User> fetchProfile() async {
    try {
      final res = await _client.authenticated.get<Map<String, dynamic>>(
        ApiConfig.profilePath,
      );
      final data = res.data;
      if (data == null) {
        throw const Failure(FailureKind.server, 'The server returned an empty profile.');
      }
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapProfileError(e);
    }
  }

  Failure _mapLoginError(DioException e) {
    if (_isConnectivity(e)) return const Failure.network();

    final status = e.response?.statusCode;
    if (status == 400 || status == 401) {
      return const Failure(FailureKind.badCredentials, 'Incorrect username or password.');
    }
    if (status != null && status >= 500) {
      return const Failure(
        FailureKind.server,
        'The server is not responding right now. Please try again shortly.',
      );
    }
    return const Failure(FailureKind.server, 'Sign in failed. Please try again.');
  }

  Failure _mapProfileError(DioException e) {
    if (_isConnectivity(e)) return const Failure.network();
    if (e.response?.statusCode == 401) return const Failure.sessionExpired();
    return const Failure(FailureKind.server, 'Could not load your profile.');
  }

  bool _isConnectivity(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => true,
    DioExceptionType.unknown => e.response == null,
    _ => false,
  };
}
