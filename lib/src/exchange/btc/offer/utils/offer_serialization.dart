import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/offer/exceptions/bad_signature_on_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/offer/exceptions/invalid_cross_chain_offer_prefix.dart';
import 'package:chia_crypto_utils/src/exchange/btc/offer/models/xch_to_btc_offer_file.dart';
import 'package:chia_crypto_utils/src/utils/bech32.dart';

String serializeOfferFile(XchToBtcOfferFile offerFile, PrivateKey privateKey) {
  final jsonData = offerFile.toJson();
  final json = jsonEncode(jsonData);
  final base64EncodedData = base64.encode(utf8.encode(json));
  final signature = AugSchemeMPL.sign(privateKey, utf8.encode(base64EncodedData));
  final signedData = utf8.encode('$base64EncodedData.${signature.toHex()}');
  return bech32Encode('ccoffer', Bytes(signedData));
}

XchToBtcOfferFile deserializeOfferFile(String serializedOfferFile) {
  final bech32DecodedOfferFile = bech32Decode(serializedOfferFile);

  final prefix = bech32DecodedOfferFile.hrp;

  if (prefix != 'ccoffer') {
    throw InvalidCrossChainOfferPrefix();
  }

  final signedData = utf8.decode(bech32DecodedOfferFile.program);
  final splitString = signedData.split('.');
  final data = splitString[0];
  final signature = JacobianPoint.fromHexG2(splitString[1]);

  final base64DecodedData = base64.decode(data);
  final jsonString = utf8.decode(base64DecodedData);
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  final offerFile = XchToBtcOfferFile.fromJson(json);

  final verification = AugSchemeMPL.verify(offerFile.publicKey, utf8.encode(data), signature);

  if (verification == false) {
    throw BadSignatureOnOfferFile();
  }

  return offerFile;
}
