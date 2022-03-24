import 'package:bip39/bip39.dart';
import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

// these should never be stored in memory, only in encrypted storage if at all
@immutable
class MasterKeyPair {
  const MasterKeyPair({
    required this.masterPrivateKey,
    required this.masterPublicKey,
  });

  factory MasterKeyPair.fromMnemonic(List<String> mnemonic) {
    final seed = mnemonicToSeed(mnemonic.join(' '));
    final privateKey = PrivateKey.fromSeed(seed);

    return MasterKeyPair(
      masterPrivateKey: privateKey,
      masterPublicKey: privateKey.getG1(),
    );
  }

  final PrivateKey masterPrivateKey;
  final JacobianPoint masterPublicKey;

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      masterPrivateKey.hashCode ^
      masterPublicKey.hashCode;

  @override
  bool operator ==(Object other) {
    return other is MasterKeyPair &&
        runtimeType == other.runtimeType &&
        masterPrivateKey == other.masterPrivateKey &&
        masterPublicKey == other.masterPublicKey;
  }
}
