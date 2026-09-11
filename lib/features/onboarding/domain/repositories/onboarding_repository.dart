abstract interface class OnboardingRepository {
  bool get introSeen;

  Future<void> markIntroSeen();
}
