import 'package:chia_crypto_utils/chia_crypto_utils.dart';

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
