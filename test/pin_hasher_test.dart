import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iboss_assessment/core/crypto/pin_hasher.dart';

void main() {
  group('PBKDF2 app lock PIN', () {
    test('accepts the right PIN, rejects a wrong one, and stores no PIN', () async {
      final hasher = PinHasher();
      const pin = '481596';

      final derived = await hasher.derive(pin);

      expect(
        await hasher.verify(pin: pin, salt: derived.salt, expectedHash: derived.hash),
        isTrue,
      );

      expect(
        await hasher.verify(
          pin: '481597',
          salt: derived.salt,
          expectedHash: derived.hash,
        ),
        isFalse,
      );

      final stored = base64Encode(derived.hash);
      expect(stored, isNot(contains(pin)));
      expect(utf8.decode(derived.hash, allowMalformed: true), isNot(contains(pin)));
      expect(derived.salt.length, PinHasher.saltLengthBytes);
      expect(derived.hash.length, PinHasher.hashLengthBytes);
      expect(PinHasher.iterations, greaterThanOrEqualTo(100000));

      final second = await hasher.derive(pin);
      expect(second.salt, isNot(equals(derived.salt)));
      expect(second.hash, isNot(equals(derived.hash)),
          reason: 'a per-install salt must change the stored hash');
    });
  });
}
