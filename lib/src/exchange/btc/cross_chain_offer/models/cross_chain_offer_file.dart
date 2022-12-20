import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/exceptions/invalid_cross_chain_offer_file_type.dart';

abstract class CrossChainOfferFile {
  CrossChainOfferFilePrefix get prefix;
  CrossChainOfferFileType get type;
  JacobianPoint get publicKey;

  Map<String, dynamic> toJson();
}

enum CrossChainOfferFileType { xchToBtc, xchToBtcAccept, btcToXch, btcToXchAccept }

// ignore: constant_identifier_names
enum CrossChainOfferFilePrefix { ccoffer, ccoffer_accept }

CrossChainOfferFileType parseCrossChainOfferFileTypeFromName(String name) {
  for (final type in CrossChainOfferFileType.values) {
    if (type.name == name) return type;
  }

  throw InvalidCrossChainOfferFileType();
}
