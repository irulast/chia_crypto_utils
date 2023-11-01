import 'package:bs58/bs58.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:intl/intl.dart';

/// A record of all values relevant to an exchange offer that can be restored.
class ExchangeOfferRecord {
  ExchangeOfferRecord({
    required this.initializationCoinId,
    required this.derivationIndex,
    required this.type,
    required this.role,
    required this.mojos,
    required this.satoshis,
    required this.messagePuzzlehash,
    required this.requestorPublicKey,
    required this.offerValidityTime,
    required this.serializedMakerOfferFile,
    required this.submittedToDexie,
    this.lightningPaymentRequest,
    this.messageCoinId,
    this.serializedTakerOfferFile,
    this.fulfillerPublicKey,
    this.exchangeValidityTime,
    this.escrowPuzzlehash,
    this.escrowCoinId,
    this.initializedTime,
    this.messageCoinReceivedTime,
    this.messageCoinAcceptedTime,
    this.messageCoinDeclinedTime,
    this.escrowTransferCompletedTime,
    this.escrowTransferConfirmedBlockIndex,
    this.escrowTransferConfirmedTime,
    this.sweepTime,
    this.clawbackTime,
    this.canceledTime,
  });

  /// The ID of the coin that was spent to create a 3 mojo coin at the message puzzlehash.
  final Bytes initializationCoinId;

  /// The random, very high derivation index used to create the private key and message puzzlehash
  /// used for this exchange offer. Since there is a possibility that the message puzzlehash will
  /// get spammed, we don't want to use a lower, more commonly used derivation index. Only used
  /// if the role is maker.
  final int derivationIndex;

  /// The type of exchange is determined by whether the requestor is the XCH holder (xchToBtc) or the
  /// BTC holder (btcToXch).
  final ExchangeType type;

  /// The role the fulfiller takes in the exchange.
  final ExchangeRole role;

  /// The amount of XCH being exchanged in mojos. This is the amount that is transferred to and from the
  /// escrow puzzlehash.
  final int mojos;

  /// The amount of BTC being exchanged in satoshis. This is the the amount that the lightning payment
  /// request is for.
  final int satoshis;

  /// The puzzlehash that interested takers of the offer will send message coins to.
  final Puzzlehash messagePuzzlehash;

  /// The public key that is used to generate the escrow puzzlehash, corresponding to the private key
  /// that may be used to to spend coins at the escrow puzzlehash under certain conditions.
  final JacobianPoint requestorPublicKey;

  /// The unix timestamp when the offer can no longer be accepted, set by the maker when creating offer.
  final int offerValidityTime;

  /// The offer file generated by the maker.
  final String serializedMakerOfferFile;

  /// Whether the offer was posted to dexie.
  final bool submittedToDexie;

  /// The lightning payment request used to transfer BTC for the exchange. If the exchange type is
  /// xchToBtc, then this value is provided by the requestor. If the exchange type is btcToXch, this
  /// value is provided by the fulfiller.
  final LightningPaymentRequest? lightningPaymentRequest;

  /// The ID of the notification coin that is hinted with the message puzzlehash. It has a single
  /// child coin at the message puzzlehash that the maker may spend to indicate acceptance
  /// (if spent with the initializationCoinId as the memo) or declination (if spent without a memo).
  final Bytes? messageCoinId;

  /// The offer file generated by the taker.
  final String? serializedTakerOfferFile;

  /// The public key of the fulfiller who takes the other side of the offer, used to generate the
  /// escrow puzzlehash and corresponding to a private key that may be used to spend coins at the
  /// escrow puzzlehash under certain conditions.
  final JacobianPoint? fulfillerPublicKey;

  /// Set by the taker when they send the message coin to the maker, this is the amount of time in
  /// seconds that the BTC holder has to sweep the escrow puzzlehash after funds arrive.
  /// This is equivalent to the clawback delay seconds.
  final int? exchangeValidityTime;

  /// Generated from the requestorPublicKey, fulfillerPublicKey, exchangeValidityTime, and paymentHash
  /// of the lightningPaymentRequest. The XCH being exchanged is transferred to and from this puzzlehash.
  final Puzzlehash? escrowPuzzlehash;

  /// The ID of the first coin at the escrow puzzlehash.
  final Bytes? escrowCoinId;

  /// When the initialization coin is spent. Only used if role is maker.
  final DateTime? initializedTime;

  /// When message coin child arrives at message coin puzzlehash.
  final DateTime? messageCoinReceivedTime;

  /// When message coin child is spent with initializationCoinId memo.
  final DateTime? messageCoinAcceptedTime;

  /// When the message coin child is spent without memo.
  final DateTime? messageCoinDeclinedTime;

  /// When sufficient XCH for the exchange arrives at the escrow puzzlehash.
  final DateTime? escrowTransferCompletedTime;

  /// 32 blocks after escrow transfer completes.
  final int? escrowTransferConfirmedBlockIndex;

  /// When 32 blocks have passed since escrow transfer has completed.
  final DateTime? escrowTransferConfirmedTime;

  /// When the BTC holder spends the XCH at the escrow puzzlehash in order to claim it.
  final DateTime? sweepTime;

  /// When the XCH holder spends the XCH at the escrow puzzlehash in order to reclaim it after the
  /// exchange validity time passes.
  final DateTime? clawbackTime;

  /// When the 3 mojo coin child of the initialization coin at the message puzzlehash is spent,
  /// indicating cancelation.
  final DateTime? canceledTime;

  Bytes? get paymentHash {
    if (lightningPaymentRequest != null) {
      return lightningPaymentRequest!.tags.paymentHash;
    }
    return null;
  }

  DateTime get offerExpirationDateTime =>
      DateTime.fromMillisecondsSinceEpoch(offerValidityTime * 1000);

  String get offerExpirationDate => DateFormat.yMd().add_jm().format(offerExpirationDateTime);

  bool get offerExpired => DateTime.now().isAfter(offerExpirationDateTime);

  DateTime? get exchangeExpirationDateTime {
    if (escrowTransferCompletedTime != null && exchangeValidityTime != null) {
      // the earliest you can spend a time-locked coin is 2 blocks later, since the time is checked
      // against the timestamp of the previous block
      return escrowTransferCompletedTime!.add(Duration(seconds: exchangeValidityTime! + (2 * 19)));
    }
    return null;
  }

  bool? get exchangeExpired {
    if (exchangeExpirationDateTime != null) {
      return DateTime.now().isAfter(exchangeExpirationDateTime!);
    }
    return null;
  }

  /// The time remaining before either the offer expires, if the offer does not yet have a taker,
  /// or before the exchange expires, if the offer has a taker and funds have been transferred to
  /// the escrow address
  Duration get timeRemaining {
    final current = DateTime.now();
    if (exchangeExpirationDateTime != null) {
      return exchangeExpirationDateTime!.difference(current);
    }
    return offerExpirationDateTime.difference(current);
  }

  DateTime? get paymentRequestExpirationDateTime {
    if (lightningPaymentRequest != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (lightningPaymentRequest!.timestamp + lightningPaymentRequest!.tags.timeout!) * 1000,
      );
    }
    return null;
  }

  bool? get lightningPaymentRequestExpired {
    if (paymentRequestExpirationDateTime != null) {
      return DateTime.now().isAfter(paymentRequestExpirationDateTime!);
    }
    return null;
  }

  bool get completed => sweepTime != null;

  String get dexieId => generateDexieId(serializedMakerOfferFile);

  Map<String, dynamic> get makerOfferFileJson {
    if ((role == ExchangeRole.maker && type == ExchangeType.xchToBtc) ||
        (role == ExchangeRole.taker && type == ExchangeType.btcToXch)) {
      return XchToBtcMakerOfferFile(
        initializationCoinId: initializationCoinId,
        offeredAmount: ExchangeAmount(type: ExchangeAmountType.XCH, amount: mojos),
        requestedAmount: ExchangeAmount(type: ExchangeAmountType.BTC, amount: satoshis),
        messageAddress: messagePuzzlehash.toAddressWithContext(),
        validityTime: offerValidityTime,
        publicKey: requestorPublicKey,
        lightningPaymentRequest: lightningPaymentRequest!,
      ).toJson();
    } else {
      return BtcToXchMakerOfferFile(
        initializationCoinId: initializationCoinId,
        offeredAmount: ExchangeAmount(type: ExchangeAmountType.BTC, amount: satoshis),
        requestedAmount: ExchangeAmount(type: ExchangeAmountType.XCH, amount: mojos),
        messageAddress: messagePuzzlehash.toAddressWithContext(),
        validityTime: offerValidityTime,
        publicKey: requestorPublicKey,
      ).toJson();
    }
  }

  Map<String, dynamic>? get takerOfferFileJson {
    if (exchangeValidityTime == null || fulfillerPublicKey == null) return null;

    if ((role == ExchangeRole.maker && type == ExchangeType.xchToBtc) ||
        (role == ExchangeRole.taker && type == ExchangeType.btcToXch)) {
      return BtcToXchTakerOfferFile(
        initializationCoinId: initializationCoinId,
        validityTime: exchangeValidityTime!,
        publicKey: fulfillerPublicKey!,
        acceptedOfferHash: Bytes.encodeFromString(serializedMakerOfferFile).sha256Hash(),
      ).toJson();
    } else {
      return XchToBtcTakerOfferFile(
        initializationCoinId: initializationCoinId,
        validityTime: exchangeValidityTime!,
        publicKey: fulfillerPublicKey!,
        acceptedOfferHash: Bytes.encodeFromString(serializedMakerOfferFile).sha256Hash(),
        lightningPaymentRequest: lightningPaymentRequest!,
      ).toJson();
    }
  }

  ExchangeOfferRecord copyWith({
    Bytes? initializationCoinId,
    int? derivationIndex,
    ExchangeType? type,
    ExchangeRole? role,
    int? mojos,
    int? satoshis,
    Puzzlehash? messagePuzzlehash,
    JacobianPoint? requestorPublicKey,
    int? offerValidityTime,
    String? serializedMakerOfferFile,
    bool? submittedToDexie,
    String? serializedTakerOfferFile,
    LightningPaymentRequest? lightningPaymentRequest,
    JacobianPoint? fulfillerPublicKey,
    int? exchangeValidityTime,
    Puzzlehash? escrowPuzzlehash,
    Bytes? escrowCoinId,
    Bytes? messageCoinId,
    DateTime? initializedTime,
    DateTime? messageCoinReceivedTime,
    DateTime? messageCoinAcceptedTime,
    DateTime? messageCoinDeclinedTime,
    DateTime? escrowTransferCompletedTime,
    int? escrowTransferConfirmedBlockIndex,
    DateTime? escrowTransferConfirmedTime,
    DateTime? sweepTime,
    DateTime? clawbackTime,
    DateTime? canceledTime,
  }) {
    return ExchangeOfferRecord(
      initializationCoinId: initializationCoinId ?? this.initializationCoinId,
      derivationIndex: derivationIndex ?? this.derivationIndex,
      type: type ?? this.type,
      role: role ?? this.role,
      mojos: mojos ?? this.mojos,
      satoshis: satoshis ?? this.satoshis,
      messagePuzzlehash: messagePuzzlehash ?? this.messagePuzzlehash,
      requestorPublicKey: requestorPublicKey ?? this.requestorPublicKey,
      offerValidityTime: offerValidityTime ?? this.offerValidityTime,
      serializedMakerOfferFile: serializedMakerOfferFile ?? this.serializedMakerOfferFile,
      submittedToDexie: submittedToDexie ?? this.submittedToDexie,
      serializedTakerOfferFile: serializedTakerOfferFile ?? this.serializedTakerOfferFile,
      lightningPaymentRequest: lightningPaymentRequest ?? this.lightningPaymentRequest,
      fulfillerPublicKey: fulfillerPublicKey ?? this.fulfillerPublicKey,
      exchangeValidityTime: exchangeValidityTime ?? this.exchangeValidityTime,
      escrowPuzzlehash: escrowPuzzlehash ?? this.escrowPuzzlehash,
      escrowCoinId: escrowCoinId ?? this.escrowCoinId,
      messageCoinId: messageCoinId ?? this.messageCoinId,
      initializedTime: initializedTime ?? this.initializedTime,
      messageCoinReceivedTime: messageCoinReceivedTime ?? this.messageCoinReceivedTime,
      messageCoinDeclinedTime: messageCoinDeclinedTime ?? this.messageCoinDeclinedTime,
      messageCoinAcceptedTime: messageCoinAcceptedTime ?? this.messageCoinAcceptedTime,
      escrowTransferCompletedTime: escrowTransferCompletedTime ?? this.escrowTransferCompletedTime,
      escrowTransferConfirmedBlockIndex:
          escrowTransferConfirmedBlockIndex ?? this.escrowTransferConfirmedBlockIndex,
      escrowTransferConfirmedTime: escrowTransferConfirmedTime ?? this.escrowTransferConfirmedTime,
      sweepTime: sweepTime ?? this.sweepTime,
      clawbackTime: clawbackTime ?? this.clawbackTime,
      canceledTime: canceledTime ?? this.canceledTime,
    );
  }
}

enum ExchangeType {
  xchToBtc,
  btcToXch,
}

enum ExchangeRole {
  maker,
  taker,
}

// See Dexie API "Inspect an Offer" section: https://dexie.space/api
String generateDexieId(String serializedOfferFile) => base58.encode(
      serializedOfferFile.toBytes().sha256Hash().byteList,
    );
