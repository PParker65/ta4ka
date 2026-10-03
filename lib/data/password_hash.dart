import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String newPasswordSalt() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return base64Encode(bytes);
}

String hashPassword(String password, String salt) {
  final bytes = utf8.encode('$salt\u001fkolesasave.v1\u001f$password');
  return sha256.convert(bytes).toString();
}

bool verifyPassword({
  required String password,
  required String salt,
  required String expectedHash,
}) {
  if (salt.isEmpty || expectedHash.isEmpty) return false;
  return hashPassword(password, salt) == expectedHash;
}
