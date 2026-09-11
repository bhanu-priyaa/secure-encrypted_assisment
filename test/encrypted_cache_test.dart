import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:iboss_assessment/core/crypto/crypto_service.dart';

void main() {
  group('AES-256-GCM profile cache', () {
    late CryptoService crypto;
    late Uint8List key;

    setUp(() {
      crypto = CryptoService();
      key = crypto.generateDataKey();
    });

    test('round-trips a profile and produces a different file every write', () async {
      final plaintext = Uint8List.fromList(
        utf8.encode(jsonEncode({'email': 'emily.johnson@x.dummyjson.com', 'id': 1})),
      );

      final first = await crypto.encrypt(plaintext, key);
      final second = await crypto.encrypt(plaintext, key);

      expect(await crypto.decrypt(first, key), equals(plaintext));
      expect(await crypto.decrypt(second, key), equals(plaintext));

      expect(first, isNot(equals(second)),
          reason: 'a fresh nonce per write must change the ciphertext');
      expect(
        first.sublist(0, CryptoService.nonceLengthBytes),
        isNot(equals(second.sublist(0, CryptoService.nonceLengthBytes))),
      );

      expect(
        utf8.decode(first, allowMalformed: true),
        isNot(contains('emily.johnson@x.dummyjson.com')),
        reason: 'the email must not be readable in the file on disk',
      );

      final tampered = Uint8List.fromList(first);
      tampered[tampered.length - 1] ^= 0xFF;
      expect(await crypto.decrypt(tampered, key), isNull,
          reason: 'a failed authentication tag is a cache miss');

      expect(await crypto.decrypt(first, crypto.generateDataKey()), isNull);
    });
  });
}
