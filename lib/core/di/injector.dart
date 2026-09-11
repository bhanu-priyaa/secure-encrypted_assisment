import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/profile/data/datasources/profile_cache_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/security/data/repositories/pin_repository_impl.dart';
import '../../features/security/domain/repositories/pin_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../crypto/crypto_service.dart';
import '../crypto/pin_hasher.dart';
import '../network/api_client.dart';
import '../network/token_store.dart';
import '../storage/prefs_store.dart';
import '../storage/secure_store.dart';

class Injector {
  Injector._({
    required this.authRepository,
    required this.profileRepository,
    required this.pinRepository,
    required this.settingsRepository,
    required this.onboardingRepository,
  });

  final AuthRepositoryImpl authRepository;
  final ProfileRepository profileRepository;
  final PinRepository pinRepository;
  final SettingsRepository settingsRepository;
  final OnboardingRepository onboardingRepository;

  static Future<Injector> create() async {
    final prefs = await PrefsStore.create();
    final secureStore = SecureStore();
    final crypto = CryptoService();

    final tokenStore = TokenStore(secureStore);
    final cache = ProfileCacheDataSource(secureStore: secureStore, crypto: crypto);

    late final AuthRepositoryImpl authRepository;

    final apiClient = ApiClient(
      tokenStore: tokenStore,
      onSessionExpired: () => authRepository.handleSessionExpiry(),
    );

    final remote = AuthRemoteDataSource(apiClient);

    authRepository = AuthRepositoryImpl(
      remote: remote,
      tokenStore: tokenStore,
      secureStore: secureStore,
      cache: cache,
    );

    return Injector._(
      authRepository: authRepository,
      profileRepository: ProfileRepositoryImpl(remote: remote, cache: cache),
      pinRepository: PinRepositoryImpl(secureStore: secureStore, hasher: PinHasher()),
      settingsRepository: SettingsRepositoryImpl(prefs),
      onboardingRepository: OnboardingRepositoryImpl(prefs),
    );
  }
}
