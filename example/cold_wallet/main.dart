// ignore_for_file: avoid_void_async, lines_longer_than_80_chars

import 'package:chia_crypto_utils/src/command/standard/generate_cold_wallet.dart';
import 'package:test/test.dart';

void main() async {
  test('generate an offline cold wallet', () {
   expect(generateColdWallet, returnsNormally);
  });
}
