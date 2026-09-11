abstract interface class PinRepository {
  Future<bool> isPinSet();

  Future<void> setPin(String pin);

  Future<bool> verifyPin(String pin);

  Future<void> clearPin();
}
