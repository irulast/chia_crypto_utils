import 'dart:convert';

import 'package:bech32m/bech32m.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/offer/exceptions/bad_signature_on_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/offer/exceptions/invalid_cross_chain_offer_prefix.dart';
import 'package:chia_crypto_utils/src/exchange/btc/offer/models/xch_to_btc_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/xch_to_btc.dart';
import 'package:chia_crypto_utils/src/utils/bech32.dart';

class XchToBtcOfferService {
  final XchToBtcService xchToBtcService = XchToBtcService();
  final bech32 = const Bech32mCodec();

  String serialize(XchToBtcOfferFile offer, PrivateKey privateKey) {
    final jsonData = offer.toJson();
    final json = jsonEncode(jsonData);
    final base64EncodedData = base64.encode(utf8.encode(json));
    final signature = AugSchemeMPL.sign(privateKey, utf8.encode(base64EncodedData));
    final signedData = utf8.encode('$base64EncodedData.${signature.toHex()}');
    return bech32Encode('ccoffer', Bytes(signedData));
  }

  XchToBtcOfferFile deserialize(String serializedOfferFile) {
    final bech32DecodedOfferFile = bech32Decode(serializedOfferFile);

    if (bech32DecodedOfferFile.hrp != 'ccoffer') {
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
}
