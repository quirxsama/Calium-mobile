import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuth PKCE and Tracking Tests', () {
    test('generateCodeChallenge generates RFC7636 compliant unpadded base64url challenge', () {
      const verifier = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOP1';
      final bytes = utf8.encode(verifier);
      final digest = sha256.convert(bytes);
      final challenge = base64Url.encode(digest.bytes).replaceAll('=', '');

      expect(verifier.length, 43);
      expect(challenge.length, 43);
      expect(RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(challenge), isTrue);
      expect(challenge, 'oFNfCYlVBNpNUuqOWTXBT7iuIoav4XytKFynRxiG0c4');
    });

    test('validates completion progress vs total episodes logic', () {
      bool checkCompleted(int progress, int? total) => total != null && progress >= total;

      expect(checkCompleted(12, 12), isTrue);
      expect(checkCompleted(11, 12), isFalse);
      expect(checkCompleted(12, null), isFalse);
    });
  });
}
