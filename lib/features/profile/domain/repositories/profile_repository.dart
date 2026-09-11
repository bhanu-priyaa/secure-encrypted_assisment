import '../entities/profile_snapshot.dart';

abstract interface class ProfileRepository {
  Future<ProfileSnapshot> getProfile();
}
