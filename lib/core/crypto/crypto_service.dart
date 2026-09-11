import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class CryptoService {
  CryptoService({Random? random}) : _random = random ?? Random.secure();

  static const cipherName = 'AES-256-GCM';
  static const keyLengthBytes = 32;
  static const nonceLengthBytes = 12;
  static const tagLengthBytes = 16;

  final Random _random;
  final AesGcm _algorithm = AesGcm.with256bits();

  Uint8List generateDataKey() => randomBytes(keyLengthBytes);

  Uint8List randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  Future<Uint8List> encrypt(Uint8List plaintext, Uint8List key) async {
    _assertKeyLength(key);

    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: randomBytes(nonceLengthBytes),
    );

    final out = BytesBuilder(copy: false)
      ..add(secretBox.nonce)
      ..add(secretBox.cipherText)
      ..add(secretBox.mac.bytes);
    return out.toBytes();
  }

  Future<Uint8List?> decrypt(Uint8List blob, Uint8List key) async {
    _assertKeyLength(key);

    const overhead = nonceLengthBytes + tagLengthBytes;
    if (blob.length < overhead) return null;

    final nonce = blob.sublist(0, nonceLengthBytes);
    final cipherText = blob.sublist(nonceLengthBytes, blob.length - tagLengthBytes);
    final mac = Mac(blob.sublist(blob.length - tagLengthBytes));

    try {
      final clear = await _algorithm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: SecretKey(key),
      );
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      return null;
    }
  }

  void _assertKeyLength(Uint8List key) {
    if (key.length != keyLengthBytes) {
      throw ArgumentError('Data key must be $keyLengthBytes bytes, got ${key.length}.');
    }
  }
}
