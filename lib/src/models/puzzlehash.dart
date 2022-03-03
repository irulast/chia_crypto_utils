import 'dart:typed_data';

import 'package:hex/hex.dart';

class Puzzlehash {
  static String bytesPrefix = '0x';
  List<int> byteList;

  Puzzlehash(this.byteList);
  
  factory Puzzlehash.fromHex(String phHex) {
    if (phHex.startsWith(bytesPrefix)) {
      return Puzzlehash(const HexDecoder().convert(phHex.replaceFirst(bytesPrefix, '')));
    }
    return Puzzlehash(const HexDecoder().convert(phHex));
  }

  Uint8List get bytes {
    return Uint8List.fromList(byteList);
  }

  String get hex {
    return const HexEncoder().convert(byteList);
  }

  String get hexWithBytesPrefix {
    return bytesPrefix + hex;
  }
}