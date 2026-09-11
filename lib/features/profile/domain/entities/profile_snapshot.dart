import '../../../auth/domain/entities/user.dart';

enum ProfileSource { network, cache }

class ProfileSnapshot {
  const ProfileSnapshot({
    required this.user,
    required this.source,
    required this.cachedAt,
    required this.cipherName,
  });

  final User user;
  final ProfileSource source;
  final DateTime cachedAt;
  final String cipherName;

  bool get isOffline => source == ProfileSource.cache;
}
