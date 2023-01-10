import 'dart:typed_data';
import 'package:bech32/bech32.dart';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

import 'package:chia_crypto_utils/src/utils/bech32.dart';

const bech32Codec = Bech32Codec();
String? network;

LightningPaymentRequest decodeLightningPaymentRequest(String paymentRequest) {
  final bech32DecodedPaymentRequest = bech32Codec.decode(paymentRequest, 2048);
  final hrp = bech32DecodedPaymentRequest.hrp;

  // prefix
  final prefixes = ['lnbcrt', 'lnbc', 'lntb', 'lnsb'];
  final prefix = prefixes.firstWhere(hrp.startsWith);

  // network
  final networks = {
    'bc': 'mainnet',
    'tb': 'testnet',
    'bcrt': 'regtest',
    'sb': 'simnet',
  };

  final network = networks[prefix.substring(2)];

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
    if (multiplierMap.containsKey(amountData[amountData.length - 1])) {
      final multiplier = amountData.substring(amountData.length - 1);
      final digits = double.parse(amountData.substring(0, amountData.length - 1));
      amount = digits * multiplierMap[multiplier]!;
    } else {
      amount = double.parse(amountData);
    }
  }

  // timestamp
  final data = bech32DecodedPaymentRequest.data;
  final timestamp = convertBits(data.sublist(0, 7), 5, 35, pad: true)[0];

  // tags
  var taggedFields = data.sublist(7);

  const overrideSizes = {1: 256, 16: 256};

  final encodedTags = <int, dynamic>{};
  final routingInfoData = <List<int>>[];

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
      routingInfoData.add(dataBlob);
      taggedFieldData = routingInfoData;
    }

    encodedTags[type] = taggedFieldData;
  }

  final decodedTags = decodeTags(encodedTags);

  // signature
  final signatureData = convertBitsBigInt(taggedFields, 5, 520, pad: true)[0].toRadixString(16);
  final fullSignature = signatureData.substring(0, signatureData.length - 2);
  final rValue = fullSignature.substring(0, 64);
  final sValue = fullSignature.substring(64);
  final recoveryFlag = int.parse(signatureData[signatureData.length - 1]);
  final signature = PaymentRequestSignature(
    fullSignature: fullSignature,
    rValue: rValue,
    sValue: sValue,
    recoveryFlag: recoveryFlag,
  );

  return LightningPaymentRequest(
    paymentRequest: paymentRequest,
    prefix: prefix,
    network: network!,
    amount: amount,
    timestamp: timestamp,
    tags: decodedTags,
    signature: signature,
  );
}

PaymentRequestTags decodeTags(Map<int, dynamic> encodedTags) {
  Bytes? paymentHash;
  Bytes? paymentSecret;
  final routingInfo = <RouteInfo>[];
  int? featureBits;
  int? expirationTime;
  FallbackAddress? fallbackAddress;
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
        if (data != null) {
          data = data as List<List<int>>;
          for (final route in data) {
            routingInfo.add(decodeRouteInfo(route));
          }
        }
        break;
      case 5:
        featureBits = data != null ? int.parse((data as BigInt).toRadixString(2)) : null;
        break;
      case 6:
        final expirationTimeData = data != null ? (data as BigInt) : null;
        expirationTime = expirationTimeData?.toInt();
        break;
      case 9:
        if (data != null) {
          final fallbackAddressData = data as Bytes;
          final version = fallbackAddressData[0];
          final addressHash = fallbackAddressData.sublist(1).toHex();
          fallbackAddress = FallbackAddress(version: version, addressHash: addressHash);
        }
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
    timeout: expirationTime,
    fallbackAddress: fallbackAddress,
    description: description,
    payeePublicKey: payeePublicKey,
    purposeCommitHash: purposeCommitHash,
    minFinalCltvExpiry: minFinalCltvExpiry,
    metadata: metadata,
    unknownTags: unknownTags,
  );
}

RouteInfo decodeRouteInfo(List<int> data) {
  final routeData = convertBits(data, 5, 8, pad: true);

  final publicKey = convertBitsBigInt(routeData.sublist(0, 33), 8, 264, pad: true)[0]
      .toRadixString(16)
      .padLeft(66, '0');
  final shortChannelId =
      convertBitsBigInt(routeData.sublist(33, 41), 8, 64, pad: true)[0].toRadixString(16);
  final feeBaseMsats = convertBits(routeData.sublist(41, 45), 8, 32, pad: true)[0];
  final feeProportionalMillionths = convertBits(routeData.sublist(45, 49), 8, 32, pad: true)[0];
  final cltvExpiryDelta = convertBits(routeData.sublist(49, 51), 8, 16, pad: true)[0];

  return RouteInfo(
    publicKey: publicKey,
    shortChannelId: shortChannelId,
    feeBaseMsat: feeBaseMsats,
    feeProportionalMillionths: feeProportionalMillionths,
    cltvExpiryDelta: cltvExpiryDelta,
  );
}
