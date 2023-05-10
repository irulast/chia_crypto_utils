import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/exceptions/invalid_cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/utils/bech32.dart';
import 'package:compute/compute.dart';

/// The most general abstraction that all cross chain offer files implement and holds parameters
/// that are common to all of concrete cross chain offer file classes.
abstract class CrossChainOfferFile {
  factory CrossChainOfferFile._fromSerializedOfferFileTask(String serializedOfferFile) {
    return CrossChainOfferFile.fromSerializedOfferFile(serializedOfferFile);
  }

  factory CrossChainOfferFile.fromSerializedOfferFile(String serializedOfferFile) {
    final deserializedOfferFile = maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferFile();
    }
    return deserializedOfferFile;
  }
  CrossChainOfferFilePrefix get prefix;
  CrossChainOfferFileType get type;
  Bytes? get initializationCoinId;
  int get validityTime;
  JacobianPoint get publicKey;
  LightningPaymentRequest? get lightningPaymentRequest;

  Map<String, dynamic> toJson();

  Puzzlehash getEscrowPuzzlehash({
    required PrivateKey requestorPrivateKey,
    required int clawbackDelaySeconds,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
  });

  CrossChainOfferExchangeInfo getExchangeInfo(
    CrossChainOfferFile fulfillerOfferFile,
    PrivateKey requestorPrivateKey,
  );

  static CrossChainOfferFile? maybeFromSerializedOfferFile(String serializedOfferFile) {
    try {
      if (!serializedOfferFile.startsWith('ccoffer') &&
          !serializedOfferFile.startsWith('ccoffer_accept')) {
        throw InvalidCrossChainOfferPrefix();
      }

      final bech32DecodedOfferFile = bech32Decode(serializedOfferFile);

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
          deserializedOfferFile = XchToBtcMakerOfferFile.fromJson(json);
          break;
        case CrossChainOfferFileType.xchToBtcAccept:
          deserializedOfferFile = XchToBtcTakerOfferFile.fromJson(json);
          break;
        case CrossChainOfferFileType.btcToXch:
          deserializedOfferFile = BtcToXchMakerOfferFile.fromJson(json);
          break;
        case CrossChainOfferFileType.btcToXchAccept:
          deserializedOfferFile = BtcToXchTakerOfferFile.fromJson(json);
          break;
      }

      final verification =
          AugSchemeMPL.verify(deserializedOfferFile.publicKey, utf8.encode(data), signature);

      if (verification == false) {
        throw BadSignatureOnOfferFile();
      }

      return deserializedOfferFile;
    } catch (e) {
      return null;
    }
  }

  static Future<CrossChainOfferFile> fromSerializedOfferFileAsync(
    String serializedOfferFile,
  ) async {
    final result =
        await compute(CrossChainOfferFile._fromSerializedOfferFileTask, serializedOfferFile);

    return result;
  }
}

extension Serialize on CrossChainOfferFile {
  String serialize(PrivateKey requestorPrivateKey) {
    final jsonData = toJson();
    final json = jsonEncode(jsonData);
    final base64EncodedData = base64.encode(utf8.encode(json));

    if (publicKey != requestorPrivateKey.getG1()) {
      throw FailedSignatureOnOfferFileException();
    }

    final signature = AugSchemeMPL.sign(requestorPrivateKey, utf8.encode(base64EncodedData));
    final signedData = utf8.encode('$base64EncodedData.${signature.toHex()}');
    return bech32Encode(prefix.name, Bytes(signedData));
  }

  Future<String> serializeAsync(PrivateKey requestorPrivateKey) async {
    final result =
        await compute(_serializeOfferFileTask, _OfferFileWithPrivateKey(this, requestorPrivateKey));

    return result;
  }

  static String _serializeOfferFileTask(_OfferFileWithPrivateKey arg) {
    return arg.offerFile.serialize(arg.privateKey);
  }
}

extension Role on CrossChainOfferFile {
  ExchangeRole get role =>
      prefix == CrossChainOfferFilePrefix.ccoffer ? ExchangeRole.maker : ExchangeRole.taker;
}

extension ExchangeOfferRecordType on CrossChainOfferFile {
  ExchangeType get exchangeType =>
      type == CrossChainOfferFileType.xchToBtc || type == CrossChainOfferFileType.xchToBtcAccept
          ? ExchangeType.xchToBtc
          : ExchangeType.btcToXch;
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

class _OfferFileWithPrivateKey {
  _OfferFileWithPrivateKey(this.offerFile, this.privateKey);

  final CrossChainOfferFile offerFile;
  final PrivateKey privateKey;
}
