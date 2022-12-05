import 'dart:typed_data';

import 'package:bech32/bech32.dart';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/payment_request_tags.dart';

import 'package:chia_crypto_utils/src/utils/bech32.dart';

PaymentRequestTags decodeTags(Map<int, dynamic> encodedTags) {
  Bytes? paymentHash;
  Bytes? paymentSecret;
  Bytes? routingInfo;
  int? featureBits;
  int? expirationTime;
  Bytes? fallbackAddress;
  String? description;
  JacobianPoint? payeePublicKey;
  Bytes? purposeCommitHash;
  int? minFinalCltvExpiry;

  final unknownTags = <int, dynamic>{};

  encodedTags.forEach((tag, dynamic data) {
    switch (tag) {
      case 1:
        paymentHash = data as Bytes;
        break;
      case 3:
        routingInfo = data as Bytes;
        break;
      case 5:
        final featureBitsData = data as BigInt;
        featureBits = featureBitsData.toInt();
        break;
      case 6:
        final expirationTimeData = data as BigInt;
        expirationTime = expirationTimeData.toInt();
        break;
      case 9:
        fallbackAddress = data as Bytes;
        break;
      case 13:
        description = data.toString();
        break;
      case 16:
        paymentSecret = data as Bytes;
        break;
      case 19:
        final payeePublicKeyData = data as Bytes;
        payeePublicKey = JacobianPoint.fromBytesG1(payeePublicKeyData);
        break;
      case 23:
        purposeCommitHash = data as Bytes;
        break;
      case 24:
        final minFinalCltvExpiryData = data as BigInt;
        minFinalCltvExpiry = minFinalCltvExpiryData.toInt();
        break;
      default:
        unknownTags[tag] = data;
    }
  });

  return PaymentRequestTags(
    paymentHash: paymentHash!,
    paymentSecret: paymentSecret!,
    routingInfo: routingInfo!,
    featureBits: featureBits!,
    expirationTime: expirationTime!,
    fallbackAddress: fallbackAddress,
    description: description,
    payeePublicKey: payeePublicKey,
    purposeCommitHash: purposeCommitHash,
    minFinalCltvExpiry: minFinalCltvExpiry,
    unknownTags: unknownTags,
  );
}

LightningPaymentRequest decodeLightningPaymentRequest(String paymentRequest) {
  const bech32 = Bech32Codec();
  final data = bech32.decode(paymentRequest, 2048).data;
  var tagged = data.sublist(7);

  const overrideSizes = {1: 256, 16: 256};

  final encodedTags = <int, dynamic>{};

  int bitSize;
  dynamic taggedFieldData;

  while (tagged.length * 5 > 520) {
    final type = tagged[0];
    final size = convertBits(tagged.sublist(1, 3), 5, 10, pad: true)[0];
    final dataBlob = tagged.sublist(3, 3 + size);

    if (overrideSizes.containsKey(type)) {
      bitSize = overrideSizes[type]!;
    } else {
      bitSize = 5 * size;
    }

    tagged = tagged.sublist(3 + size);

    if (size > 0) {
      taggedFieldData = convertToLongBitLength(dataBlob, 5, bitSize, pad: true)[0];
    } else {
      taggedFieldData = null;
    }

    if (size > 10) {
      taggedFieldData = bigIntToBytes(taggedFieldData as BigInt, (bitSize + 7) >> 3, Endian.big);
    }
    encodedTags[type] = taggedFieldData;
  }

  final signature = convertToLongBitLength(tagged, 5, 520, pad: true)[0].toString();

  final decodedTags = decodeTags(encodedTags);

  return LightningPaymentRequest(tags: decodedTags, signature: signature);
}
