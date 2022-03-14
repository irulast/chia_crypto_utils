import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/clvm/keywords.dart';
import 'package:chia_utils/src/core/models/conditions/agg_sig_me_condition.dart';
import 'package:chia_utils/src/core/models/conditions/assert_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';
import 'package:chia_utils/src/core/models/conditions/reserve_fee_condition.dart';
import 'package:chia_utils/src/standard/exceptions/spend_bundle_validation/clvm_error_exception.dart';
import 'package:chia_utils/src/standard/exceptions/spend_bundle_validation/duplicate_coin_exception.dart';
import 'package:chia_utils/src/standard/exceptions/spend_bundle_validation/failed_signature_verification.dart';
import 'package:chia_utils/src/standard/exceptions/spend_bundle_validation/incorrect_announcement_id_exception.dart';
import 'package:chia_utils/src/standard/exceptions/spend_bundle_validation/multiple_origin_coin_exception.dart';

class StandardWalletService {
  Context context;

  StandardWalletService(this.context);

  BlockchainNetwork get blockchainNetwork {
    return context.get<BlockchainNetwork>();
  }

  SpendBundle createSpendBundle(
      List<Coin> coinsInput,
      int amount,
      Address destinationAddress,
      Puzzlehash changePuzzlehash,
      WalletKeychain keychain,
      {
        int fee = 0,
        Puzzlehash? originId,
        AssertCoinAnnouncementCondition? coinAnnouncementToAssert,
      }) 
    {
    // copy coins input since coins list is modified in this function
    final coins = List<Coin>.from(coinsInput);
    final totalCoinValue =
        coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final change = totalCoinValue - amount - fee;

    final destinationHash = destinationAddress.toPuzzlehash();

    final signatures = <JacobianPoint>[];
    final spends = <CoinSpend>[];

    // returns -1 if originId is given but is not in coins
    final originIndex = originId == null ? 0 : coins.indexWhere((coin) => coin.id.hex == originId.hex);

    if (originIndex == -1) {
      throw Exception('Origin id not in coins');
    }

    final originCoin = coins.removeAt(originIndex);

    // create coin spend for origin coin
    final originCoinWalletVector = keychain.getWalletVector(originCoin.puzzlehash);
    final originCoinPrivateKey = originCoinWalletVector!.childPrivateKey;
    final originCoinPublicKey = originCoinPrivateKey.getG1();

    final conditions = <Condition>[];
    final createdCoins = <CoinPrototype>[];

    // generate conditions
    if (amount > 0) {
      final sendCreateCoinCondition = CreateCoinCondition(destinationHash, amount);
      conditions.add(sendCreateCoinCondition);
      createdCoins.add(
        CoinPrototype(
          parentCoinInfo: originCoin.id,
          puzzlehash: destinationHash,
          amount: amount,
        ),
      );
    }
    

    if (change > 0) {
      conditions.add(CreateCoinCondition(changePuzzlehash, change));
      createdCoins.add(
        CoinPrototype(
          parentCoinInfo: originCoin.id,
          puzzlehash: changePuzzlehash,
          amount: change,
        ),
      );
    }

    if (fee > 0) {
      conditions.add(ReserveFeeCondition(fee));
    }

    // if (coinAnnouncementToAssert != null) {
    //   conditions.add(coinAnnouncementToAssert);
    // }

    // generate message for coin announcements by appending coin_ids
    // see: chia/wallet/wallet.py: 380
    //   message: bytes32 = std_hash(b"".join(message_list))
    final existingCoinsMessage = coins.fold(Puzzlehash.empty, (Puzzlehash previousValue, coin) => previousValue + coin.id) + originCoin.id;
    final createdCoinsMessage = createdCoins.fold(Puzzlehash.empty, (Puzzlehash previousValue, coin) => previousValue + coin.id);
    final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();
    conditions.add(CreateCoinAnnouncementCondition(message));

    final originCoinSolution = makeSolutionFromConditions(conditions);
    final originCoinPuzzle = getPuzzleFromPk(originCoinPublicKey);

    final coinSpendAndSignature = createCoinsSpendAndSignature(originCoinSolution, originCoinPuzzle, originCoinPrivateKey, originCoin);

    signatures.add(coinSpendAndSignature.signature);
    spends.add(coinSpendAndSignature.coinSpend);

    final primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition.fromParts(originCoin.id, message);

    // create coin spends for the rest of the coins
    for (final coin in coins) {
      final walletVector = keychain.getWalletVector(coin.puzzlehash);
      final privateKey = walletVector!.childPrivateKey;
      final publicKey = privateKey.getG1();

      final solution = makeSolutionFromConditions([primaryAssertCoinAnnouncement]);
      final puzzle = getPuzzleFromPk(publicKey);

      final coinSpendAndSignature = createCoinsSpendAndSignature(solution, puzzle, privateKey, coin);
      signatures.add(coinSpendAndSignature.signature);
      spends.add(coinSpendAndSignature.coinSpend);
    }

    final aggregate = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(coinSpends: spends, aggregatedSignature: aggregate);
  }

  CoinSpendAndSignature createCoinsSpendAndSignature(Program solution, Program puzzle, PrivateKey privateKey, Coin coin) {
    final result = puzzle.run(solution);

    final addsigmessage = getAddSigMeMessageFromResult(result.program, coin);

    final synthSecretKey = calculateSyntheticPrivateKey(privateKey);
    final signature = AugSchemeMPL.sign(synthSecretKey, addsigmessage.bytes);

    final coinSpend = CoinSpend(coin: coin, puzzleReveal: puzzle, solution: solution);

    return CoinSpendAndSignature(coinSpend, signature);
  }

  Puzzlehash getAddSigMeMessageFromResult(Program result, Coin coin) {
    final aggSigMeCondition = result.toList().singleWhere(AggSigMeCondition.isThisCondition);
    return Puzzlehash(aggSigMeCondition.toList()[2].atom) +
      coin.id +
      Puzzlehash.fromHex(blockchainNetwork.aggSigMeExtraData,
    );
  }

  // 51: create_coin condition number
  // 60: create_coin_announcement condition number
  // example solution: (() (q (51 0x0b7a3d5e723e0b... 10000) (60 0x6e27c9c24a...)) ())
  static Program makeSolutionFromConditions(List<Condition> conditions) {
    return Program.list([
      Program.nil,
      Program.list([
        Program.fromBigInt(keywords['q']!),
        ...conditions.map((condition) => condition.program).toList()
      ]),
      Program.nil
    ]);
  }

  void validateSpendBundle(SpendBundle spendBundle) {
    final publicKeys = <JacobianPoint>[];
    final messages = <List<int>>[];
    for (final spend in spendBundle.coinSpends) {
      final outputConditions = spend.puzzleReveal.run(spend.solution).program.toList();

      // look for assert agg sig me condition
      final aggSigMeProgram = outputConditions.singleWhere(AggSigMeCondition.isThisCondition);

      final aggSigMeCondition = AggSigMeCondition.fromProgram(aggSigMeProgram);
      publicKeys.add(aggSigMeCondition.publicKey);
      messages.add((aggSigMeCondition.message + spend.coin.id + Puzzlehash.fromHex(blockchainNetwork.aggSigMeExtraData)).bytes);
    }

    // validate signature
    if(!AugSchemeMPL.aggregateVerify(publicKeys, messages, spendBundle.aggregatedSignature)) {
      throw FailedSignatureVerificationException();
    }

    // validate assert_coin_announcement if it is created (if there are multiple coins spent)
    if (spendBundle.coinSpends.length > 1) {
      AssertCoinAnnouncementCondition? assertCoinAnnouncement;
      final coinsToCreate = <CoinPrototype>[];
      final coinsBeingSpent = <CoinPrototype>[];
      Puzzlehash? originId;
      for (final spend in spendBundle.coinSpends) {
        final outputConditions = spend.puzzleReveal.run(spend.solution).program.toList();

        // look for assert coin announcement condition
        final assertCoinAnnouncementProgram =  outputConditions.where(AssertCoinAnnouncementCondition.isThisCondition).toList();
        if (assertCoinAnnouncementProgram.length == 1 && assertCoinAnnouncement == null) {
          assertCoinAnnouncement = AssertCoinAnnouncementCondition.fromProgram(assertCoinAnnouncementProgram[0]);
        }

        // find create_coin conditions
        final coinCreationConditions = outputConditions.where(CreateCoinCondition.isThisCondition)
          .map((program) => CreateCoinCondition.fromProgram(program)).toList();
        
        if (coinCreationConditions.isNotEmpty) {
          // if originId is already set, multiple coins are creating output which is invalid
          if (originId != null) {
            throw MultipleOriginCoinsException();
          }
          originId = spend.coin.id;
        }
        for (final coinCreationCondition in coinCreationConditions) {
          coinsToCreate.add(CoinPrototype(parentCoinInfo: spend.coin.id, puzzlehash: coinCreationCondition.destinationHash, amount: coinCreationCondition.amount));
        }
        coinsBeingSpent.add(spend.coin);
      }
      // check for duplicate coins
      checkForDuplicateCoins(coinsToCreate);
      checkForDuplicateCoins(coinsBeingSpent);

      assert(assertCoinAnnouncement != null, 'No assert_coin_announcement condition when multiple spends');
      assert(originId != null, 'No create_coin conditions');
      
      // construct assert_coin_announcement id from spendbundle, verify against output

      // move origin id to end to preserve order
      final existingCoinsMessage = coinsBeingSpent.where((element) => element.id != originId)
        .fold(Puzzlehash.empty, (Puzzlehash previousValue, coin) => previousValue + coin.id)
        + originId!;

      final createdCoinsMessage = coinsToCreate.fold(Puzzlehash.empty, (Puzzlehash previousValue, coin) => previousValue + coin.id);

      final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();

      if ((originId + message).sha256Hash() != assertCoinAnnouncement!.announcementId) {
        throw IncorrectAnnouncementIdException();
      }
    }
  }

  static void checkForDuplicateCoins(List<CoinPrototype> coins) {
    final idSet = <String>{};
    for(final coin in coins) {
      final coinIdHex = coin.id.hex;
      if (idSet.contains(coinIdHex)) {
        throw DuplicateCoinException(coinIdHex);
      } else {
        idSet.add(coinIdHex);
      }
    }
  }
}

class CoinSpendAndSignature {
  CoinSpend coinSpend;
  JacobianPoint signature;

  CoinSpendAndSignature(this.coinSpend, this.signature);
}
