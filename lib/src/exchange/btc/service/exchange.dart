import 'dart:typed_data';

import 'package:bech32/bech32.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/exceptions/bad_signature_on_public_key.dart';
import 'package:chia_crypto_utils/src/exchange/btc/puzzles/p2_delayed_or_preimage/p2_delayed_or_preimage.clvm.hex.dart';
import 'package:chia_crypto_utils/src/utils/bech32.dart';

// code adapted from https://github.com/richardkiss/chiaswap
class BtcExchangeService {
  final BaseWalletService baseWalletService = BaseWalletService();

  SpendBundle createExchangeSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain requestorKeychain,
    Puzzlehash? changePuzzlehash,
    required int clawbackDelaySeconds,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
    Bytes? sweepPreimage,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final walletVector = requestorKeychain.unhardenedWalletVectors.first;
    final requestorPrivateKey = walletVector.childPrivateKey;
    final requestorPublicKey = requestorPrivateKey.getG1();

    final JacobianPoint clawbackPublicKey;
    final JacobianPoint sweepPublicKey;

    if (sweepPreimage == null) {
      clawbackPublicKey = requestorPublicKey;
      sweepPublicKey = fulfillerPublicKey;
    } else {
      clawbackPublicKey = fulfillerPublicKey;
      sweepPublicKey = requestorPublicKey;
    }

    return baseWalletService.createSpendBundleBase(
      payments: payments,
      coinsInput: coinsInput,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
      transformStandardSolution: (standardSolution) {
        final totalPublicKey = sweepPublicKey + clawbackPublicKey;

        return clawbackOrSweepSolution(
          totalPublicKey: totalPublicKey,
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: clawbackPublicKey,
          sweepPaymentHash: sweepPaymentHash,
          sweepPublicKey: sweepPublicKey,
          delegatedSolution: standardSolution,
          sweepPreimage: sweepPreimage,
        );
      },
      makePuzzleRevealFromPuzzlehash: (puzzlehash) {
        return generateChiaswapPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: clawbackPublicKey,
          sweepPaymentHash: sweepPaymentHash,
          sweepPublicKey: sweepPublicKey,
        );
      },
      makeSignatureForCoinSpend: (coinSpend) {
        return baseWalletService.makeSignature(
          requestorPrivateKey,
          coinSpend,
          useSyntheticOffset: false,
        );
      },
    );
  }

  Program generateChiaswapPuzzle({
    required int clawbackDelaySeconds,
    required JacobianPoint clawbackPublicKey,
    required Bytes sweepPaymentHash,
    required JacobianPoint sweepPublicKey,
  }) {
    final hiddenPuzzleProgram = generateHiddenPuzzle(
      clawbackDelaySeconds: clawbackDelaySeconds,
      clawbackPublicKey: clawbackPublicKey,
      sweepPaymentHash: sweepPaymentHash,
      sweepPublicKey: sweepPublicKey,
    );

    final totalPublicKey = sweepPublicKey + clawbackPublicKey;

    final puzzle = getPuzzleFromPkAndHiddenPuzzle(totalPublicKey, hiddenPuzzleProgram);

    return puzzle;
  }

  Program generateHiddenPuzzle({
    required int clawbackDelaySeconds,
    required JacobianPoint clawbackPublicKey,
    required Bytes sweepPaymentHash,
    required JacobianPoint sweepPublicKey,
  }) {
    final hiddenPuzzleProgram = p2DelayedOrPreimageProgram.curry([
      Program.cons(
        Program.fromInt(clawbackDelaySeconds),
        Program.fromBytes(clawbackPublicKey.toBytes()),
      ),
      Program.cons(
        Program.fromBytes(sweepPaymentHash),
        Program.fromBytes(sweepPublicKey.toBytes()),
      )
    ]);

    return hiddenPuzzleProgram;
  }

  Program clawbackOrSweepSolution({
    required JacobianPoint totalPublicKey,
    required int clawbackDelaySeconds,
    required JacobianPoint clawbackPublicKey,
    required Bytes sweepPaymentHash,
    required JacobianPoint sweepPublicKey,
    required Program delegatedSolution,
    Bytes? sweepPreimage,
  }) {
    Program? p2DelayedOrPreimageSolution;

    final hiddenPuzzleProgram = generateHiddenPuzzle(
      clawbackDelaySeconds: clawbackDelaySeconds,
      clawbackPublicKey: clawbackPublicKey,
      sweepPaymentHash: sweepPaymentHash,
      sweepPublicKey: sweepPublicKey,
    );

    if (sweepPreimage != null) {
      p2DelayedOrPreimageSolution =
          Program.list([Program.fromBytes(sweepPreimage), delegatedSolution]);
    } else {
      p2DelayedOrPreimageSolution = Program.list([Program.fromInt(0), delegatedSolution]);
    }

    final solution = Program.list(
      [
        Program.fromBytes(totalPublicKey.toBytes()),
        hiddenPuzzleProgram,
        p2DelayedOrPreimageSolution
      ],
    );

    return solution;
  }

  String createSignedPublicKey(WalletKeychain keychain) {
    final walletVector = keychain.unhardenedWalletVectors.first;
    final privateKey = walletVector.childPrivateKey;
    final publicKey = privateKey.getG1();

    final message = 'I own this key.'.toBytes();

    final signature = AugSchemeMPL.sign(privateKey, message);

    return '${publicKey.toHex()}_${signature.toHex()}';
  }

  JacobianPoint parseSignedPublicKey(String signedPublicKey) {
    final splitString = signedPublicKey.split('_');
    final publicKey = JacobianPoint.fromHexG1(splitString[0]);
    final signature = JacobianPoint.fromHexG2(splitString[1]);

    final message = 'I own this key.'.toBytes();

    final verification = AugSchemeMPL.verify(publicKey, message, signature);

    if (verification == true) {
      return publicKey;
    } else {
      throw BadSignatureOnPublicKeyException();
    }
  }

  Map<String, dynamic> parseLightningPaymentRequest(String paymentRequest) {
    const bech32 = Bech32Codec();
    final data = bech32.decode(paymentRequest, 2048).data;
    var tagged = data.sublist(7);

    const overrideSizes = {'1': 256, '16': 256};

    final parsedPaymentRequest = <String, dynamic>{};

    int bitSize;
    dynamic taggedFieldData;

    while (tagged.length * 5 > 520) {
      final type = tagged[0].toString();
      final size = convertBits(tagged.sublist(1, 3), 5, 10, pad: true)[0];
      final dataBlob = tagged.sublist(3, 3 + size);

      if (overrideSizes.containsKey(type)) {
        bitSize = overrideSizes[type]!;
      } else {
        bitSize = 5 * size;
      }

      tagged = tagged.sublist(3 + size);

      if (size > 0) {
        taggedFieldData = convertToLongBitLength(dataBlob, 5, bitSize, pad: true)[0];
      } else {
        taggedFieldData = null;
      }

      if (size > 10) {
        taggedFieldData = bigIntToBytes(taggedFieldData as BigInt, (bitSize + 7) >> 3, Endian.big);
      }
      parsedPaymentRequest[type] = taggedFieldData;
    }

    final signature = convertToLongBitLength(tagged, 5, 520, pad: true)[0];
    parsedPaymentRequest['signature'] = signature;

    return parsedPaymentRequest;
  }

  Bytes getPaymentHash(String paymentRequest) {
    final parsedPaymentRequest = parseLightningPaymentRequest(paymentRequest);

    return parsedPaymentRequest['1'] as Bytes;
  }
}
