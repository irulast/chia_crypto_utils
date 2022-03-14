import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:meta/meta.dart';

@immutable
class Puzzlehash {
  static String bytesPrefix = '0x';
  final List<int> byteList;

  const Puzzlehash(this.byteList);

  // empty byte array
  // ignore: prefer_constructors_over_static_methods
  static Puzzlehash get empty {
    return const Puzzlehash([]);
  }

  factory Puzzlehash.fromHex(String phHex) {
    if (phHex.startsWith(bytesPrefix)) {
      return Puzzlehash(
        const HexDecoder().convert(phHex.replaceFirst(bytesPrefix, '')),
      );
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

  @override
  bool operator ==(Object other) =>
      other is Puzzlehash &&
      other.runtimeType == runtimeType &&
      other.hex == hex;

  @override
  int get hashCode => hex.hashCode;

  Puzzlehash sha256Hash() {
    return Puzzlehash(sha256.convert(bytes).bytes);
  }
}
