import 'package:bip39/bip39.dart' as bip39;
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';
import 'package:meta/meta.dart';

@immutable
class KeychainCoreSecret with ToBytesMixin {
  const KeychainCoreSecret(this.mnemonic, this.masterPrivateKey);

  factory KeychainCoreSecret.generate() {
    final mnemonic = generateMnemonic();
    final seed = bip39.mnemonicToSeed(mnemonic.join(mnemonicWordSeperator));
    final masterPrivateKey = PrivateKey.fromSeed(seed);

    return KeychainCoreSecret(mnemonic, masterPrivateKey);
  }

  factory KeychainCoreSecret.fromMnemonic(List<String> mnemonic) {
    final seed = bip39.mnemonicToSeed(mnemonic.join(mnemonicWordSeperator));
    final privateKey = PrivateKey.fromSeed(seed);

    return KeychainCoreSecret(
      mnemonic,
      privateKey,
    );
  }

  factory KeychainCoreSecret.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    final mnemonicAsString = stringfromStream(iterator);
    final masterPrivateKey = PrivateKey.fromStream(iterator);

    return KeychainCoreSecret(
      mnemonicAsString.split(mnemonicWordSeperator),
      masterPrivateKey,
    );
  }

  @override
  Bytes toBytes() {
    return serializeItem(mnemonic.join(mnemonicWordSeperator)) + masterPrivateKey.toBytes();
  }

  static const mnemonicWordSeperator = ' ';

  final List<String> mnemonic;
  final PrivateKey masterPrivateKey;
  JacobianPoint get masterPublicKey => masterPrivateKey.getG1();

  PrivateKey get farmerPrivateKey => masterSkToFarmerSk(masterPrivateKey);
  JacobianPoint get farmerPublicKey => farmerPrivateKey.getG1();

  int get fingerprint => masterPublicKey.getFingerprint();

  static List<String> generateMnemonic({int strength = 256}) {
    return bip39.generateMnemonic(strength: strength).split(mnemonicWordSeperator);
  }
}
