import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class SingletonWalletVector with ToBytesMixin {
  const SingletonWalletVector({
    required this.singletonOwnerPrivateKey,
    required this.poolingAuthenticationPrivateKey,
    required this.derivationIndex,
  });

  SingletonWalletVector.fromMasterPrivateKey(PrivateKey masterPrivateKey, this.derivationIndex)
      : singletonOwnerPrivateKey = masterSkToSingletonOwnerSk(masterPrivateKey, derivationIndex),
        poolingAuthenticationPrivateKey =
            masterSkToPoolingAuthenticationSk(masterPrivateKey, derivationIndex, 0);

  factory SingletonWalletVector.fromStream(Iterator<int> iterator) {
    final singletonOwnerPrivateKey = PrivateKey.fromStream(iterator);
    final poolingAuthenticationPrivateKey = PrivateKey.fromStream(iterator);
    final derivationIndex = intFrom32BitsStream(iterator);

    return SingletonWalletVector(
      singletonOwnerPrivateKey: singletonOwnerPrivateKey,
      poolingAuthenticationPrivateKey: poolingAuthenticationPrivateKey,
      derivationIndex: derivationIndex,
    );
  }

  factory SingletonWalletVector.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    return SingletonWalletVector.fromStream(iterator);
  }

  final PrivateKey singletonOwnerPrivateKey;
  final PrivateKey poolingAuthenticationPrivateKey;
  final int derivationIndex;

  JacobianPoint get singletonOwnerPublicKey => singletonOwnerPrivateKey.getG1();
  JacobianPoint get poolingAuthenticationPublicKey => poolingAuthenticationPrivateKey.getG1();

  @override
  Bytes toBytes() {
    return singletonOwnerPrivateKey.toBytes() +
        poolingAuthenticationPrivateKey.toBytes() +
        intTo32Bits(derivationIndex);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      singletonOwnerPrivateKey.hashCode ^
      poolingAuthenticationPrivateKey.hashCode ^
      derivationIndex.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SingletonWalletVector &&
            runtimeType == other.runtimeType &&
            singletonOwnerPrivateKey == other.singletonOwnerPrivateKey &&
            poolingAuthenticationPrivateKey == other.poolingAuthenticationPrivateKey &&
            derivationIndex == other.derivationIndex;
  }
}
