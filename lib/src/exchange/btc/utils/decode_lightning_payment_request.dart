import 'dart:typed_data';
import 'package:bech32/bech32.dart';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/payment_request_tags.dart';

import 'package:chia_crypto_utils/src/utils/bech32.dart';

const bech32 = Bech32Codec();

LightningPaymentRequest decodeLightningPaymentRequest(String paymentRequest) {
  final bech32DecodedPaymentRequest = bech32.decode(paymentRequest, 2048);
  final hrp = bech32DecodedPaymentRequest.hrp;

  // prefix
  final prefixes = ['lnbcrt', 'lnbc', 'lntb', 'lnsb'];
  final prefix = prefixes.firstWhere(hrp.startsWith);

  // amount
  final multiplierMap = {
    'm': 0.001,
    'u': 0.000001,
    'n': 0.000000001,
    'p': 0.000000000001,
  };

  double? amount;

  if (hrp.length == prefix.length) {
    amount = 0.toDouble();
  } else {
    final amountData = hrp.substring(prefix.length, hrp.length);
    final multiplier = amountData.substring(amountData.length - 1);
    final digits = double.parse(amountData.substring(0, amountData.length - 1));
    amount = digits * multiplierMap[multiplier]!;
  }

  // timestamp
  final data = bech32DecodedPaymentRequest.data;
  final timestamp = convertBits(data.sublist(0, 7), 5, 35, pad: true)[0];

  // tags
  var taggedFields = data.sublist(7);

  const overrideSizes = {1: 256, 16: 256};

  final encodedTags = <int, dynamic>{};
  final routingInfoData = <Bytes>[];

  int bitSize;
  dynamic taggedFieldData;

  while (taggedFields.length * 5 > 520) {
    final type = taggedFields[0];
    final size = convertBits(taggedFields.sublist(1, 3), 5, 10, pad: true)[0];
    final dataBlob = taggedFields.sublist(3, 3 + size);

    if (overrideSizes.containsKey(type)) {
      bitSize = overrideSizes[type]!;
    } else {
      bitSize = 5 * size;
    }

    taggedFields = taggedFields.sublist(3 + size);

    if (size > 0) {
      taggedFieldData = convertBitsBigInt(dataBlob, 5, bitSize, pad: true)[0];
    } else {
      taggedFieldData = null;
    }

    if (size > 10) {
      taggedFieldData = bigIntToBytes(taggedFieldData as BigInt, (bitSize + 7) >> 3, Endian.big);
    }

    if (type == 3) {
      routingInfoData.add(taggedFieldData as Bytes);
      taggedFieldData = routingInfoData;
    }

    encodedTags[type] = taggedFieldData;
  }

  final decodedTags = decodeTags(encodedTags);

  // signature
  final signature = convertBitsBigInt(taggedFields, 5, 520, pad: true)[0].toString();

  return LightningPaymentRequest(
    prefix: prefix,
    amount: amount,
    timestamp: timestamp,
    tags: decodedTags,
    signature: signature,
  );
}

PaymentRequestTags decodeTags(Map<int, dynamic> encodedTags) {
  Bytes? paymentHash;
  Bytes? paymentSecret;
  final routingInfo = <Bytes>[];
  int? featureBits;
  int? expirationTime;
  Bytes? fallbackAddress;
  String? description;
  Bytes? payeePublicKey;
  Bytes? purposeCommitHash;
  int? minFinalCltvExpiry;
  Bytes? metadata;
  final unknownTags = <int, dynamic>{};

  encodedTags.forEach((type, dynamic data) {
    switch (type) {
      case 1:
        paymentHash = data != null ? (data as Bytes) : null;
        break;
      case 3:
        for (final route in data) {
          routingInfo.add(route as Bytes);
        }
        break;
      case 5:
        final featureBitsData = data != null ? (data as BigInt) : null;
        featureBits = featureBitsData?.toInt();
        break;
      case 6:
        final expirationTimeData = data != null ? (data as BigInt) : null;
        expirationTime = expirationTimeData?.toInt();
        break;
      case 9:
        fallbackAddress = data != null ? (data as Bytes) : null;
        break;
      case 13:
        description = data?.toString();
        break;
      case 16:
        paymentSecret = data != null ? (data as Bytes) : null;
        break;
      case 19:
        payeePublicKey = data != null ? (data as Bytes) : null;
        break;
      case 23:
        purposeCommitHash = data != null ? (data as Bytes) : null;
        break;
      case 24:
        final minFinalCltvExpiryData = data != null ? (data as BigInt) : null;
        minFinalCltvExpiry = minFinalCltvExpiryData?.toInt();
        break;
      case 25:
        metadata = data != null ? (data as Bytes) : null;
        break;
      default:
        unknownTags[type] = data;
    }
  });

  return PaymentRequestTags(
    paymentHash: paymentHash,
    paymentSecret: paymentSecret,
    routingInfo: routingInfo,
    featureBits: featureBits,
    expirationTime: expirationTime,
    fallbackAddress: fallbackAddress,
    description: description,
    payeePublicKey: payeePublicKey,
    purposeCommitHash: purposeCommitHash,
    minFinalCltvExpiry: minFinalCltvExpiry,
    metadata: metadata,
    unknownTags: unknownTags,
  );
}
