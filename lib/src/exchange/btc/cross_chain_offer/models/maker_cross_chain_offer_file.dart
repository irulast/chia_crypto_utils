import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:compute/compute.dart';

/// The abstract class that holds parameters unique to offer files generated by the maker of an offer.
abstract class MakerCrossChainOfferFile implements CrossChainOfferFile {
  factory MakerCrossChainOfferFile.fromSerializedOfferFile(String serializedOfferFile) {
    final deserializedOfferFile = maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferType('ccoffer');
    }
    return deserializedOfferFile;
  }

  factory MakerCrossChainOfferFile._fromSerializedOfferFileTask(String serializedOfferFile) {
    return MakerCrossChainOfferFile.fromSerializedOfferFile(serializedOfferFile);
  }
  ExchangeAmount get offeredAmount;
  ExchangeAmount get requestedAmount;
  Address get messageAddress;
  int get mojos;
  int get satoshis;

  static MakerCrossChainOfferFile? maybeFromSerializedOfferFile(String serializedOfferFile) {
    try {
      final deserializedOfferFile =
          CrossChainOfferFile.fromSerializedOfferFile(serializedOfferFile);
      if (deserializedOfferFile is! MakerCrossChainOfferFile) {
        return null;
      }
      return deserializedOfferFile;
    } catch (e) {
      return null;
    }
  }

  static Future<MakerCrossChainOfferFile> fromSerializedOfferFileAsync(
    String serializedOfferFile,
  ) async {
    final result =
        await compute(MakerCrossChainOfferFile._fromSerializedOfferFileTask, serializedOfferFile);

    return result;
  }
}
