import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User> login({required String username, required String password});

  Future<void> logout();

  Future<bool> hasSession();

  Stream<void> get sessionExpired;
}
