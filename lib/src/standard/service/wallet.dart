import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/conditions/assert_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';
import 'package:chia_utils/src/core/models/conditions/reserve_fee_condition.dart';
import 'package:chia_utils/src/core/service/base_wallet.dart';

class StandardWalletService extends BaseWalletService{
  StandardWalletService(Context context) : super(context);

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

    final originCoinSolution = BaseWalletService.makeSolutionFromConditions(conditions);
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

      final solution = BaseWalletService.makeSolutionFromConditions([primaryAssertCoinAnnouncement]);
      final puzzle = getPuzzleFromPk(publicKey);

      final coinSpendAndSignature = createCoinsSpendAndSignature(solution, puzzle, privateKey, coin);
      signatures.add(coinSpendAndSignature.signature);
      spends.add(coinSpendAndSignature.coinSpend);
    }

    final aggregate = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(coinSpends: spends, aggregatedSignature: aggregate);
  }
}
