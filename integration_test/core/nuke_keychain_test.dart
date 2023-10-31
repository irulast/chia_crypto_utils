@Timeout(Duration(seconds: 120))

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/command/core/nuke_keychain.dart';
import 'package:test/test.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final enhancedFullNodeHttpRpc = EnhancedFullNodeHttpRpc(
    SimulatorUtils.simulatorUrl,
  );

  final fullNode = EnhancedChiaFullNodeInterface(enhancedFullNodeHttpRpc);

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  final blockchainUtils = SimulatorBlockchainUtils(fullNodeSimulator);

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  late ChiaEnthusiast nathan;

  setUp(() async {
    nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    await nathan.farmCoins(10);
    await nathan.issueDid();
    await nathan.issueMultiIssuanceCat();
    await nathan.issueMultiIssuanceCat();
    await nathan.issueMultiIssuanceCat();
    await nathan.issueMultiIssuanceCat();

    final nftBulkMintSpendBundle = NftWalletService().createDidNftBulkMintSpendBundle(
      targetPuzzlehash: nathan.puzzlehashes.first,
      nftMintData: await NftMintingDataWithHashes.makeUniformBulkMintData(
        uriHashProvider: MockUriHashProvider(),
        dataUri: 'nathan.com',
        metadataUri: 'nathan_meta.com',
        editionTotal: 50,
        totalNftsToMint: 10,
      ),
      fee: 100,
      coins: nathan.standardCoins.sublist(0, 2),
      keychain: nathan.keychain,
      targetDidInfo: nathan.didInfo!,
      changePuzzlehash: nathan.firstPuzzlehash,
      editionTotal: 50,
    );
    await fullNode.pushTransaction(nftBulkMintSpendBundle);

    final meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);

    await meera.farmCoins();
    await nathan.refreshCoins();

    for (var i = 0; i < 5; i++) {
      try {
        await nathan.issueDid();
      } on Exception {
        // pass
      }
      await nathan.refreshCoins();

      await fullNodeSimulator.moveToNextBlock();
    }
    for (var i = 0; i < 5; i++) {
      await meera.issueMultiIssuanceCat();
      await fullNodeSimulator.pushTransaction(
        Cat2WalletService().createSpendBundle(
          payments: [CatPayment(meera.catCoins.totalValue, nathan.puzzlehashes[i])],
          catCoinsInput: meera.catCoins,
          keychain: meera.keychain,
        ),
      );
      await fullNodeSimulator.moveToNextBlock();
    }

    await fullNodeSimulator.moveToNextBlock();
    await nathan.refreshCoins();
  });

  test('should successfully nuke keychain', () async {
    final initialCats = await fullNode.getCatCoinsByHints(nathan.puzzlehashes);
    expect(initialCats.length, 9);
    final initialStandardCoins = nathan.standardCoins;
    expect(initialStandardCoins.length, 19);

    final initialNfts = await fullNode.getNftRecordsByHints(nathan.puzzlehashes);
    final initialDids = await fullNode.getDidRecordsByHints(nathan.puzzlehashes);
    expect(initialNfts.length, 10);
    expect(initialDids.length, 6);

    await nukeKeychain(
      keychain: nathan.keychain,
      fullNode: fullNode,
      blockchainUtils: blockchainUtils,
      feePerCoin: 0,
      burnBundleSize: 2,
    );

    await nathan.refreshCoins();

    final endingCats = nathan.catCoins;
    final endingStandardCoins = nathan.standardCoins;
    final endingNfts = await fullNode.getNftRecordsByHints(nathan.puzzlehashes);
    final endingDids = await fullNode.getDidRecordsByHints(nathan.puzzlehashes);

    expect(endingNfts, isEmpty);
    expect(endingDids, isEmpty);

    expect(endingCats, isEmpty);
    expect(endingStandardCoins, isEmpty);
  });
}
