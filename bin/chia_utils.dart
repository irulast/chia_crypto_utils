// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:chia_utils/src/bls/private_key.dart';
import 'package:chia_utils/src/bls/schemes.dart';
import 'package:hex/hex.dart';

void main() {
  var sk = PrivateKey.fromBytes(Uint8List.fromList(HexDecoder().convert(
      '71b0441a52587ccb38592f8fde254a08c1c23c07bbb31a9a9c94b8347743144b')));
  var pk = sk.getG1();
  print(HexEncoder().convert(pk.toBytes()));
  var message = Uint8List.fromList([]);
  var signature = AugSchemeMPL.sign(sk, message);
  var ok = AugSchemeMPL.verify(pk, message, signature);
  print(ok);
}
