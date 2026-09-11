import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
          );

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<Uint8List?> readBytes(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    try {
      return base64Decode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> writeBytes(String key, Uint8List value) =>
      _storage.write(key: key, value: base64Encode(value));

  Future<void> wipeAll() async {
    await Future.wait([
      _storage.delete(key: SecureKeys.accessToken),
      _storage.delete(key: SecureKeys.refreshToken),
      _storage.delete(key: SecureKeys.cacheKey),
      _storage.delete(key: SecureKeys.pinSalt),
      _storage.delete(key: SecureKeys.pinHash),
    ]);
  }
}
