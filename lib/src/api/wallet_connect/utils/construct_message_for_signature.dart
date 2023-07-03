import 'package:chia_crypto_utils/chia_crypto_utils.dart';

Bytes constructMessageForWCSignature(String message) {
  return Program.cons(
    Program.fromString(chiaMessagePrefix),
    Program.fromString(message),
  ).hash();
}

const chiaMessagePrefix = 'Chia Signed Message';
