import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  late ChiaEnthusiast nathan;
  late NftRecord nftRecord;
  final inputMetadata = NftMetadata(
    dataUris: const [
      'https://www.chia.net/img/branding/chia-logo.svg',
      'https://www.chia.net/img/a/chia-logo.svg',
      'https://www.chia.net/img/c/chia-logo.svg',
    ],
    dataHash: Program.fromInt(0).hash(),
    metaUris: const [
      'https://www.chia.net/music/branding/chia-logo.svg',
      'https://www.netflix.com',
      'https://www.sss.com',
    ],
    // metaHash: Program.fromInt(1).hash(),
    // licenseUris: const [
    //   'https://www.chia.net/video/branding/chia-logo.svg',
    //   'https://www.hulu.com'
    // ],
    // licenseHash: Program.fromInt(2).hash(),
    // editionNumber: 5,
    // editionTotal: 500,
  );
  final nftWalletService = NftWalletService();
  final dependentCoinWalletService = DependentCoinWalletService();

  setUp(() async {
    nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    await nathan.farmCoins();

    final targetPuzzleHash = nathan.puzzlehashes[1];
    final spendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: targetPuzzleHash,
      metadata: inputMetadata,
      fee: 50,
      coins: nathan.standardCoins,
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);

    await fullNodeSimulator.moveToNextBlock();

    await nathan.refreshCoins();

    nftRecord = (await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash)).single;
  });

  test('should create and spend dependent fee coin', () async {
    final nftSendBundle = nftWalletService.createSpendBundle(
      targetPuzzlehash: nathan.firstPuzzlehash,
      nftCoin: nftRecord.toNft(nathan.keychain),
      keychain: nathan.keychain,
    );

    final dependentCoinsAndCreationBundle =
        dependentCoinWalletService.createGenerateDependentCoinsSpendBundle(
      amountPerCoin: 50,
      primaryCoinInfos: [PrimaryCoinInfo.fromNft(nftRecord)],
      coins: nathan.standardCoins,
      keychain: nathan.keychain,
      changePuzzleHash: nathan.firstPuzzlehash,
    );

    final dependentCoin = dependentCoinsAndCreationBundle.dependentCoins.first;

    await fullNodeSimulator.pushTransaction(dependentCoinsAndCreationBundle.creationBundle);
    await fullNodeSimulator.moveToNextBlock();

    final dependentCoinFromBlockchain = await fullNodeSimulator.getCoinById(dependentCoin.id);

    expect(dependentCoin, dependentCoinFromBlockchain);

    final dependentFeeBundle = dependentCoinWalletService.createFeeCoinSpendBundle(
      dependentCoin: dependentCoinsAndCreationBundle.dependentCoins.first,
    );

    await fullNodeSimulator.pushTransaction(nftSendBundle + dependentFeeBundle);
  });

  test('should fail to spend dependent coin if condition is not satisfied', () async {
    final dependentCoinsAndCreationBundle =
        dependentCoinWalletService.createGenerateDependentCoinsSpendBundle(
      amountPerCoin: 50,
      primaryCoinInfos: [PrimaryCoinInfo.fromNft(nftRecord)],
      coins: nathan.standardCoins,
      keychain: nathan.keychain,
      changePuzzleHash: nathan.firstPuzzlehash,
    );

    final dependentCoin = dependentCoinsAndCreationBundle.dependentCoins.first;

    await fullNodeSimulator.pushTransaction(dependentCoinsAndCreationBundle.creationBundle);
    await fullNodeSimulator.moveToNextBlock();

    final dependentCoinFromBlockchain = await fullNodeSimulator.getCoinById(dependentCoin.id);

    expect(dependentCoin, dependentCoinFromBlockchain);

    final dependentFeeBundle = dependentCoinWalletService.createFeeCoinSpendBundle(
      dependentCoin: dependentCoinsAndCreationBundle.dependentCoins.first,
    );
    // add pointless signature to avoid out of range full node bug
    final mockSignatureSpendBundle = SpendBundle(
      coinSpends: const [],
      signatures: {
        AugSchemeMPL.sign(
          nathan.firstWalletVector.childPrivateKey,
          [],
        ),
      },
    );

    expect(
      () async {
        await fullNodeSimulator.pushTransaction(mockSignatureSpendBundle + dependentFeeBundle);
      },
      throwsA(const TypeMatcher<AssertAnnouncementConsumeFailedException>()),
    );
  });
}
