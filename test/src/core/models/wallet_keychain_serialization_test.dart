// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final keychainSecret = KeychainCoreSecret.generate();

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 20; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final assetId =
      Puzzlehash.fromHex('625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8c');

  final walletKeychain = WalletKeychain(walletsSetList)..addOuterPuzzleHashesForAssetId(assetId);

  test('should correctly serialize and deserialize a WalletKeychain', () {
    final walletKeychainSerialized = walletKeychain.toBytes();
    final walletKeychainDeserialized = WalletKeychain.fromBytes(walletKeychainSerialized);
    expect(walletKeychainDeserialized.toBytes(), equals(walletKeychainSerialized));
  });
}
