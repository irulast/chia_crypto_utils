// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/src/core/index.dart';
import 'package:test/test.dart';

const testMnemonic = [
  'elder',
  'quality',
  'this',
  'chalk',
  'crane',
  'endless',
  'machine',
  'hotel',
  'unfair',
  'castle',
  'expand',
  'refuse',
  'lizard',
  'vacuum',
  'embody',
  'track',
  'crash',
  'truth',
  'arrow',
  'tree',
  'poet',
  'audit',
  'grid',
  'mesh',
];

void main() {
  test(
    'WalletVector serializarion and deserialization to bytes must work',
    () async {
      final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);
      final wv = WalletVector.fromPrivateKey(
        masterKeyPair.masterPrivateKey,
        0,
      );

      final bytes = wv.toBytes();

      final wv2 = WalletVector.fromBytes(bytes);

      expect(wv, equals(wv2));
      expect(bytes, equals(wv2.toBytes()));
    },
  );

  test(
    'UnhardenedWalletWector serializarion and deserialization to bytes must work',
    () async {
      final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);
      final wv = UnhardenedWalletVector.fromPrivateKey(
        masterKeyPair.masterPrivateKey,
        0,
      );

      final bytes = wv.toBytes();

      final wv2 = UnhardenedWalletVector.fromBytes(bytes);

      expect(wv, equals(wv2));
      expect(bytes, equals(wv2.toBytes()));
    },
  );
}
