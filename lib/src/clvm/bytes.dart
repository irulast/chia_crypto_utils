import 'dart:typed_data';

String flip(String binary) {
  return binary.replaceAllMapped(
      RegExp(r'[01]'), (match) => match.group(0) == '1' ? '0' : '1');
}

Uint8List intToBytes(int value, int size, Endian endian,
    {bool signed = false}) {
  if (value < 0 && !signed) {
    throw ArgumentError('Cannot convert negative int to unsigned.');
  }
  var binary =
      (value < 0 ? -value : value).toRadixString(2).padLeft(size * 8, '0');
  if (value < 0) {
    binary = (int.parse(flip(binary), radix: 2) + 1)
        .toRadixString(2)
        .padLeft(size * 8, '0');
  }
  var bytes = RegExp(r'[01]{8}')
      .allMatches(binary)
      .map((match) => int.parse(match.group(0)!, radix: 2))
      .toList();
  if (endian == Endian.little) {
    bytes = bytes.reversed.toList();
  }
  return Uint8List.fromList(bytes);
}

Uint8List encodeInt(int value) {
  if (value == 0) {
    return Uint8List.fromList([]);
  }
  var length = (value.bitLength + 8) >> 3;
  var bytes = intToBytes(value, length, Endian.big, signed: true);
  while (bytes.length > 1 && bytes[0] == ((bytes[1] & 0x80) != 0 ? 0xFF : 0)) {
    bytes = bytes.sublist(1);
  }
  return bytes;
}

int bytesToInt(Uint8List bytes, Endian endian, {bool signed = false}) {
  if (bytes.isEmpty) {
    return 0;
  }
  var sign = bytes[endian == Endian.little ? bytes.length - 1 : 0]
      .toRadixString(2)
      .padLeft(8, '0')[0];
  var byteList = (endian == Endian.little ? bytes.reversed : bytes).toList();
  var binary =
      byteList.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');
  if (sign == '1' && signed) {
    binary = (int.parse(flip(binary), radix: 2) + 1)
        .toRadixString(2)
        .padLeft(bytes.length * 8, '0');
  }
  var result = int.parse(binary, radix: 2);
  return sign == '1' && signed ? -result : result;
}

int decodeInt(Uint8List bytes) {
  return bytesToInt(bytes, Endian.big, signed: true);
}

Uint8List bigIntToBytes(BigInt value, int size, Endian endian,
    {bool signed = false}) {
  if (value < BigInt.zero && !signed) {
    throw ArgumentError('Cannot convert negative bigint to unsigned.');
  }
  var binary = (value < BigInt.zero ? -value : value)
      .toRadixString(2)
      .padLeft(size * 8, '0');
  if (value < BigInt.zero) {
    binary = (BigInt.parse(flip(binary), radix: 2) + BigInt.one)
        .toRadixString(2)
        .padLeft(size * 8, '0');
  }
  var bytes = RegExp(r'[01]{8}')
      .allMatches(binary)
      .map((match) => int.parse(match.group(0)!, radix: 2))
      .toList();
  if (endian == Endian.little) {
    bytes = bytes.reversed.toList();
  }
  return Uint8List.fromList(bytes);
}

Uint8List encodeBigInt(BigInt value) {
  if (value == BigInt.zero) {
    return Uint8List.fromList([]);
  }
  var length = (value.bitLength + 8) >> 3;
  var bytes = bigIntToBytes(value, length, Endian.big, signed: true);
  while (bytes.length > 1 && bytes[0] == ((bytes[1] & 0x80) != 0 ? 0xFF : 0)) {
    bytes = bytes.sublist(1);
  }
  return bytes;
}

BigInt bytesToBigInt(Uint8List bytes, Endian endian, {bool signed = false}) {
  if (bytes.isEmpty) {
    return BigInt.zero;
  }
  var sign = bytes[endian == Endian.little ? bytes.length - 1 : 0]
      .toRadixString(2)
      .padLeft(8, '0')[0];
  var byteList = (endian == Endian.little ? bytes.reversed : bytes).toList();
  var binary =
      byteList.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');
  if (sign == '1' && signed) {
    binary = (BigInt.parse(flip(binary), radix: 2) + BigInt.one)
        .toRadixString(2)
        .padLeft(bytes.length * 8, '0');
  }
  var result = BigInt.parse(binary, radix: 2);
  return sign == '1' && signed ? -result : result;
}

BigInt decodeBigInt(Uint8List bytes) {
  return bytesToBigInt(bytes, Endian.big, signed: true);
}

bool bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
