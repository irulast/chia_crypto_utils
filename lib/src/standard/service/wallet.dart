// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/exceptions/change_puzzlehash_needed_exception.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/origin_id_not_in_coins_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/incorrect_announcement_id_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/multiple_origin_coin_exception.dart';

class StandardWalletService extends BaseWalletService {
  SpendBundle createSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    // copy coins input since coins list is modified in this function
    final coins = List<CoinPrototype>.from(coinsInput);
    final totalCoinValue = coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);

    final totalPaymentAmount = payments.fold(
      0,
      (int previousValue, payment) => previousValue + payment.amount,
    );
    final change = totalCoinValue - totalPaymentAmount - fee;

    if (changePuzzlehash == null && change > 0) {
      throw ChangePuzzlehashNeededException();
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

    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;

    var first = true;
    for (var i = 0; i < coins.length; i++) {
      final coin = coins[i];
      final walletVector = keychain.getWalletVector(coin.puzzlehash);
      final privateKey = walletVector!.childPrivateKey;
      final publicKey = privateKey.getG1();

      Program? solution;
      // create output for origin coin
      if (first) {
        first = false;
        final conditions = <Condition>[];
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

        if (change > 0) {
          conditions.add(CreateCoinCondition(changePuzzlehash!, change));
          createdCoins.add(
            CoinPrototype(
              parentCoinInfo: coin.id,
              puzzlehash: changePuzzlehash,
              amount: change,
            ),
          );
        }

        if (fee > 0) {
          conditions.add(ReserveFeeCondition(fee));
        }

        conditions
          ..addAll(coinAnnouncementsToAssert)
          ..addAll(puzzleAnnouncementsToAssert);

        // generate message for coin announcements by appending coin_ids
        // see https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/wallet.py#L383
        //   message: bytes32 = std_hash(b"".join(message_list))
        final existingCoinsMessage = coins.fold(
          Bytes.empty,
          (Bytes previousValue, coin) => previousValue + coin.id,
        );
        final createdCoinsMessage = createdCoins.fold(
          Bytes.empty,
          (Bytes previousValue, coin) => previousValue + coin.id,
        );
        final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();
        conditions.add(CreateCoinAnnouncementCondition(message));

        primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(coin.id, message);

        solution = BaseWalletService.makeSolutionFromConditions(conditions);
      } else {
        solution = BaseWalletService.makeSolutionFromConditions(
          [primaryAssertCoinAnnouncement!],
        );
      }

      final puzzle = getPuzzleFromPk(publicKey);
      final coinSpend = CoinSpend(coin: coin, puzzleReveal: puzzle, solution: solution);
      spends.add(coinSpend);

      final signature = makeSignature(privateKey, coinSpend);
      signatures.add(signature);
    }

    final aggregate = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(coinSpends: spends, aggregatedSignature: aggregate);
  }

  void validateSpendBundle(SpendBundle spendBundle) {
    validateSpendBundleSignature(spendBundle);

    // validate assert_coin_announcement if it is created (if there are multiple coins spent)
    Bytes? actualAssertCoinAnnouncementId;
    final coinsToCreate = <CoinPrototype>[];
    final coinsBeingSpent = <CoinPrototype>[];
    Bytes? originId;
    for (final spend in spendBundle.coinSpends) {
      final outputConditions = spend.puzzleReveal.run(spend.solution).program.toList();

      // look for assert coin announcement condition
      final assertCoinAnnouncementPrograms =
          outputConditions.where(AssertCoinAnnouncementCondition.isThisCondition).toList();
      if (assertCoinAnnouncementPrograms.length == 1 && actualAssertCoinAnnouncementId == null) {
        actualAssertCoinAnnouncementId =
            AssertCoinAnnouncementCondition.getAnnouncementIdFromProgram(
          assertCoinAnnouncementPrograms[0],
        );
      }

      // find create_coin conditions
      final coinCreationConditions = outputConditions
          .where(CreateCoinCondition.isThisCondition)
          .map(CreateCoinCondition.fromProgram)
          .toList();

      if (coinCreationConditions.isNotEmpty) {
        // if originId is already set, multiple coins are creating output which is invalid
        if (originId != null) {
          throw MultipleOriginCoinsException();
        }
        originId = spend.coin.id;
      }
      for (final coinCreationCondition in coinCreationConditions) {
        coinsToCreate.add(
          CoinPrototype(
            parentCoinInfo: spend.coin.id,
            puzzlehash: coinCreationCondition.destinationPuzzlehash,
            amount: coinCreationCondition.amount,
          ),
        );
      }
      coinsBeingSpent.add(spend.coin);
    }
    // check for duplicate coins
    BaseWalletService.checkForDuplicateCoins(coinsToCreate);
    BaseWalletService.checkForDuplicateCoins(coinsBeingSpent);

    if (spendBundle.coinSpends.length > 1) {
      assert(
        actualAssertCoinAnnouncementId != null,
        'No assert_coin_announcement condition when multiple spends',
      );
      assert(originId != null, 'No create_coin conditions');

      // construct assert_coin_announcement id from spendbundle, verify against output

      final existingCoinsMessage = coinsBeingSpent.fold(
        Bytes.empty,
        (Bytes previousValue, coin) => previousValue + coin.id,
      );

      final createdCoinsMessage = coinsToCreate.fold(
        Bytes.empty,
        (Bytes previousValue, coin) => previousValue + coin.id,
      );

      final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();
      final constructedAnnouncementId = (originId! + message).sha256Hash();

      if (constructedAnnouncementId != actualAssertCoinAnnouncementId) {
        throw IncorrectAnnouncementIdException();
      }
    }
  }
}
