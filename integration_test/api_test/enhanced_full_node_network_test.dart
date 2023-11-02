@Timeout(Duration(minutes: 10))
@Skip('interacts with live full node')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

import 'test_wallets.dart';

void main() {
  const url = 'FULL_NODE_URL';

  const enhancedFullNodeHttpRpc =
      EnhancedFullNodeHttpRpc(url, timeout: Duration(seconds: 30));
  const enhancedFullNode =
      EnhancedChiaFullNodeInterface(enhancedFullNodeHttpRpc);

  const fullNodeRpc = FullNodeHttpRpc(
    url,
    timeout: Duration(seconds: 30),
  );

  const fullNode = ChiaFullNodeInterface(fullNodeRpc);

  final puzzlehashes = mediumWallet;

  const pageSize = 20;

  group('Should get paginated coins correctly', () {
    for (final blockRange in <List<int?>>[
      [null, 3468715],
      [3068715, 3468715],
      [3468715, null],
      [3668715, 3768715],
      [null, 3768715],
      [null, null],
    ]) {
      final startHeight = blockRange[0];
      final endHeight = blockRange[1];
      test('between $startHeight and $endHeight', () async {
        final expectedCoins = await fullNode.getCoinsByPuzzleHashes(
          puzzlehashes,
          includeSpentCoins: true,
          startHeight: startHeight,
          endHeight: endHeight,
        );

        final expectedUnspentCoins = await Future.wait(
          expectedCoins.where((element) => element.isNotSpent).map((e) async {
            final parentSpend = await fullNode.getParentSpend(e);
            return CoinWithParentSpend(delegate: e, parentSpend: parentSpend);
          }),
        );

        final expectedSpendCoins = <SpentCoin>[];

        for (final spentCoin
            in expectedCoins.where((element) => element.isSpent)) {
          final coinSpend = await enhancedFullNode.getCoinSpend(spentCoin);

          expectedSpendCoins
              .add(SpentCoin.fromCoinSpend(spentCoin, coinSpend!));
        }

        final paginatedUnspentCoins = <CoinWithParentSpend>[];
        final paginatedSpentCoins = <SpentCoin>[];
        PaginatedCoins? paginatedResponse;
        Bytes? lastId;
        do {
          paginatedResponse =
              await enhancedFullNode.getCoinsByPuzzleHashesPaginated(
            puzzlehashes,
            pageSize,
            startHeight: startHeight,
            endHeight: endHeight,
            includeSpentCoins: true,
            lastId: lastId,
          );

          expect(paginatedResponse.length, lessThanOrEqualTo(pageSize));
          paginatedUnspentCoins.addAll(paginatedResponse.unspent);
          paginatedSpentCoins.addAll(paginatedResponse.spent);
          lastId = paginatedResponse.lastId;
        } while (paginatedResponse.length > 0);

        expectListEquality(
          expectedUnspentCoins,
          paginatedUnspentCoins,
          (item) =>
              item.toCoinBytes() + (item.parentSpend?.toBytes() ?? Bytes.empty),
        );

        expectListEquality(
          expectedSpendCoins,
          paginatedSpentCoins,
          (item) => item.toCoinBytes() + item.coinSpend.toBytes(),
        );
      });
    }
  });
  group('Should get hinted paginated coins correctly', () {
    for (final blockRange in <List<int?>>[
      [null, 3468715],
      [3068715, 3468715],
      [3468715, null],
      [3668715, 3768715],
      [null, 3768715],
      [null, null],
    ]) {
      final startHeight = blockRange[0];
      final endHeight = blockRange[1];
      test('between $startHeight and $endHeight', () async {
        final expectedCoins = await fullNode.getCoinsByHints(
          puzzlehashes,
          includeSpentCoins: true,
          startHeight: startHeight,
          endHeight: endHeight,
        );
        final expectedUnspentCoins = await Future.wait(
          expectedCoins.where((element) => element.isNotSpent).map((e) async {
            final parentSpend = await fullNode.getParentSpend(e);
            return CoinWithParentSpend(delegate: e, parentSpend: parentSpend);
          }),
        );

        final expectedSpendCoins = <SpentCoin>[];

        for (final spentCoin
            in expectedCoins.where((element) => element.isSpent)) {
          final coinSpend = await enhancedFullNode.getCoinSpend(spentCoin);

          expectedSpendCoins
              .add(SpentCoin.fromCoinSpend(spentCoin, coinSpend!));
        }

        final paginatedUnspentCoins = <CoinWithParentSpend>[];
        final paginatedSpentCoins = <SpentCoin>[];
        PaginatedCoins? paginatedResponse;
        Bytes? lastId;
        do {
          paginatedResponse = await enhancedFullNode.getCoinsByHintsPaginated(
            puzzlehashes,
            pageSize,
            startHeight: startHeight,
            endHeight: endHeight,
            includeSpentCoins: true,
            lastId: lastId,
          );

          expect(paginatedResponse.length, lessThanOrEqualTo(pageSize));
          paginatedUnspentCoins.addAll(paginatedResponse.unspent);
          paginatedSpentCoins.addAll(paginatedResponse.spent);
          lastId = paginatedResponse.lastId;
        } while (paginatedResponse.length > 0);
        expectListEquality(
          expectedUnspentCoins,
          paginatedUnspentCoins,
          (item) =>
              item.toCoinBytes() + (item.parentSpend?.toBytes() ?? Bytes.empty),
        );

        expectListEquality(
          expectedSpendCoins,
          paginatedSpentCoins,
          (item) => item.toCoinBytes() + item.coinSpend.toBytes(),
        );
      });
    }
  });

  group('Should additions with hints', () {
    for (final blockHeight in [3669078]) {
      test('at block height $blockHeight', () async {
        // print('testing block at height $blockHeight');
        final block = await fullNode.getBlockRecordByHeight(blockHeight);
        final additionsAndRemovals = await fullNode
            .getAdditionsAndRemovals(block.blockRecord!.headerHash);

        print(
          '$blockHeight: ${additionsAndRemovals.additions.length + additionsAndRemovals.removals.length}',
        );

        final additionsAndRemovalsWithHints = await enhancedFullNode
            .getAdditionsAndRemovalsWithHints(block.blockRecord!.headerHash);
        var progress = 0;

        for (final expectedItem
            in additionsAndRemovals.removals + additionsAndRemovals.additions) {
          final matchingItemWithHint =
              (additionsAndRemovalsWithHints.removals).singleWhere(
            (element) => element.id == expectedItem.id,
            orElse: () => additionsAndRemovalsWithHints.additions.singleWhere(
              (element) => element.id == expectedItem.id,
            ),
          );
          final hint = matchingItemWithHint.hint;
          if (hint == null) {
            final spend = await fullNode.getParentSpend(expectedItem);
            if (spend == null) {
              continue;
            }
            expect(
              spend.memosSync
                  .where((element) => element.length == Puzzlehash.bytesLength),
              isEmpty,
            );
          } else if (hint.length < Puzzlehash.bytesLength) {
            print('weird hint: ${matchingItemWithHint.hint}');
          } else {
            final now = DateTime.now();
            List<Coin>? coins;
            try {
              coins = await enhancedFullNode.getCoinsByHints(
                [Puzzlehash(hint)],
                includeSpentCoins: expectedItem.isSpent,
                startHeight: expectedItem.confirmedBlockIndex,
                endHeight: expectedItem.confirmedBlockIndex + 1,
              );
            } catch (e) {
              print(e);
            }

            final then = DateTime.now();

            if (then.difference(now) > const Duration(seconds: 15)) {
              print('long hint: $hint');
            }
            coins!.singleWhere((value) => value.id == expectedItem.id);
          }
          progress++;
          print(
            '${progress / (additionsAndRemovals.removals.length + additionsAndRemovals.additions.length) * 100}%',
          );
        }
      });
    }
  });

  test('should correctly get coin spends', () async {
    final spentCoins = (await fullNode.getCoinsByPuzzleHashes(
      puzzlehashes,
      includeSpentCoins: true,
    ))
        .where((element) => element.isSpent);

    final coinSpends = await enhancedFullNode.getCoinSpendsByIds(
      spentCoins.map((e) => e.id).toList() + [Puzzlehash.zeros()],
    );

    for (final spentCoin in spentCoins) {
      final fetchedCoinSpend = await fullNode.getCoinSpend(spentCoin);
      expect(coinSpends[spentCoin.id]!.toHex(), fetchedCoinSpend!.toHex());
    }
  });

  test('should correctly get coins by ids', () async {
    final coins = (await fullNode.getCoinsByPuzzleHashes(
      puzzlehashes,
      includeSpentCoins: true,
    ))
        .toList();

    final then = DateTime.now();

    final coinsByIds = await enhancedFullNode.getCoinsByIds(
      coins.map((e) => e.id).toList(),
      includeSpentCoins: true,
    );

    final now = DateTime.now();
    print(now.difference(then));

    expectListEquality(
      coinsByIds,
      coins,
      (item) => item.toCoinBytes(),
    );
  });
}

void expectListEquality<T>(
  List<T> expectedList,
  List<T> actualList,
  dynamic Function(T item) getAttributeToCompare,
) {
  expect(actualList.length, expectedList.length);

  for (final expectedItem in expectedList) {
    if (!actualList.any(
      (actualItem) =>
          getAttributeToCompare(expectedItem) ==
          getAttributeToCompare(actualItem),
    )) {
      throw Exception(
        'could not find expected item ${getAttributeToCompare(expectedItem)} in ${actualList.map(getAttributeToCompare).toList()}',
      );
    }
    expect(
      actualList.any(
        (actualItem) =>
            getAttributeToCompare(expectedItem) ==
            getAttributeToCompare(actualItem),
      ),
      true,
    );
  }
}
