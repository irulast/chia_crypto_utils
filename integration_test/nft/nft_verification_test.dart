@Timeout(Duration(seconds: 120))

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  late ChiaEnthusiast nftHolder;
  late ChiaEnthusiast verifier;

  final inputMetadata = NftMetadata(
    dataUris: const [
      'https://www.chia.net/img/branding/chia-logo.svg',
    ],
    dataHash: Program.fromInt(0).hash(),
    metaUris: const [
      'https://www.chia.net/music/branding/chia-logo.svg',
    ],
  );

  setUp(() async {
    nftHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    verifier = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);

    await nftHolder.farmCoins();
  });

  final nftWalletService = NftWalletService();
  final standardWalletService = StandardWalletService();

  test('should create and make nft verifcation spend', () async {
    final targetPuzzleHash = nftHolder.puzzlehashes[1];
    final spendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: targetPuzzleHash,
      metadata: inputMetadata,
      fee: 50,
      coins: nftHolder.standardCoins,
      keychain: nftHolder.keychain,
      changePuzzlehash: nftHolder.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);

    await fullNodeSimulator.moveToNextBlock();

    await nftHolder.refreshCoins();

    final nftCoins = await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash);
    expect(nftCoins.single.metadata, inputMetadata);

    final nft = nftCoins.single;

    final proofSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          5000,
          verifier.firstPuzzlehash,
          memos: nft.getProofOfNft(nftHolder.keychain).toMemos(),
        ),
      ],
      coinsInput: nftHolder.standardCoins,
      keychain: nftHolder.keychain,
      changePuzzlehash: nftHolder.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(proofSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    await nftHolder.refreshCoins();

    final proofCoin = nftHolder.standardCoins.single;

    final proofSpend = await fullNodeSimulator.getParentSpend(proofCoin);

    final proofOfNft = ProofOfNft.maybeFromMemos(proofSpend!.memosSync);

    final isVerified = await proofOfNft!.verify(fullNodeSimulator);

    expect(isVerified.success, true);
  });
}
