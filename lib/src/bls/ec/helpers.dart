import 'package:chia_utils/src/bls.dart';

extension BigIntExtractor on dynamic {
  BigInt? toBigInt() {
    if (this is BigInt) {
      return this as BigInt;
    } else if (this is Fq) {
      return (this as Fq).value;
    } else {
      return null;
    }
  }
}
