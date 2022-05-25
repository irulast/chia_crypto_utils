import 'dart:convert';

import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:hex/hex.dart';

mixin ToBytesMixin {
  Bytes toBytes();

  String toHex() => const HexEncoder().convert(toBytes());
}

extension StringToBytesX on String {
  Bytes toBytes() => Bytes(utf8.encode(this));
  Bytes hexToBytes() => Bytes(const HexDecoder().convert(this));
}
