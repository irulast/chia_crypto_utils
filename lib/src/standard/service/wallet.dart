import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/clvm/keywords.dart';
import 'package:chia_utils/src/core/models/conditions/assert_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';
import 'package:chia_utils/src/core/models/conditions/reserve_fee_condition.dart';

class WalletService {
  FullNode fullNode;

  Context context;

  WalletService(this.fullNode, this.context);

  BlockchainNetwork get blockchainNetwork {
    return context.get<BlockchainNetwork>();
  }

  SpendBundle createSpendBundle(
      List<Coin> coins,
      int amount,
      Address destinationAddress,
      Puzzlehash changePuzzlehash,
      WalletKeychain keychain,
      {int fee = 0,
      Puzzlehash? originId}) {
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
    final sendCreateCoinCondition = CreateCoinCondition(amount, destinationHash);
    conditions.add(sendCreateCoinCondition);
    createdCoins.add(
      CoinPrototype(
        parentCoinInfo: originCoin.id,
        puzzlehash: destinationHash,
        amount: amount,
      ),
    );

    if (change > 0) {
      conditions.add(CreateCoinCondition(change, changePuzzlehash));
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

    // generate message for coin announcements by appending coin_ids
    // see: chia/wallet/wallet.py: 380
    //   message: bytes32 = std_hash(b"".join(message_list))
    final existingCoinsMessage = coins.fold(Puzzlehash.empty, (Puzzlehash previousValue, coin) => previousValue + coin.id);
    final createdCoinsMessage = createdCoins.fold(Puzzlehash.empty, (Puzzlehash previousValue, coin) => previousValue + coin.id);
    final message = (existingCoinsMessage + createdCoinsMessage).sha256Hash();
    conditions.add(CreateCoinAnnouncementCondition(message));

    final originCoinSolution = makeSolutionFromConditions(conditions);
    final originCoinPuzzle = getPuzzleFromPk(originCoinPublicKey);

    final coinSpendAndSignature = createCoinsSpendAndSignature(originCoinSolution, originCoinPuzzle, originCoinPrivateKey, originCoin);

    signatures.add(coinSpendAndSignature.signature);
    spends.add(coinSpendAndSignature.coinSpend);

    final primaryAssertCoinAnnouncement = AssertCoinAnnouncementCondition(originCoin.id, message);

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
    return Puzzlehash(result.toList()[0].toList()[2].atom) +
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
}

class CoinSpendAndSignature {
  CoinSpend coinSpend;
  JacobianPoint signature;

  CoinSpendAndSignature(this.coinSpend, this.signature);
}
