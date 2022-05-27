import 'package:chia_crypto_utils/src/clvm/cost.dart';
import 'package:chia_crypto_utils/src/clvm/program.dart';

int msbMask(int byte) {
  byte |= byte >> 1;
  byte |= byte >> 2;
  byte |= byte >> 4;
  return (byte + 1) >> 1;
}

Output traversePath(Program value, Program environment) {
  var cost = Cost.pathLookupBaseCost + Cost.pathLookupCostPerLeg;
  if (value.isNull) {
    return Output(Program.nil, cost);
  }
  var endByteCursor = 0;
  final atom = value.atom;
  while (endByteCursor < atom.length && atom[endByteCursor] == 0) {
    endByteCursor++;
  }
  cost += BigInt.from(endByteCursor) * Cost.pathLookupCostPerZeroByte;
  if (endByteCursor == atom.length) {
    return Output(Program.nil, cost);
  }
  final endBitMask = msbMask(atom[endByteCursor]);
  var byteCursor = atom.length - 1;
  var bitMask = 0x01;
  while (byteCursor > endByteCursor || bitMask < endBitMask) {
    if (environment.isAtom) {
      throw StateError('Cannot traverse into $environment.');
    }
    if (atom[byteCursor] & bitMask != 0) {
      environment = environment.rest();
    } else {
      environment = environment.first();
    }
    cost += Cost.pathLookupCostPerLeg;
    bitMask <<= 1;
    if (bitMask == 0x100) {
      byteCursor--;
      bitMask = 0x01;
    }
  }
  return Output(environment, cost);
}
