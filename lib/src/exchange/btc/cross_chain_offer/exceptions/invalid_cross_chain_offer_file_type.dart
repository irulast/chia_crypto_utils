import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';

class InvalidCrossChainOfferType implements Exception {
  InvalidCrossChainOfferType(this.expectedType);

  final CrossChainOfferFileType expectedType;

  @override
  String toString() {
    return 'Wrong offer file type. Expected type $expectedType';
  }
}
