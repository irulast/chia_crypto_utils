import 'dart:convert';
import 'dart:typed_data';

import 'package:chia_utils/src/bls/ec.dart';
import 'package:chia_utils/src/bls/hkdf.dart';
import 'package:chia_utils/src/bls/private_key.dart';
import 'package:chia_utils/src/bls/util.dart';
import 'package:chia_utils/src/clvm/bytes.dart';

PrivateKey keyGen(Uint8List seed) {
  var L = 48;
  var okm = extractExpand(
      L,
      Uint8List.fromList(seed + [0]),
      Uint8List.fromList(utf8.encode('BLS-SIG-KEYGEN-SALT-')),
      Uint8List.fromList([0, L]));
  return PrivateKey(bytesToBigInt(okm, Endian.big) % defaultEc.n);
}

Uint8List ikmToLamportSk(Uint8List ikm, Uint8List salt) {
  return extractExpand(32 * 255, ikm, salt, Uint8List(0));
}

Uint8List parentSkToLamportPk(PrivateKey parentSk, int index) {
  var salt = intToBytes(index, 4, Endian.big);
  var ikm = parentSk.toBytes();
  var notIkm = Uint8List.fromList(ikm.map((e) => e ^ 0xFF).toList());
  var lamport0 = ikmToLamportSk(ikm, salt);
  var lamport1 = ikmToLamportSk(notIkm, salt);
  List<int> lamportPk = [];
  for (var i = 0; i < 255; i++) {
    lamportPk += hash256(lamport0.sublist(i * 32, (i + 1) * 32)) +
        hash256(lamport1.sublist(i * 32, (i + 1) * 32));
  }
  return hash256(Uint8List.fromList(lamportPk));
}

PrivateKey deriveChildSk(PrivateKey parentSk, int index) {
  return keyGen(parentSkToLamportPk(parentSk, index));
}

PrivateKey deriveChildSkUnhardened(PrivateKey parentSk, int index) {
  var h =
      hash256(parentSk.getG1().toBytes()) + intToBytes(index, 4, Endian.big);
  return PrivateKey.aggregate(
      [PrivateKey.fromBytes(Uint8List.fromList(h)), parentSk]);
}

JacobianPoint deriveChildG1Unhardened(JacobianPoint parentPk, int index) {
  var h = hash256(Uint8List.fromList(
      parentPk.toBytes() + intToBytes(index, 4, Endian.big)));
  return parentPk + G1Generator() * PrivateKey.fromBytes(h).value;
}

JacobianPoint deriveChildG2Unhardened(JacobianPoint parentPk, int index) {
  var h = hash256(Uint8List.fromList(
      parentPk.toBytes() + intToBytes(index, 4, Endian.big)));
  return parentPk + G2Generator() * PrivateKey.fromBytes(h).value;
}
