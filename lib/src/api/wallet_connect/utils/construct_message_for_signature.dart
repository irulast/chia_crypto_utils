import 'package:chia_crypto_utils/chia_crypto_utils.dart';

Bytes constructMessageForSignature(String message, SigningMode signingMode) {
  switch (signingMode) {
    case SigningMode.chip0002:
      return constructChip002Message(message);
    case SigningMode.blsMessageAugUtf8:
      return Bytes.encodeFromString(message);
    case SigningMode.blsMessageAugHex:
      return message.hexToBytes();
  }
}

Bytes constructChip002Message(String message) {
  return Program.cons(
    Program.fromString(chip002MessagePrefix),
    Program.fromString(message),
  ).hash();
}

const chip002MessagePrefix = 'Chia Signed Message';
