import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:hex/hex.dart';

mixin ToBytesMixin {
  Bytes toBytes();

  String toHex() => const HexEncoder().convert(toBytes());
}

extension StringToBytesX on String {
  Bytes toBytes() => const HexDecoder().convert(this) as Bytes;
}
