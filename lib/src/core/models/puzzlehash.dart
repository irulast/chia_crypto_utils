import 'dart:html';
import 'dart:typed_data';

import 'package:chia_utils/src/core/models/address.dart';
import 'package:hex/hex.dart';
import 'package:crypto/crypto.dart';

class Puzzlehash {
  static String bytesPrefix = '0x';
  List<int> byteList;

  

  Puzzlehash(this.byteList);

  // empty byte array
  static Puzzlehash get empty {
    return Puzzlehash([]);
  }
  
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

  /// Returns a concatenation of this puzzlehash and [other].
  Puzzlehash operator +(Puzzlehash other) {
    return Puzzlehash(bytes + other.bytes);
  }

  Puzzlehash sha256Hash() {
    return(Puzzlehash(sha256.convert(bytes).bytes));
  }
}
