import 'package:chia_crypto_utils/src/bls.dart';

extension BigIntExtractor on Object {
  BigInt? extractBigInt() {
    if (this is BigInt) {
      return this as BigInt;
    } else if (this is Fq) {
      return (this as Fq).value;
    } else {
      return null;
    }
  }
}
