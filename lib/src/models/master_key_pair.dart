import 'package:bip39/bip39.dart';
import 'package:chia_utils/chia_crypto_utils.dart';

// these should never be stored in memory, only in encrypted storage if at all
class MasterKeyPair {
  PrivateKey masterPrivateKey;
  JacobianPoint masterPublicKey;
 
  MasterKeyPair({
    required this.masterPrivateKey,
    required this.masterPublicKey,
  });

  factory MasterKeyPair.fromMnemonic(List<String> mnemonic) {
    var x = mnemonic.join(' ');
    final seed = mnemonicToSeed(mnemonic.join(' '));
    final privateKey = PrivateKey.fromSeed(seed);

    return MasterKeyPair(
      masterPrivateKey: privateKey,
      masterPublicKey: privateKey.getG1()
    );
  }
}