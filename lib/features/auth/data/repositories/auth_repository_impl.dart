import 'dart:async';

import '../../../../core/network/token_store.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../profile/data/datasources/profile_cache_data_source.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStore tokenStore,
    required SecureStore secureStore,
    required ProfileCacheDataSource cache,
  }) : _remote = remote,
       _tokens = tokenStore,
       _secure = secureStore,
       _cache = cache;

  final AuthRemoteDataSource _remote;
  final TokenStore _tokens;
  final SecureStore _secure;
  final ProfileCacheDataSource _cache;

  final StreamController<void> _sessionExpired = StreamController<void>.broadcast();

  @override
  Stream<void> get sessionExpired => _sessionExpired.stream;

  @override
  Future<User> login({required String username, required String password}) async {
    final result = await _remote.login(username: username, password: password);
    await _tokens.save(result.tokens);
    await _cache.write(result.user);
    return result.user;
  }

  @override
  Future<bool> hasSession() => _tokens.hasSession();

  @override
  Future<void> logout() async {
    await _cache.clear();
    await _secure.wipeAll();
    await _tokens.clear();
  }

  Future<void> handleSessionExpiry() async {
    await logout();
    if (!_sessionExpired.isClosed) _sessionExpired.add(null);
  }

  Future<void> dispose() => _sessionExpired.close();
}
