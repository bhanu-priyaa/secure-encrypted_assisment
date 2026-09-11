import '../../../../core/storage/prefs_store.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._prefs);

  final PrefsStore _prefs;

  @override
  bool get introSeen => _prefs.introSeen;

  @override
  Future<void> markIntroSeen() => _prefs.markIntroSeen();
}
