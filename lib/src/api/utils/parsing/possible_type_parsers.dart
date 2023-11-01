// // ignore_for_file: avoid_catching_errors

// import 'package:chia_crypto_utils/chia_crypto_utils.dart';

// String? parsePossibleString(dynamic item, {bool allowEmpty = false}) {
//   if (item is! String || (!allowEmpty && item.isEmpty)) {
//     return null;
//   }

//   return item;
// }

// List<T>? parsePossibleListOfXFromListOfStrings<T>(
//   dynamic list,
//   T Function(String string) xFromString,
// ) {
//   if (list is! List<dynamic>) {
//     return null;
//   }
//   final listOfx = <T>[];

//   for (final item in list) {
//     if (item is String) {
//       try {
//         final x = xFromString(item);
//         listOfx.add(x);
//       } on Error {
//         // pass
//       } on Exception {
//         // pass
//       }
//     }
//   }
//   return listOfx;
// }

// List<T>? parsePossibleListOfXFromListOfJson<T>(
//   dynamic list,
//   T Function(Map<String, dynamic> json) xFromJson,
// ) {
//   if (list is! List<dynamic>) {
//     return null;
//   }
//   final listOfx = <T>[];

//   for (final item in list) {
//     final x = parsePossibleXFromJson(item, xFromJson);
//     if (x != null) {
//       listOfx.add(x);
//     }
//   }
//   return listOfx;
// }

// List<String>? parsePossibleListOfStrings(dynamic list) {
//   return parsePossibleListOfXFromListOfStrings(list, (string) => string);
// }

// List<Bytes>? parsePossibleListOfBytes(dynamic list) {
//   return parsePossibleListOfXFromListOfStrings(list, Bytes.fromHex);
// }

// bool? parsePossibleBool(dynamic item) {
//   if (item is bool) {
//     return item;
//   }
//   if (item is String) {
//     final boolString = item.toLowerCase();
//     if (boolString == 'true') {
//       return true;
//     }
//     if (boolString == 'false') {
//       return false;
//     }
//   }
//   return null;
// }

// int? parsePossibleInt(dynamic item) {
//   if (item is int) {
//     return item;
//   }
//   return null;
// }

// double? parsePossibleDouble(dynamic item) {
//   if (item is double) {
//     return item;
//   }
//   return null;
// }

// num? parsePossibleNum(dynamic item) {
//   if (item is num) {
//     return item;
//   }
//   return null;
// }

// T? parsePossibleXFromJson<T>(
//   dynamic maybeJson,
//   T Function(Map<String, dynamic> json) xFromJson,
// ) {
//   final json = parsePossibleJson(maybeJson);
//   if (json == null) {
//     return null;
//   }
//   try {
//     final x = xFromJson(json);
//     return x;
//   } on Error {
//     return null;
//   } on Exception {
//     return null;
//   }
// }

// Map<String, dynamic>? parsePossibleJson(dynamic item) {
//   if (item is Map<String, dynamic>) {
//     return item;
//   }
//   return null;
// }

// Bytes? parsePossibleBytesFromHex(dynamic item, {bool allowEmpty = false}) {
//   return parsePossibleXFromString(item, Bytes.fromHex, allowEmpty: allowEmpty);
// }

// PrivateKey? parsePossiblePrivateKeyFromHex(dynamic item) {
//   return parsePossibleXFromString(item, PrivateKey.fromHex);
// }

// Address? parsePossibleAddressFromString(dynamic item) {
//   return parsePossibleXFromString(item, Address.new);
// }

// T? parsePossibleXFromString<T>(
//   dynamic item,
//   T Function(String string) xFromString, {
//   bool allowEmpty = false,
// }) {
//   final string = parsePossibleString(item, allowEmpty: allowEmpty);
//   if (string == null) {
//     return null;
//   }

//   try {
//     final x = xFromString(string);
//     return x;
//   } on Error {
//     return null;
//   } on Exception {
//     return null;
//   }
// }

// extension ThrowIfNull<T> on T? {
//   T assertNotNull() {
//     if (this == null) {
//       throw Exception('Null check not passed');
//     }
//     return this!;
//   }
// }
