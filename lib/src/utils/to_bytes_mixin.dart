import 'dart:typed_data';

import 'package:hex/hex.dart';

mixin ToBytesMixin {
  Uint8List toBytes();

  String toHex() => const HexEncoder().convert(toBytes());
}

extension ToBytesExtension on String {
  Uint8List toBytes() => const HexDecoder().convert(this) as Uint8List;
}
