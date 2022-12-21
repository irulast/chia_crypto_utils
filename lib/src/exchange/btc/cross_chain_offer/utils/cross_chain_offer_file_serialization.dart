import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/exceptions/bad_signature_on_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/exceptions/failed_signature_on_offer_file_exception.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/exceptions/invalid_cross_chain_offer_prefix.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_offer_file.dart';
import 'package:chia_crypto_utils/src/utils/bech32.dart';

String serializeCrossChainOfferFile(CrossChainOfferFile offerFile, PrivateKey privateKey) {
  final jsonData = offerFile.toJson();
  final json = jsonEncode(jsonData);
  final base64EncodedData = base64.encode(utf8.encode(json));

  if (offerFile.publicKey != privateKey.getG1()) {
    throw FailedSignatureOnOfferFileException();
  }

  final signature = AugSchemeMPL.sign(privateKey, utf8.encode(base64EncodedData));
  final signedData = utf8.encode('$base64EncodedData.${signature.toHex()}');
  return bech32Encode(offerFile.prefix.name, Bytes(signedData));
}

CrossChainOfferFile deserializeCrossChainOfferFile(String serializedOfferFile) {
  final bech32DecodedOfferFile = bech32Decode(serializedOfferFile);

  final prefix = bech32DecodedOfferFile.hrp;

  if (prefix != 'ccoffer' && prefix != 'ccoffer_accept') {
    throw InvalidCrossChainOfferPrefix();
  }

  final signedData = utf8.decode(bech32DecodedOfferFile.program);
  final splitString = signedData.split('.');
  final data = splitString[0];
  final signature = JacobianPoint.fromHexG2(splitString[1]);

  final base64DecodedData = base64.decode(data);
  final jsonString = utf8.decode(base64DecodedData);
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  final type = parseCrossChainOfferFileTypeFromJson(json);

  CrossChainOfferFile deserializedOfferFile;

  switch (type) {
    case CrossChainOfferFileType.xchToBtc:
      deserializedOfferFile = XchToBtcOfferFile.fromJson(json);
      break;
    case CrossChainOfferFileType.xchToBtcAccept:
      deserializedOfferFile = XchToBtcOfferAcceptFile.fromJson(json);
      break;
    case CrossChainOfferFileType.btcToXch:
      deserializedOfferFile = BtcToXchOfferFile.fromJson(json);
      break;
    case CrossChainOfferFileType.btcToXchAccept:
      deserializedOfferFile = BtcToXchOfferAcceptFile.fromJson(json);
      break;
  }

  final verification =
      AugSchemeMPL.verify(deserializedOfferFile.publicKey, utf8.encode(data), signature);

  if (verification == false) {
    throw BadSignatureOnOfferFile();
  }

  return deserializedOfferFile;
}
