import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:meta/meta.dart';

@immutable
class Bytes {
  static String bytesPrefix = '0x';
  final List<int> byteList;

  const Bytes(this.byteList);

  // empty byte array
  // ignore: prefer_constructors_over_static_methods
  static Bytes get empty {
    return const Bytes([]);
  }

  factory Bytes.fromHex(String phHex) {
    if (phHex.startsWith(bytesPrefix)) {
      return Bytes(
        const HexDecoder().convert(phHex.replaceFirst(bytesPrefix, '')),
      );
    }
    return Bytes(const HexDecoder().convert(phHex));
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
  Bytes operator +(Bytes other) {
    return Bytes(bytes + other.bytes);
  }

  @override
  bool operator ==(Object other) =>
      other is Bytes &&
      other.runtimeType == runtimeType &&
      other.hex == hex;

  @override
  int get hashCode => hex.hashCode;

  Bytes sha256Hash() {
    return Bytes(sha256.convert(bytes).bytes);
  }
}

typedef Puzzlehash = Bytes;
