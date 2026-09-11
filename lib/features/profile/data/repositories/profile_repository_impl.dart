import '../../../../core/error/failure.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../domain/entities/profile_snapshot.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_cache_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required AuthRemoteDataSource remote,
    required ProfileCacheDataSource cache,
  }) : _remote = remote,
       _cache = cache;

  final AuthRemoteDataSource _remote;
  final ProfileCacheDataSource _cache;

  @override
  Future<ProfileSnapshot> getProfile() async {
    try {
      final user = await _remote.fetchProfile();
      await _cache.write(user);
      final cached = await _cache.read();

      return ProfileSnapshot(
        user: user,
        source: ProfileSource.network,
        cachedAt: cached?.cachedAt ?? DateTime.now(),
        cipherName: _cache.cipherName,
      );
    } on Failure catch (failure) {
      if (failure.kind == FailureKind.sessionExpired) rethrow;

      final cached = await _cache.read();
      if (cached == null) rethrow;

      return ProfileSnapshot(
        user: cached.user,
        source: ProfileSource.cache,
        cachedAt: cached.cachedAt,
        cipherName: _cache.cipherName,
      );
    }
  }
}
