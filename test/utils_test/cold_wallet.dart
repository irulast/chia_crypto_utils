// ignore_for_file: avoid_void_async, lines_longer_than_80_chars

import 'package:bip39/bip39.dart';
import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  test('generate an offline cold wallet', () {
    final mnemonicPhrase = generateMnemonic(strength: 256);
    final mnemonicWords = mnemonicPhrase.split(' ');
    final masterKeyPair = MasterKeyPair.fromMnemonic(mnemonicWords);
    final masterPrivateKey = masterKeyPair.masterPrivateKey;

    final fingerprint = masterKeyPair.masterPublicKey.getFingerprint();
    final masterPublicKeyHex = masterKeyPair.masterPublicKey.toHex();
    final farmerPublicKeyHex = masterSkToFarmerSk(masterPrivateKey).getG1().toHex();
    final poolPublicKeyHex = masterSkToPoolSk(masterPrivateKey).getG1().toHex();

    print('Fingerprint: $fingerprint');
    print('Master public key (m): $masterPublicKeyHex');
    print('Farmer public key (m/$blsSpecNumber/$chiaBlockchanNumber/$farmerPathNumber/0): $farmerPublicKeyHex');
    print('Pool public key (m/$blsSpecNumber/$chiaBlockchanNumber/$poolPathNumber/0: $poolPublicKeyHex');
    print('Wallet addresses');

    print('Mnemonic Phrase: $mnemonicWords');

    final walletSet = <WalletSet>[];
    for (var i = 0; i < 20; i++) {
      final set = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
      walletSet.add(set);

      final address = Address.fromPuzzlehash(set.hardened.puzzlehash, 'xch').address;
      print(' $address');
    }
  });
}
