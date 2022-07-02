import 'package:bip39/bip39.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

Future<void> createColdWallet() async {
  final mnemonicPhrase = generateMnemonic(strength: 256);
  final mnemonicWords = mnemonicPhrase.split(' ');
  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonicWords);
  final masterPrivateKey = keychainSecret.masterPrivateKey;

  final fingerprint = keychainSecret.masterPublicKey.getFingerprint();
  final masterPublicKeyHex = keychainSecret.masterPublicKey.toHex();
  final farmerPublicKeyHex = masterSkToFarmerSk(masterPrivateKey).getG1().toHex();
  final poolPublicKeyHex = masterSkToPoolSk(masterPrivateKey).getG1().toHex();

  print('Fingerprint: $fingerprint');
  print('Mnemonic Phrase: $mnemonicPhrase');
  print('Master public key (m): $masterPublicKeyHex');
  print(
    'Farmer public key (m/$blsSpecNumber/$chiaBlockchainNumber/$farmerPathNumber/0): $farmerPublicKeyHex',
  );
  print(
    'Pool public key (m/$blsSpecNumber/$chiaBlockchainNumber/$poolPathNumber/0: $poolPublicKeyHex',
  );
  print('Wallet addresses');

  final walletSet = <WalletSet>[];
  for (var i = 0; i < 20; i++) {
    final set = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletSet.add(set);

    final address = Address.fromPuzzlehash(set.hardened.puzzlehash, 'xch').address;
    print(' $address');
  }
}
