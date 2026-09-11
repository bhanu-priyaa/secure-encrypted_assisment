import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class PinDerivation {
  const PinDerivation({required this.salt, required this.hash});

  final Uint8List salt;
  final Uint8List hash;
}

class PinHasher {
  PinHasher({Random? random}) : _random = random ?? Random.secure();

  static const iterations = 120000;
  static const saltLengthBytes = 16;
  static const hashLengthBytes = 32;

  final Random _random;

  Uint8List newSalt() {
    final bytes = Uint8List(saltLengthBytes);
    for (var i = 0; i < saltLengthBytes; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  Future<PinDerivation> derive(String pin) async {
    final salt = newSalt();
    return PinDerivation(salt: salt, hash: await deriveWithSalt(pin, salt));
  }

  Future<Uint8List> deriveWithSalt(String pin, Uint8List salt) {
    return Isolate.run(() => _pbkdf2(pin, salt));
  }

  Future<bool> verify({
    required String pin,
    required Uint8List salt,
    required Uint8List expectedHash,
  }) async {
    final actual = await deriveWithSalt(pin, salt);
    return constantTimeEquals(actual, expectedHash);
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    var diff = a.length ^ b.length;
    final n = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

Future<Uint8List> _pbkdf2(String pin, Uint8List salt) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: PinHasher.iterations,
    bits: PinHasher.hashLengthBytes * 8,
  );
  final key = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(pin)),
    nonce: salt,
  );
  return Uint8List.fromList(await key.extractBytes());
}
