import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/block_with_reference_blocks.dart';
import 'package:chia_crypto_utils/src/core/models/conditions/create_puzzle_announcement_condition.dart';

/// cribbed from https://github.com/SutuLabs/Pawket/commit/75275f52f6e32b0a2805db18f83bbd36609f3a4d
Future<SpendBundle?> constructSpendBundleOfCoin(
  Bytes coinId,
  ChiaFullNodeInterface fullNode,
) async {
  final coin = await fullNode.getCoinById(coinId);
  if (coin == null || coin.isNotSpent) {
    return null;
  }

  final thisCoinName = coinId;

  final blockWithReferences =
      await fullNode.getBlockWithReferenceBlocks(coin.spentBlockIndex);

  if (blockWithReferences == null) {
    return null;
  }

  final outputProgram = await _parseBlock(blockWithReferences);

  final blockSpends = outputProgram
      .first()
      .toList()
      .map(CoinSpend.fromGeneratorCoinProgram)
      .toList();

  final puzAnnoCreates = <CoinAnnouncementMessage>[];
  final puzAnnoAsserts = <CoinAnnouncementMessage>[];

  final coinAnnoCreates = <CoinAnnouncementMessage>[];
  final coinAnnoAsserts = <CoinAnnouncementMessage>[];

  final createCoinConditions = <CoinAnnouncementMessage>[];

  for (final coinSpend in blockSpends) {
    final coin = coinSpend.coin;
    final conditions = coinSpend.conditions;

    final coinId = coin.id;

    for (final condition in conditions) {
      switch (condition.code) {
        case CreateCoinAnnouncementCondition.conditionCode:
          final message =
              (coin.id + condition.arguments.first.atom).sha256Hash();

          coinAnnoCreates
              .add(CoinAnnouncementMessage(coinId: coinId, message: message));
          break;

        case AssertCoinAnnouncementCondition.conditionCode:
          final message = condition.arguments.first.atom;
          coinAnnoAsserts
              .add(CoinAnnouncementMessage(coinId: coinId, message: message));
          break;

        case CreatePuzzleAnnouncementCondition.conditionCode:
          final message =
              (coin.puzzlehash + condition.arguments.first.atom).sha256Hash();
          puzAnnoCreates
              .add(CoinAnnouncementMessage(coinId: coinId, message: message));
          break;

        case AssertPuzzleAnnouncementCondition.conditionCode:
          final message = condition.arguments.first.atom;
          puzAnnoAsserts
              .add(CoinAnnouncementMessage(coinId: coinId, message: message));
          break;

        case CreateCoinCondition.conditionCode:
          final ccc = CreateCoinCondition.fromProgram(condition.toProgram());

          createCoinConditions.add(
            CoinAnnouncementMessage(
              coinId: coinId,
              message: CoinPrototype(
                parentCoinInfo: coinId,
                puzzlehash: ccc.destinationPuzzlehash,
                amount: ccc.amount,
              ).id,
            ),
          );
          break;
      }
    }
  }

  final coinsToDeal = [thisCoinName];

  final coinsDealed = <Bytes>[];

  void addToCTD(Bytes coinId) {
    if (!coinsToDeal.contains(coinId) && !coinsDealed.contains(coinId)) {
      coinsToDeal.add(coinId);
    }
  }

  while (coinsToDeal.isNotEmpty) {
    final coin = coinsToDeal.removeAt(0);
    coinsDealed.add(coin);

    for (final puzzleAnnoAssert
        in puzAnnoAsserts.where((element) => element.coinId == coin)) {
      for (final puzzleAnnoCreate in puzAnnoCreates
          .where((element) => element.message == puzzleAnnoAssert.message)) {
        addToCTD(puzzleAnnoCreate.coinId);
      }
    }

    for (final puzzleAnnoCreate
        in puzAnnoCreates.where((element) => element.coinId == coin)) {
      for (final puzzleAnnoAssert in puzAnnoAsserts
          .where((element) => element.message == puzzleAnnoCreate.message)) {
        addToCTD(puzzleAnnoAssert.coinId);
      }
    }

    for (final coinAnnoAssert
        in coinAnnoAsserts.where((element) => element.coinId == coin)) {
      for (final coinAnnoCreate in coinAnnoCreates
          .where((element) => element.message == coinAnnoAssert.message)) {
        addToCTD(coinAnnoCreate.coinId);
      }
    }

    for (final coinAnnoCreate
        in coinAnnoCreates.where((element) => element.coinId == coin)) {
      for (final coinAnnoAssert in coinAnnoAsserts
          .where((element) => element.message == coinAnnoCreate.message)) {
        addToCTD(coinAnnoAssert.coinId);
      }
    }

    for (final createCoinCondition
        in createCoinConditions.where((element) => element.coinId == coin)) {
      addToCTD(createCoinCondition.message);
    }
  }

  final spendBundleSpends =
      blockSpends.where((element) => coinsDealed.contains(element.coin.id));

  return SpendBundle(
    coinSpends: spendBundleSpends.toList(),
  );
}

Future<Program> _parseBlock(
  BlockWithReferenceBlocks blockWithReferences,
) async {
  final block = blockWithReferences.block;
  final refBlocks = blockWithReferences.referenceBlocks;
  if (refBlocks.isEmpty) {
    return block.transactionGenerator!
        .runAsync(Program.list([Program.list([])]))
        .then((value) => value.program);
  }

  return generatorProgram
      .runAsync(
        Program.list([
          block.transactionGenerator!,
          Program.list(refBlocks.map((e) => e.transactionGenerator!).toList()),
        ]),
      )
      .then((value) => value.program);
}

final generatorProgram = Program.deserializeHex(
  'ff02ffff01ff02ff05ffff04ff02ffff04ff13ff80808080ffff04ffff01ff02ffff01ff05ffff02ff3effff04ff02ffff04ff05ff8080808080ffff04ffff01ffffff81ff7fff81df81bfffffff02ffff03ffff09ff0bffff01818080ffff01ff04ff80ffff04ff05ff808080ffff01ff02ffff03ffff0aff0bff1880ffff01ff02ff1affff04ff02ffff04ffff02ffff03ffff0aff0bff1c80ffff01ff02ffff03ffff0aff0bff1480ffff01ff0880ffff01ff04ffff0effff18ffff011fff0b80ffff0cff05ff80ffff01018080ffff04ffff0cff05ffff010180ff80808080ff0180ffff01ff04ffff18ffff013fff0b80ffff04ff05ff80808080ff0180ff80808080ffff01ff04ff0bffff04ff05ff80808080ff018080ff0180ff04ffff0cff15ff80ff0980ffff04ffff0cff15ff0980ff808080ffff04ffff04ff05ff1380ffff04ff2bff808080ffff02ff16ffff04ff02ffff04ff09ffff04ffff02ff3effff04ff02ffff04ff15ff80808080ff8080808080ff02ffff03ffff09ffff0cff05ff80ffff010180ff1080ffff01ff02ff2effff04ff02ffff04ffff02ff3effff04ff02ffff04ffff0cff05ffff010180ff80808080ff80808080ffff01ff02ff12ffff04ff02ffff04ffff0cff05ffff010180ffff04ffff0cff05ff80ffff010180ff808080808080ff0180ff018080ff018080',
);

class CoinAnnouncementMessage {
  CoinAnnouncementMessage({
    required this.coinId,
    required this.message,
  });

  final Bytes coinId;

  final Bytes message;
}
