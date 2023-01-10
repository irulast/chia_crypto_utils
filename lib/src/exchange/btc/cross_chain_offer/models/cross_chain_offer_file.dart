import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class CrossChainOfferFile {
  CrossChainOfferFilePrefix get prefix;
  CrossChainOfferFileType get type;
  int get validityTime;
  JacobianPoint get publicKey;

  Map<String, dynamic> toJson();

  CrossChainOfferExchangeInfo getExchangeInfo(
    CrossChainOfferFile fulfillerOfferFile,
    PrivateKey requestorPrivateKey,
  );
}

extension Serialize on CrossChainOfferFile {
  String serialize(PrivateKey requestorPrivateKey) {
    return serializeCrossChainOfferFile(this, requestorPrivateKey);
  }
}

enum CrossChainOfferFileType { xchToBtc, xchToBtcAccept, btcToXch, btcToXchAccept }

// ignore: constant_identifier_names
enum CrossChainOfferFilePrefix { ccoffer, ccoffer_accept }

CrossChainOfferFileType parseCrossChainOfferFileTypeFromJson(Map<String, dynamic> json) {
  if (json.containsKey('offered')) {
    final offeredAmount = ExchangeAmount.fromJson(json['offered'] as Map<String, dynamic>);
    if (offeredAmount.type == ExchangeAmountType.XCH) {
      return CrossChainOfferFileType.xchToBtc;
    } else {
      return CrossChainOfferFileType.btcToXch;
    }
  } else {
    if (json.containsKey('lightning_payment_request')) {
      return CrossChainOfferFileType.xchToBtcAccept;
    } else {
      return CrossChainOfferFileType.btcToXchAccept;
    }
  }
}
