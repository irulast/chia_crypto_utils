import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/exceptions/invalid_cross_chain_offer_file_type.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/utils/cross_chain_offer_file_serialization.dart';

abstract class CrossChainOfferAcceptFile implements CrossChainOfferFile {
  Bytes get acceptedOfferHash;

  static CrossChainOfferAcceptFile? maybeFromSerializedOfferFile(String serializedOfferFile) {
    try {
      final deserializedOfferFile = deserializeCrossChainOfferFile(serializedOfferFile);
      if (deserializedOfferFile is! CrossChainOfferAcceptFile) {
        return null;
      }
      return deserializedOfferFile;
    } catch (e) {
      return null;
    }
  }

  factory CrossChainOfferAcceptFile.fromSerializedOfferFile(String serializedOfferFile) {
    final deserializedOfferFile = maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferType('accept');
    }
    return deserializedOfferFile;
  }
}
