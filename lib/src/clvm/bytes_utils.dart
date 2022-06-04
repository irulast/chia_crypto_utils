import 'dart:math';
import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

String flip(String binary) {
  return binary.replaceAllMapped(RegExp('[01]'), (match) => match.group(0) == '1' ? '0' : '1');
}

Bytes intToBytes(int value, int size, Endian endian, {bool signed = false}) {
  if (value < 0 && !signed) {
    throw ArgumentError('Cannot convert negative int to unsigned.');
  }
  var binary = (value < 0 ? -value : value).toRadixString(2).padLeft(size * 8, '0');
  if (value < 0) {
    binary = (int.parse(flip(binary), radix: 2) + 1).toRadixString(2).padLeft(size * 8, '0');
  }
  var bytes = RegExp('[01]{8}')
      .allMatches(binary)
      .map((match) => int.parse(match.group(0)!, radix: 2))
      .toList();
  if (endian == Endian.little) {
    bytes = bytes.reversed.toList();
  }
  return Bytes(bytes);
}

Bytes intTo64Bits(int value) {
  return intToBytes(value, 8, Endian.big);
}

Bytes intTo32Bits(int value) {
  return intToBytes(value, 4, Endian.big);
}

int intFrom32BitsStream(Iterator<int> iterator) {
  return bytesToInt(iterator.extractBytesAndAdvance(4), Endian.big);
}

int intFrom64BitsStream(Iterator<int> iterator) {
  return bytesToInt(iterator.extractBytesAndAdvance(8), Endian.big);
}

Bytes intTo8Bits(int value) {
  return intToBytes(value, 1, Endian.big);
}

Bytes intToBytesStandard(int value, Endian endian, {bool signed = false}) {
  return intToBytes(value, (value.bitLength + 8) >> 3, endian, signed: signed);
}

Bytes encodeInt(int value) {
  if (value == 0) {
    return Bytes([]);
  }
  final length = (value.bitLength + 8) >> 3;
  var bytes = intToBytes(value, length, Endian.big, signed: true);
  while (bytes.length > 1 && bytes[0] == ((bytes[1] & 0x80) != 0 ? 0xFF : 0)) {
    bytes = bytes.sublist(1);
  }
  return bytes;
}

int bytesToInt(List<int> bytes, Endian endian, {bool signed = false}) {
  if (bytes.isEmpty) {
    return 0;
  }
  final sign =
      bytes[endian == Endian.little ? bytes.length - 1 : 0].toRadixString(2).padLeft(8, '0')[0];
  final byteList = (endian == Endian.little ? bytes.reversed : bytes).toList();
  var binary = byteList.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join();
  if (sign == '1' && signed) {
    binary =
        (int.parse(flip(binary), radix: 2) + 1).toRadixString(2).padLeft(bytes.length * 8, '0');
  }
  final result = int.parse(binary, radix: 2);
  return sign == '1' && signed ? -result : result;
}

int decodeInt(List<int> bytes) {
  return bytesToInt(bytes, Endian.big, signed: true);
}

Bytes bigIntToBytes(BigInt value, int size, Endian endian, {bool signed = false}) {
  if (value < BigInt.zero && !signed) {
    throw ArgumentError('Cannot convert negative bigint to unsigned.');
  }
  var binary = (value < BigInt.zero ? -value : value).toRadixString(2).padLeft(size * 8, '0');
  if (value < BigInt.zero) {
    binary =
        (BigInt.parse(flip(binary), radix: 2) + BigInt.one).toRadixString(2).padLeft(size * 8, '0');
  }
  var bytes = RegExp('[01]{8}')
      .allMatches(binary)
      .map((match) => int.parse(match.group(0)!, radix: 2))
      .toList();
  if (endian == Endian.little) {
    bytes = bytes.reversed.toList();
  }
  return Bytes(bytes);
}

Bytes encodeBigInt(BigInt value) {
  if (value == BigInt.zero) {
    return Bytes([]);
  }
  final length = (value.bitLength + 8) >> 3;
  var bytes = bigIntToBytes(value, length, Endian.big, signed: true);
  while (bytes.length > 1 && bytes[0] == ((bytes[1] & 0x80) != 0 ? 0xFF : 0)) {
    bytes = bytes.sublist(1);
  }
  return bytes;
}

BigInt bytesToBigInt(List<int> bytes, Endian endian, {bool signed = false}) {
  if (bytes.isEmpty) {
    return BigInt.zero;
  }
  var bytesList = List.of(bytes);
  if (endian == Endian.little) {
    bytesList = bytesList.reversed.toList();
  }
  final hex = Bytes(bytes).toHex();
  if (signed) {
    return BigInt.parse(hex, radix: 16).toSigned(hex.length * 4);
  }
  return BigInt.parse(hex, radix: 16);
}

BigInt decodeBigInt(List<int> bytes) {
  return bytesToBigInt(bytes, Endian.big, signed: true);
}

bool bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

final secureRandom = Random.secure();

int randomByte() {
  return secureRandom.nextInt(256);
}

List<int> randomBytes(int length) {
  final result = <int>[];
  for (var i = 0; i < length; i++) {
    result.add(randomByte());
  }
  return result;
}

extension StripByItsPrefix on String {
  String stripBytesPrefix() {
    if (startsWith(Bytes.bytesPrefix)) {
      return replaceFirst(Bytes.bytesPrefix, '');
    }
    return this;
  }
}
