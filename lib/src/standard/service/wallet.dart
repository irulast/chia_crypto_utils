import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/clvm/keywords.dart';
import 'package:chia_utils/src/context/context.dart';
import 'package:chia_utils/src/core/models/address.dart';
import 'package:chia_utils/src/core/models/blockchain_network.dart';
import 'package:chia_utils/src/core/models/coin.dart';
import 'package:chia_utils/src/core/models/coin_prototype.dart';
import 'package:chia_utils/src/core/models/coin_spend.dart';
import 'package:chia_utils/src/core/models/conditions/assert_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_announcement_condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';
import 'package:chia_utils/src/core/models/conditions/reserve_fee_condition.dart';
import 'package:chia_utils/src/core/models/puzzlehash.dart';
import 'package:chia_utils/src/core/models/spend_bundle.dart';
import 'package:chia_utils/src/core/models/wallet_keychain.dart';

class WalletService {
  FullNode fullNode;

  Context context;

  WalletService(this.fullNode, this.context);

  BlockchainNetwork get blockchainNetwork {
    return context.get<BlockchainNetwork>();
  }

  Future<SpendBundle> createSpendBundle(
      List<Coin> coins,
      int amount,
      Address destinationAddress,
      Puzzlehash changePuzzlehash,
      WalletKeychain keychain,
      {int fee = 0,
      Puzzlehash? originId}) async {
    final totalCoinValue =
        coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final change = totalCoinValue - amount - fee;
    print(change);

    final destinationHash = destinationAddress.toPuzzlehash();

    AssertCoinAnnouncementCondition? primaryAssertCoinAnnouncement;
    List<JacobianPoint> signatures = [];
    List<CoinSpend> spends = [];
    var outputCreated = false;
    for (var i = 0; i < coins.length; i++) {
      final coin = coins[i];
      final walletVector = keychain.getWalletVector(coin.puzzlehash);
      var privateKey = walletVector!.childPrivateKey;
      var publicKey = privateKey.getG1();

      Program? solution;

      // Only one coin creates outputs
      if ((originId == null && i == 0) ||
          (originId != null && originId.hex == coin.id.hex)) {
        outputCreated = true;

        List<Condition> conditions = [];
        List<CoinPrototype> createdCoins = [];

        // generate conditions
        final sendCreateCoinCondition =
            CreateCoinCondition(amount, destinationHash);
        conditions.add(sendCreateCoinCondition);
        createdCoins.add(CoinPrototype(
            parentCoinInfo: coin.id,
            puzzlehash: destinationHash,
            amount: amount));

        if (change > 0) {
          conditions.add(CreateCoinCondition(change, changePuzzlehash));
          createdCoins.add(CoinPrototype(
              parentCoinInfo: coin.id,
              puzzlehash: changePuzzlehash,
              amount: change));
        }

        if (fee > 0) {
          conditions.add(ReserveFeeCondition(fee));
        }

        // generate message for coin announcements by appending coin_ids
        // see: chia/wallet/wallet.py: 380
        //   message: bytes32 = std_hash(b"".join(message_list))
        final existingCoinsMessage = coins.fold(Puzzlehash.empty,
            (Puzzlehash previousValue, coin) => previousValue + coin.id);
        final createdCoinsMessage = createdCoins.fold(Puzzlehash.empty,
            (Puzzlehash previousValue, coin) => previousValue + coin.id);
        final message =
            (existingCoinsMessage + createdCoinsMessage).sha256Hash();
        conditions.add(CreateCoinAnnouncementCondition(message));

        primaryAssertCoinAnnouncement =
            AssertCoinAnnouncementCondition(coin.id, message);

        solution = makeSolutionFromConditions(conditions);
      } else {
        solution = makeSolutionFromConditions([primaryAssertCoinAnnouncement!]);
      }

      if (!outputCreated) {
        throw Exception('Origin id not in coins');
      }

      final puzzle = getPuzzleFromPk(publicKey);
      var result = puzzle.run(solution);

      var addsigmessage = getAddSigMeMessageFromResult(result.program, coin);

      var synthSecretKey = calculateSyntheticPrivateKey(privateKey);
      final signature = AugSchemeMPL.sign(synthSecretKey, addsigmessage.bytes);
      signatures.add(signature);

      spends
          .add(CoinSpend(coin: coin, puzzleReveal: puzzle, solution: solution));
    }

    var aggregate = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(coinSpends: spends, aggregatedSignature: aggregate);
  }

  Puzzlehash getAddSigMeMessageFromResult(Program result, Coin coin) {
    return Puzzlehash(result.toList()[0].toList()[2].atom) +
        coin.id +
        Puzzlehash.fromHex(blockchainNetwork.aggSigMeExtraData);
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

  static List<Coin> selectCoinsToSpend(List<Coin> coins, int amount) {
    coins = coins.where((element) => element.spentBlockIndex == 0).toList();
    coins.sort((a, b) => b.amount - a.amount);

    List<Coin> spendCoins = [];
    var spendAmount = 0;

    calculator:
    while (coins.isNotEmpty && spendAmount < amount) {
      for (var i = 0; i < coins.length; i++) {
        if (spendAmount + coins[i].amount <= amount) {
          var record = coins.removeAt(i--);
          spendCoins.add(record);
          spendAmount += record.amount;
          continue calculator;
        }
      }
      var record = coins.removeAt(0);
      spendCoins.add(record);
      spendAmount += record.amount;
    }
    if (spendAmount < amount) {
      throw Exception('Insufficient funds.');
    }

    return spendCoins;
  }
}
