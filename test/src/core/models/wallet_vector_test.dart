// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
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
      final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);
      final wv = WalletVector.fromPrivateKey(
        keychainSecret.masterPrivateKey,
        0,
      );

      final bytes = wv.toBytes();

      final wv2 = WalletVector.fromBytes(bytes, 0);

      expect(wv, equals(wv2));
      expect(bytes, equals(wv2.toBytes()));
    },
  );

  test(
    'UnhardenedWalletWector serializarion and deserialization to bytes must work',
    () async {
      final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);
      final walletSet = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, 0);
      final keychain = WalletKeychain.fromWalletSets([walletSet])
        ..addOuterPuzzleHashesForAssetId(
          Puzzlehash.fromHex(
            '0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad',
          ),
        )
        ..addOuterPuzzleHashesForAssetId(
          Puzzlehash.fromHex(
            '0b6a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad',
          ),
        );

      final wv = keychain.unhardenedMap.values.first;
      final bytes = wv.toBytes();

      final deserializedWv = UnhardenedWalletVector.fromBytes(bytes, 0);

      expect(wv, equals(deserializedWv));
      expect(bytes, equals(deserializedWv.toBytes()));
    },
  );

  test(
    'SingletonWalletVector serializarion and deserialization to bytes must work',
    () async {
      final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);
      final walletSet = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, 0);
      final keychain = WalletKeychain.fromWalletSets([walletSet])
        ..getNextSingletonWalletVector(keychainSecret.masterPrivateKey)
        ..getNextSingletonWalletVector(keychainSecret.masterPrivateKey);

      final wv = keychain.singletonWalletVectors.first;
      final bytes = wv.toBytes();

      final deserializedWv = SingletonWalletVector.fromBytes(bytes);

      expect(wv, equals(deserializedWv));
      expect(bytes, equals(deserializedWv.toBytes()));
    },
  );
}
