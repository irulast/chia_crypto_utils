// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() async {
  final keychainSecret = await KeychainCoreSecret.generateAsync();

  final keychain = await WalletKeychain.fromCoreSecretAsync(
    keychainSecret,
    walletSize: 20,
    plotNftWalletSize: 0,
  );

  final assetIds = [Program.fromInt(0).hash(), Program.fromInt(1).hash()];

  final walletKeychain = keychain
    ..addOuterPuzzleHashesForAssetId(assetIds[0])
    ..addOuterPuzzleHashesForAssetId(assetIds[1])
    ..getNextSingletonWalletVector(keychainSecret.masterPrivateKey)
    ..getNextSingletonWalletVector(keychainSecret.masterPrivateKey);

  test('should correctly serialize and deserialize a WalletKeychain', () {
    final walletKeychainSerialized = walletKeychain.toBytes();
    final walletKeychainDeserialized = WalletKeychain.fromBytes(walletKeychainSerialized);

    expect(
      walletKeychainDeserialized.hardenedWalletVectors.length,
      equals(20),
    );
    expect(
      walletKeychainDeserialized.hardenedWalletVectors.length,
      equals(walletKeychain.hardenedWalletVectors.length),
    );

    for (var i = 0; i < walletKeychainDeserialized.hardenedWalletVectors.length; i++) {
      expect(
        walletKeychainDeserialized.hardenedWalletVectors[i],
        equals(walletKeychain.hardenedWalletVectors[i]),
      );
    }

    expect(
      walletKeychainDeserialized.unhardenedMap.length,
      equals(60),
    );

    expect(
      walletKeychainDeserialized.unhardenedWalletVectors.length,
      equals(walletKeychain.unhardenedWalletVectors.length),
    );

    final deserializeUnhardenedWalletVectors = walletKeychainDeserialized.unhardenedWalletVectors;
    final originalUnhardenedWalletVectors = walletKeychain.unhardenedWalletVectors;

    deserializeUnhardenedWalletVectors.sort((a, b) => a.puzzlehash.compareTo(b.puzzlehash));
    originalUnhardenedWalletVectors.sort((a, b) => a.puzzlehash.compareTo(b.puzzlehash));

    for (var i = 0; i < deserializeUnhardenedWalletVectors.length; i++) {
      expect(
        deserializeUnhardenedWalletVectors[i],
        equals(originalUnhardenedWalletVectors[i]),
      );
    }

    expect(
      walletKeychainDeserialized.singletonWalletVectors.length,
      equals(2),
    );

    expect(
      walletKeychainDeserialized.singletonWalletVectors.length,
      equals(walletKeychain.singletonWalletVectors.length),
    );

    for (var i = 0; i < walletKeychainDeserialized.singletonWalletVectors.length; i++) {
      expect(
        walletKeychainDeserialized.singletonWalletVectors[i],
        equals(walletKeychain.singletonWalletVectors[i]),
      );
    }
  });
}
