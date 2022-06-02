import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() {
  // final p = Program.list([Program.fromInt(604800)]);
  final p = Program.list([  Program.fromBytes(intToBytesStandard(604800, Endian.big))
]);
  print(p.serialize().toList());
}