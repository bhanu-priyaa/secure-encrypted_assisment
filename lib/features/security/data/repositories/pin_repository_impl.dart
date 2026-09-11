import '../../../../core/constants/app_constants.dart';
import '../../../../core/crypto/pin_hasher.dart';
import '../../../../core/storage/secure_store.dart';
import '../../domain/repositories/pin_repository.dart';

class PinRepositoryImpl implements PinRepository {
  PinRepositoryImpl({required SecureStore secureStore, required PinHasher hasher})
    : _secure = secureStore,
      _hasher = hasher;

  final SecureStore _secure;
  final PinHasher _hasher;

  @override
  Future<bool> isPinSet() async {
    final salt = await _secure.readBytes(SecureKeys.pinSalt);
    final hash = await _secure.readBytes(SecureKeys.pinHash);
    return salt != null && hash != null;
  }

  @override
  Future<void> setPin(String pin) async {
    final derived = await _hasher.derive(pin);
    await _secure.writeBytes(SecureKeys.pinSalt, derived.salt);
    await _secure.writeBytes(SecureKeys.pinHash, derived.hash);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final salt = await _secure.readBytes(SecureKeys.pinSalt);
    final hash = await _secure.readBytes(SecureKeys.pinHash);
    if (salt == null || hash == null) return false;
    return _hasher.verify(pin: pin, salt: salt, expectedHash: hash);
  }

  @override
  Future<void> clearPin() async {
    await _secure.delete(SecureKeys.pinSalt);
    await _secure.delete(SecureKeys.pinHash);
  }
}
