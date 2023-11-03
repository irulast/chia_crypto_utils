import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:compute/compute.dart';

class BtcToXchTakerOfferFile implements TakerCrossChainOfferFile {
  BtcToXchTakerOfferFile({
    required this.initializationCoinId,
    required this.validityTime,
    required this.publicKey,
    required this.acceptedOfferHash,
  });

  factory BtcToXchTakerOfferFile._fromSerializedOfferFileTask(
    String serializedOfferFile,
  ) {
    return BtcToXchTakerOfferFile.fromSerializedOfferFile(serializedOfferFile);
  }

  factory BtcToXchTakerOfferFile.fromSerializedOfferFile(
    String serializedOfferFile,
  ) {
    final deserializedOfferFile =
        maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferType(
        CrossChainOfferFileType.btcToXchAccept.name,
      );
    }
    return deserializedOfferFile;
  }

  factory BtcToXchTakerOfferFile.fromJson(Map<String, dynamic> json) {
    return BtcToXchTakerOfferFile(
      initializationCoinId:
          (json['initialization_coin_id'] as String).hexToBytes(),
      validityTime: json['validity_time'] as int,
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
      acceptedOfferHash: (json['accepted_offer_hash'] as String).hexToBytes(),
    );
  }

  @override
  final Bytes initializationCoinId;
  @override
  final int validityTime;
  @override
  final JacobianPoint publicKey;
  @override
  final Bytes acceptedOfferHash;
  @override
  LightningPaymentRequest? get lightningPaymentRequest => null;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'initialization_coin_id': initializationCoinId.toHex(),
        'validity_time': validityTime,
        'public_key': publicKey.toHex(),
        'accepted_offer_hash': acceptedOfferHash.toHex(),
      };

  static BtcToXchTakerOfferFile? maybeFromSerializedOfferFile(
    String serializedOfferFile,
  ) {
    try {
      final deserializedOfferFile =
          CrossChainOfferFile.fromSerializedOfferFile(serializedOfferFile);
      if (deserializedOfferFile.type !=
          CrossChainOfferFileType.btcToXchAccept) {
        return null;
      }
      return deserializedOfferFile as BtcToXchTakerOfferFile;
    } catch (e) {
      return null;
    }
  }

  static Future<BtcToXchTakerOfferFile> fromSerializedOfferFileAsync(
    String serializedOfferFile,
  ) async {
    final result = await compute(
      BtcToXchTakerOfferFile._fromSerializedOfferFileTask,
      serializedOfferFile,
    );

    return result;
  }

  @override
  CrossChainOfferFileType get type => CrossChainOfferFileType.btcToXchAccept;

  @override
  CrossChainOfferFilePrefix get prefix =>
      CrossChainOfferFilePrefix.ccoffer_accept;

  @override
  Puzzlehash getEscrowPuzzlehash({
    required PrivateKey requestorPrivateKey,
    required int clawbackDelaySeconds,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
  }) {
    return BtcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
    );
  }
}
