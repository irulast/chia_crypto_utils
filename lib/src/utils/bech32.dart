import 'package:bech32m/bech32m.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

const maxLength = 4294967296;

String bech32Encode(String hrp, Bytes data) {
  final convertedData = convertBits(data, 8, 5, pad: true);
  return bech32.encode(Bech32m(hrp, convertedData), maxLength);
}

Segwit bech32Decode(String bech32String) {
  final decoded = bech32.decode(bech32String, maxLength);

  final convertedData = convertBits(Bytes(decoded.data), 5, 8, pad: false);

  return Segwit(decoded.hrp, convertedData);
}

List<int> convertBits(List<int> data, int from, int to, {required bool pad}) {
  var acc = 0;
  var bits = 0;
  final result = <int>[];
  final maxv = (1 << to) - 1;
  for (final v in data) {
    if (v < 0 || (v >> from) != 0) {
      throw Exception();
    }
    acc = (acc << from) | v;
    bits += from;
    while (bits >= to) {
      bits -= to;
      result.add((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      result.add((acc << (to - bits)) & maxv);
    }
  }
  return result;
}

// conversion to arbitrarily long bit length
List<BigInt> convertBitsBigInt(List<int> data, int from, int to, {required bool pad}) {
  var acc = BigInt.zero;
  var bits = 0;
  final result = <BigInt>[];
  final maxv = (BigInt.one << to) - BigInt.one;
  final maxAcc = (BigInt.one << (from + to - 1)) - BigInt.one;
  for (final v in data) {
    if (v < 0 || (v >> from) != 0) {
      throw Exception();
    }
    acc = ((acc << from) | BigInt.from(v)) & maxAcc;
    bits += from;
    while (bits >= to) {
      bits -= to;
      result.add((acc >> bits) & maxv);
    }
  }
  if (pad) {
    if (bits > 0) {
      result.add((acc << (to - bits)) & maxv);
    }
  }
  return result;
}
