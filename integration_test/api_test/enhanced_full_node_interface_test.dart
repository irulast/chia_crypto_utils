@Timeout(Duration(minutes: 5))

// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'enhanced_full_node_network_test.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final enhancedFullNodeHttpRpc = EnhancedFullNodeHttpRpc(
    SimulatorUtils.simulatorUrl,
  );

  final enhancedFullNode =
      EnhancedChiaFullNodeInterface(enhancedFullNodeHttpRpc);

  final fullNode = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final standardWalletService = StandardWalletService();

  final keychainSecret = KeychainCoreSecret.generate();

  final keychain =
      WalletKeychain.fromCoreSecret(keychainSecret, walletSize: 100);

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final senderPuzzlehash = keychain.unhardenedMap.values.toList()[0].puzzlehash;
  final senderAddress = Address.fromContext(senderPuzzlehash);
  final receiverPuzzlehash =
      keychain.unhardenedMap.values.toList()[1].puzzlehash;

  for (var i = 0; i < 4; i++) {
    await fullNode.farmCoins(senderAddress);
  }
  await fullNode.moveToNextBlock();

  final currentHeight = await fullNode.getBlockchainState().then(
        (value) => value!.peak!.height,
      );

  test('should correctly get paginated coins ', () async {
    for (var i = 0; i < 25; i++) {
      await fullNode
          .farmCoins(keychain.puzzlehashes.random.toAddressWithContext());
      await fullNode.moveToNextBlock();

      final coins =
          await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

      final spendBundle = standardWalletService.createSpendBundle(
        payments: [
          Payment(coins[0].amount, receiverPuzzlehash),
        ],
        coinsInput: [coins[0]],
        changePuzzlehash: senderPuzzlehash,
        keychain: keychain,
      );

      await fullNode.pushTransaction(spendBundle);
      await fullNode.moveToNextBlock();
    }

    final expectedCoins = await fullNode.getCoinsByPuzzleHashes(
      keychain.puzzlehashes,
      includeSpentCoins: true,
    );
    final expectedUnspentCoins = await Future.wait(
      expectedCoins.where((element) => element.isNotSpent).map((e) async {
        final parentSpend = await fullNode.getParentSpend(e);
        return CoinWithParentSpend(delegate: e, parentSpend: parentSpend);
      }),
    );

    print('expectedUnspentCoins: ${expectedUnspentCoins.length}');

    final expectedSpendCoins = <SpentCoin>[];

    for (final spentCoin in expectedCoins.where((element) => element.isSpent)) {
      final coinSpend = await fullNode.getCoinSpend(spentCoin);

      expectedSpendCoins.add(SpentCoin.fromCoinSpend(spentCoin, coinSpend!));
    }

    print('expectedSpentCoins: ${expectedSpendCoins.length}');

    final paginatedUnspentCoins = <CoinWithParentSpend>[];
    final paginatedSpentCoins = <SpentCoin>[];

    for (final puzzlehashes in keychain.puzzlehashes.splitIntoBatches(10)) {
      PaginatedCoins? paginatedResponse;
      Bytes? lastId;
      do {
        paginatedResponse =
            await enhancedFullNode.getCoinsByPuzzleHashesPaginated(
          puzzlehashes,
          5,
          includeSpentCoins: true,
          lastId: lastId,
        );

        expect(paginatedResponse.length, lessThanOrEqualTo(5));
        paginatedUnspentCoins.addAll(paginatedResponse.unspent);
        paginatedSpentCoins.addAll(paginatedResponse.spent);
        lastId = paginatedResponse.lastId;
      } while (paginatedResponse.length > 0);
    }
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

  test('should correctly get coins by hints with limit', () async {
    final hints = keychain.puzzlehashes;

    for (var i = 0; i < 20; i++) {
      await fullNode
          .farmCoins(keychain.puzzlehashes.random.toAddressWithContext());
      await fullNode.moveToNextBlock();

      final coins =
          await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

      final spendBundle = standardWalletService.createSpendBundle(
        payments: [
          Payment(coins[0].amount, receiverPuzzlehash,
              memos: <Bytes>[hints[i]]),
        ],
        coinsInput: [coins[0]],
        changePuzzlehash: senderPuzzlehash,
        keychain: keychain,
      );

      await fullNode.pushTransaction(spendBundle);
      await fullNode.moveToNextBlock();
    }

    final expectedCoins = await fullNode.getCoinsByHints(
      keychain.puzzlehashes,
      includeSpentCoins: true,
    );
    final expectedUnspentCoins = await Future.wait(
      expectedCoins.where((element) => element.isNotSpent).map((e) async {
        final parentSpend = await fullNode.getParentSpend(e);
        return CoinWithParentSpend(delegate: e, parentSpend: parentSpend);
      }),
    );

    print('expectedUnspentCoins: ${expectedUnspentCoins.length}');

    final expectedSpentCoins = <SpentCoin>[];

    for (final spentCoin in expectedCoins.where((element) => element.isSpent)) {
      final coinSpend = await fullNode.getCoinSpend(spentCoin);

      expectedSpentCoins.add(SpentCoin.fromCoinSpend(spentCoin, coinSpend!));
    }

    print('expectedSpentCoins: ${expectedSpentCoins.length}');

    final paginatedUnspentCoins = <CoinWithParentSpend>[];
    final paginatedSpentCoins = <SpentCoin>[];

    for (final puzzlehashes in keychain.puzzlehashes.splitIntoBatches(10)) {
      PaginatedCoins? paginatedResponse;
      Bytes? lastId;
      do {
        paginatedResponse = await enhancedFullNode.getCoinsByHintsPaginated(
          puzzlehashes,
          5,
          includeSpentCoins: true,
          lastId: lastId,
        );

        expect(paginatedResponse.length, lessThanOrEqualTo(5));
        paginatedUnspentCoins.addAll(paginatedResponse.unspent);
        paginatedSpentCoins.addAll(paginatedResponse.spent);
        lastId = paginatedResponse.lastId;
      } while (paginatedResponse.length > 0);
    }
    expectListEquality(
      expectedUnspentCoins,
      paginatedUnspentCoins,
      (item) =>
          item.toCoinBytes() + (item.parentSpend?.toBytes() ?? Bytes.empty),
    );

    expectListEquality(
      expectedSpentCoins,
      paginatedSpentCoins,
      (item) => item.toCoinBytes() + item.coinSpend.toBytes(),
    );

    await fullNode.moveToNextBlock();

    final coinSpends = await enhancedFullNode.getCoinSpendsByIds(
      expectedSpentCoins.map((e) => e.id).toList() + [Puzzlehash.zeros()],
    );

    for (final spentCoin in expectedSpentCoins) {
      expect(
          spentCoin.coinSpend.toBytes(), coinSpends[spentCoin.id]!.toBytes());
    }
  });
  group('Should additions with hints', () {
    for (final blockHeight in [for (var i = 1; i <= currentHeight; i++) i]) {
      test('at block height $blockHeight', () async {
        // print('testing block at height $blockHeight');
        final block = await fullNode.getBlockRecordByHeight(blockHeight);
        final additionsAndRemovals = await fullNode
            .getAdditionsAndRemovals(block.blockRecord!.headerHash);

        print('expected additions: ${additionsAndRemovals.additions.length}');
        print('expected removals: ${additionsAndRemovals.removals.length}');

        print(
          '$blockHeight: ${additionsAndRemovals.additions.length + additionsAndRemovals.removals.length}',
        );

        final additionsAndRemovalsWithHints = await enhancedFullNode
            .getAdditionsAndRemovalsWithHints(block.blockRecord!.headerHash);
        var progress = 0;

        for (final expectedItem in additionsAndRemovals.removals) {
          final matchingItemWithHint =
              (additionsAndRemovalsWithHints.removals).singleWhere(
            (element) => element.id == expectedItem.id,
          );
          final hint = matchingItemWithHint.hint;
          if (hint == null) {
            final spend = await fullNode.getParentSpend(expectedItem);
            if (spend == null) {
              continue;
            }
            final hint = spend.memosSync.firstWhereOrNull(
                (element) => element.length == Puzzlehash.bytesLength);

            expect(
              await fullNode
                  .getCoinsByHints([if (hint != null) Puzzlehash(hint)]),
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

  test('should correctly get coins by ids', () async {
    for (var i = 0; i < 20; i++) {
      await fullNode
          .farmCoins(keychain.puzzlehashes.random.toAddressWithContext());
    }
    final coins = (await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes,
            includeSpentCoins: true))
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
