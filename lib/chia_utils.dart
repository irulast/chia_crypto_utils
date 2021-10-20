import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';

String getArborWalletPuzzleReveal(String publicKey) {
  return 'ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0' +
      publicKey +
      'ff018080';
}

String getArborWalletPuzzleHash(String publicKey) {
  return HexEncoder().convert(Program.cons(
          Program.int(2),
          Program.cons(
              Program.hash(Uint8List.fromList(HexDecoder().convert(
                  '0797d0507adb2bc9e193c2e3129606ff9322f1ca64580b591f2de8a04861798c'))),
              Program.cons(
                  Program.cons(
                      Program.int(4),
                      Program.cons(
                          Program.cons(Program.int(1), Program.hex(publicKey)),
                          Program.cons(Program.int(1), Program.nil))),
                  Program.nil)))
      .hash());
}

class Program {
  List<Program>? cons;
  Uint8List? atom;
  bool hashed = false;

  static Program nil = Program.atom(Uint8List.fromList([]));

  Program.atom(this.atom);
  Program.cons(Program left, Program right) : cons = [left, right];
  Program.hash(this.atom) : hashed = true;
  Program.hex(String hex)
      : atom = Uint8List.fromList(HexDecoder().convert(hex));
  Program.int(int number) {
    var length = (number.bitLength + 8) >> 3;
    if (length == 0) {
      atom = Uint8List(0);
    } else {
      var byteData = ByteData(8);
      byteData.setInt64(0, number);
      atom = byteData.buffer.asUint8List();
      while (atom!.length > length) {
        atom = atom!.sublist(1);
      }
      while (
          atom!.length > 1 && atom![0] == ((atom![1] & 0x80) != 0 ? 0xFF : 0)) {
        atom = atom!.sublist(1);
      }
    }
  }

  Uint8List hash() {
    if (atom != null) {
      return hashed
          ? atom!
          : Uint8List.fromList(sha256.convert([1] + atom!.toList()).bytes);
    } else {
      return Uint8List.fromList(sha256
          .convert([2] + cons![0].hash().toList() + cons![1].hash().toList())
          .bytes);
    }
  }
}
