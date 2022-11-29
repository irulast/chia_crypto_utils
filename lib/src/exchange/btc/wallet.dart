import 'dart:typed_data';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/origin_id_not_in_coins_exception.dart';
import 'package:chia_crypto_utils/src/standard/puzzles/p2_delayed_or_preimage./p2_delayed_or_preimage.clvm.hex.dart';

class BtcExchangeWalletService extends StandardWalletService {
  SpendBundle createExchangeSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    int clawbackDelaySeconds = 86400,
    required PrivateKey clawbackPrivateKey,
    required JacobianPoint clawbackPublicKey,
    required Puzzlehash sweepReceiptHash,
    required PrivateKey sweepPrivateKey,
    required JacobianPoint sweepPublicKey,
    Bytes? sweepPreimage,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    // copy coins input since coins list is modified in this function
    final coins = List<CoinPrototype>.from(coinsInput);

    PrivateKey? privateKey;
    if (sweepPreimage != null) {
      privateKey = sweepPrivateKey;
    } else {
      privateKey = clawbackPrivateKey;
    }

    final signatures = <JacobianPoint>[];
    final spends = <CoinSpend>[];

    // returns -1 if originId is given but is not in coins
    final originIndex = originId == null ? 0 : coins.indexWhere((coin) => coin.id == originId);

    if (originIndex == -1) {
      throw OriginIdNotInCoinsException();
    }

    // origin coin should be processed first so move it to the front of the list
    if (originIndex != 0) {
      final originCoin = coins.removeAt(originIndex);
      coins.insert(0, originCoin);
    }

    final conditions = <Condition>[];
    // AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    var first = true;
    for (var i = 0; i < coins.length; i++) {
      final coin = coins[i];

      // create output for origin coin
      if (first) {
        first = false;
        final createdCoins = <CoinPrototype>[];
        for (final payment in payments) {
          final sendCreateCoinCondition = payment.toCreateCoinCondition();
          conditions.add(sendCreateCoinCondition);
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: coin.id,
              puzzlehash: payment.puzzlehash,
              amount: payment.amount,
            ),
          );
        }

        // if (fee > 0) {
        //   conditions.add(ReserveFeeCondition(fee));
        // }

        // conditions
        //   ..addAll(coinAnnouncementsToAssert)
        //   ..addAll(puzzleAnnouncementsToAssert);

        // // generate message for coin announcements by appending coin_ids
        // // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/wallet.py#L383
        // //   message: bytes32 = std_hash(b"".join(message_list))
        // final existingCoinsMessage = coins.fold(
        //   Bytes.empty,
        //   (Bytes previousValue, coin) => previousValue + coin.id,
        // );
        // final createdCoinsMessage = createdCoins.fold(
        //   Bytes.empty,
        //   (Bytes previousValue, coin) => previousValue + coin.id,
        // );
        // final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();
        // conditions.add(CreateCoinAnnouncementCondition(message));

        // primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(coin.id, message);
      }
      // else {
      //   delegatedSolution = BaseWalletService.makeSolutionFromConditions(
      //     [primaryAssertCoinAnnouncement!],
      //   );
      // }

      final holdingAddressPuzzle = generateHoldingAddressPuzzle(
        clawbackDelaySeconds: clawbackDelaySeconds,
        clawbackPublicKey: clawbackPublicKey,
        sweepReceiptHash: sweepReceiptHash,
        sweepPublicKey: sweepPublicKey,
      );

      final totalPublicKey = sweepPublicKey + clawbackPublicKey;

      final solution = clawbackOrSweepSolution(
        totalPublicKey: totalPublicKey,
        clawbackDelaySeconds: clawbackDelaySeconds,
        clawbackPublicKey: clawbackPublicKey,
        sweepReceiptHash: sweepReceiptHash,
        sweepPublicKey: sweepPublicKey,
        conditions: conditions,
        sweepPreimage: sweepPreimage,
      );

      final coinSpend =
          CoinSpend(coin: coin, puzzleReveal: holdingAddressPuzzle, solution: solution);
      spends.add(coinSpend);

      final signature = makeSignatureForExchange(privateKey, coinSpend);
      signatures.add(signature);
    }

    final aggregate = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(coinSpends: spends, aggregatedSignature: aggregate);
  }

  SpendBundle createCleanSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    int clawbackDelaySeconds = 86400,
    required PrivateKey clawbackPrivateKey,
    required JacobianPoint clawbackPublicKey,
    required Puzzlehash sweepReceiptHash,
    required PrivateKey sweepPrivateKey,
    required JacobianPoint sweepPublicKey,
    Bytes? sweepPreimage,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    // copy coins input since coins list is modified in this function
    final coins = List<CoinPrototype>.from(coinsInput);

    final signatures = <JacobianPoint>[];
    final spends = <CoinSpend>[];

    // returns -1 if originId is given but is not in coins
    final originIndex = originId == null ? 0 : coins.indexWhere((coin) => coin.id == originId);

    if (originIndex == -1) {
      throw OriginIdNotInCoinsException();
    }

    // origin coin should be processed first so move it to the front of the list
    if (originIndex != 0) {
      final originCoin = coins.removeAt(originIndex);
      coins.insert(0, originCoin);
    }

    final conditions = <Condition>[];
    // AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    var first = true;
    for (var i = 0; i < coins.length; i++) {
      final coin = coins[i];

      // create output for origin coin
      if (first) {
        first = false;
        final createdCoins = <CoinPrototype>[];
        for (final payment in payments) {
          final sendCreateCoinCondition = payment.toCreateCoinCondition();
          conditions.add(sendCreateCoinCondition);
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: coin.id,
              puzzlehash: payment.puzzlehash,
              amount: payment.amount,
            ),
          );
        }

        // if (fee > 0) {
        //   conditions.add(ReserveFeeCondition(fee));
        // }

        // conditions
        //   ..addAll(coinAnnouncementsToAssert)
        //   ..addAll(puzzleAnnouncementsToAssert);

        // // generate message for coin announcements by appending coin_ids
        // // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/wallet.py#L383
        // //   message: bytes32 = std_hash(b"".join(message_list))
        // final existingCoinsMessage = coins.fold(
        //   Bytes.empty,
        //   (Bytes previousValue, coin) => previousValue + coin.id,
        // );
        // final createdCoinsMessage = createdCoins.fold(
        //   Bytes.empty,
        //   (Bytes previousValue, coin) => previousValue + coin.id,
        // );
        // final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();
        // conditions.add(CreateCoinAnnouncementCondition(message));

        // primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(coin.id, message);
      }
      // else {
      //   delegatedSolution = BaseWalletService.makeSolutionFromConditions(
      //     [primaryAssertCoinAnnouncement!],
      //   );
      // }

      final hiddenPuzzle = generateHiddenPuzzle(
        clawbackDelaySeconds: clawbackDelaySeconds,
        clawbackPublicKey: clawbackPublicKey,
        sweepReceiptHash: sweepReceiptHash,
        sweepPublicKey: sweepPublicKey,
      );

      final holdingAddressPuzzle = generateHoldingAddressPuzzle(
        clawbackDelaySeconds: clawbackDelaySeconds,
        clawbackPublicKey: clawbackPublicKey,
        sweepReceiptHash: sweepReceiptHash,
        sweepPublicKey: sweepPublicKey,
      );

      final totalPublicKey = sweepPublicKey + clawbackPublicKey;

      final totalPrivateKey = calculateTotalPrivateKey(
        totalPublicKey,
        hiddenPuzzle,
        sweepPrivateKey,
        clawbackPrivateKey,
      );

      final delegatedSolution = BaseWalletService.makeSolutionFromConditions(conditions);

      final coinSpend =
          CoinSpend(coin: coin, puzzleReveal: holdingAddressPuzzle, solution: delegatedSolution);
      spends.add(coinSpend);

      final signature = makeSignatureForExchange(totalPrivateKey, coinSpend);
      signatures.add(signature);
    }

    final aggregate = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(coinSpends: spends, aggregatedSignature: aggregate);
  }

  Program generateHoldingAddressPuzzle({
    int clawbackDelaySeconds = 86400,
    required JacobianPoint clawbackPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint sweepPublicKey,
  }) {
    final hiddenPuzzleProgram = generateHiddenPuzzle(
      clawbackDelaySeconds: clawbackDelaySeconds,
      clawbackPublicKey: clawbackPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: sweepPublicKey,
    );

    final totalPublicKey = sweepPublicKey + clawbackPublicKey;

    final puzzle = getPuzzleFromPkAndHiddenPuzzle(totalPublicKey, hiddenPuzzleProgram);

    return puzzle;
  }

  Program generateHiddenPuzzle({
    required int clawbackDelaySeconds,
    required JacobianPoint clawbackPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint sweepPublicKey,
  }) {
    final hiddenPuzzleProgram = p2DelayedOrPreimageProgram.curry([
      Program.cons(
        Program.fromInt(clawbackDelaySeconds),
        Program.fromBytes(clawbackPublicKey.toBytes()),
      ),
      Program.cons(
        Program.fromBytes(sweepReceiptHash.toBytes()),
        Program.fromBytes(sweepPublicKey.toBytes()),
      )
    ]);

    return hiddenPuzzleProgram;
  }

  Program clawbackOrSweepSolution({
    required JacobianPoint totalPublicKey,
    required int clawbackDelaySeconds,
    required JacobianPoint clawbackPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint sweepPublicKey,
    required List<Condition> conditions,
    Bytes? sweepPreimage,
  }) {
    Program? p2DelayedOrPreimageSolution;

    final hiddenPuzzleProgram = generateHiddenPuzzle(
      clawbackDelaySeconds: clawbackDelaySeconds,
      clawbackPublicKey: clawbackPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: sweepPublicKey,
    );

    final delegatedSolution = BaseWalletService.makeSolutionFromConditions(conditions);

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
}
