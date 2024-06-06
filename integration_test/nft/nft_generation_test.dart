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

  late ChiaEnthusiast nathan;
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

  setUp(() async {
    nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    await nathan.farmCoins();
  });

  final nftWalletService = NftWalletService();

  test('should create and send nft', () async {
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

    final nftCoins =
        await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash);
    expect(nftCoins.single.metadata, inputMetadata);

    final meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);

    await meera.farmCoins();

    final sendBundle = nftWalletService.createSpendBundle(
      targetPuzzlehash: meera.firstPuzzlehash,
      fee: 50,
      coinsForFee: nathan.standardCoins,
      nftCoin: nftCoins.single.toNft(nathan.keychain),
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(sendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final meeraNft =
        (await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash))
            .single;

    var nathanNfts =
        await fullNodeSimulator.getNftRecordsByHint(nathan.firstPuzzlehash);
    expect(nathanNfts, isEmpty);

    expect(meeraNft.metadata, inputMetadata);
    await meera.refreshCoins();

    final toNathanSpendBundle = nftWalletService.createSpendBundle(
      targetPuzzlehash: nathan.firstPuzzlehash,
      fee: 50,
      coinsForFee: meera.standardCoins,
      nftCoin: meeraNft.toNft(meera.keychain),
      keychain: meera.keychain,
      changePuzzlehash: meera.firstPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(toNathanSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    nathanNfts =
        await fullNodeSimulator.getNftRecordsByHint(nathan.firstPuzzlehash);

    expect(nathanNfts.single.metadata, inputMetadata);
  });
  test('should melt a cat and use result to mint an nft', () async {
    final user = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);
    final nftFaucet = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);

    await user.farmCoins();
    await nftFaucet.farmCoins();

    final catWalletService = Cat2WalletService();

    final catMintOriginCoin = nftFaucet.standardCoins.first;

    final issuanceResult =
        catWalletService.makeMeltableMultiIssuanceCatSpendBundle(
      genesisCoinId: catMintOriginCoin.id,
      standardCoins: [catMintOriginCoin],
      privateKey: nftFaucet.firstWalletVector.childPrivateKey,
      destinationPuzzlehash: user.puzzlehashes.first,
      changePuzzlehash: nftFaucet.puzzlehashes.first,
      amount: 10000,
      keychain: nftFaucet.keychain,
    );

    await fullNodeSimulator.pushTransaction(issuanceResult.spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    await user.refreshCoins();

    final meltOriginCoin = user.standardCoins.first;

    final nftFaucetPuzzlehash = nftFaucet.puzzlehashes[2];

    final meltSpendBundle = catWalletService.makeMeltingSpendBundle(
      catCoinToMelt: user.catCoins.first,
      standardCoinsForXchClaimingSpendBundle: [meltOriginCoin],
      puzzlehashToClaimXchTo: nftFaucetPuzzlehash,
      keychain: user.keychain,
      tailRunningInfo: issuanceResult.tailRunningInfo,
      standardOriginId: meltOriginCoin.id,
      changePuzzlehash: user.puzzlehashes.last,
      inputAmountToMelt: 101,
    );

    // check that cat is being melted

    final meltedAddition = meltSpendBundle.additions
        .where(
          (addition) =>
              addition.parentCoinInfo == meltOriginCoin.id &&
              addition.puzzlehash == nftFaucetPuzzlehash &&
              addition.amount > 51,
        )
        .first;

    final mintSpendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: nftFaucet.firstPuzzlehash,
      targetPuzzlehash: user.firstPuzzlehash,
      metadata: inputMetadata,
      fee: 50,
      coins: [meltedAddition],
      keychain: nftFaucet.keychain,
      changePuzzlehash: nftFaucet.firstPuzzlehash,
    );
    // move nft to cat sender's address

    await fullNodeSimulator.pushTransaction(meltSpendBundle + mintSpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    final nftCoins = await fullNodeSimulator.getNftRecordsByHint(
      user.firstPuzzlehash,
    );
    expect(nftCoins.single.metadata, inputMetadata);
    final mintInfo = await fullNodeSimulator
        .getNftMintInfoForLauncherId(nftCoins.single.launcherId);

    expect(mintInfo!.minterDid, null);
  });

  test('should generate did nft and transfer did ownership', () async {
    final didWalletService = DIDWalletService();
    final didWalletVector = nathan.keychain.unhardenedWalletVectors.last;
    final createDidSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: nathan.standardCoins.sublist(0, 1),
      targetPuzzleHash: didWalletVector.puzzlehash,
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    print(inputMetadata.toProgram());

    await fullNodeSimulator.pushTransaction(createDidSpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    var didInfo = (await fullNodeSimulator
            .getDidRecordsByPuzzleHashes(nathan.puzzlehashes))
        .single;

    await nathan.refreshCoins();
    final createNftSpendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: nathan.firstPuzzlehash,
      metadata: inputMetadata,
      fee: 0,
      coins: nathan.standardCoins.sublist(0, 1),
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
      targetDidInfo: didInfo.toDidInfo(nathan.keychain),
      royaltyPercentagePoints: 200,
    );

    // return;
    await fullNodeSimulator.pushTransaction(createNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final nfts =
        await fullNodeSimulator.getNftRecordsByHint(nathan.firstPuzzlehash);

    final meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);

    await meera.farmCoins();
    await meera.issueDid();

    didInfo = (await fullNodeSimulator.getDidRecordForDid(didInfo.did))!;

    ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

    final spendNftBundle = nftWalletService.createSpendBundle(
      targetPuzzlehash: meera.firstPuzzlehash,
      nftCoin: nfts.single.toNft(nathan.keychain),
      keychain: nathan.keychain,
    );

    BaseWalletService().validateSpendBundleSignature(spendNftBundle);

    await fullNodeSimulator.pushTransaction(spendNftBundle);
    await fullNodeSimulator.moveToNextBlock();

    var meeraNft =
        (await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash))
            .single;

    await fullNodeSimulator.pushTransaction(
      nftWalletService.createSpendBundle(
            targetPuzzlehash: meera.firstPuzzlehash,
            nftCoin: meeraNft.toNft(meera.keychain),
            keychain: meera.keychain,
            targetDidInfo: meera.didInfo,
          ) +
          nftWalletService.didWalletService.createSpendBundleFromPrivateKey(
            didInfo: meera.didInfo!,
            privateKey: meera.keychain
                .getWalletVectorOrThrow(meera.didInfo!.p2Puzzle.hash())
                .childPrivateKey,
            puzzlesToAnnounce: [meeraNft.launcherId],
          ),
    );

    await fullNodeSimulator.moveToNextBlock();
    meeraNft =
        (await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash))
            .single;

    final mintInfo = await fullNodeSimulator
        .getNftMintInfoForLauncherId(meeraNft.launcherId);

    expect(mintInfo!.minterDid, didInfo.did);
    expect(meeraNft.ownershipLayerInfo!.currentDid, meera.didInfo!.did);
  });

  test('should spend did multiple times then burn it', () async {
    final meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);

    await meera.farmCoins();
    final didWalletService = DIDWalletService();
    final didWalletVector = nathan.keychain.unhardenedWalletVectors.last;
    final createDidSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: nathan.standardCoins.sublist(0, 1),
      targetPuzzleHash: didWalletVector.puzzlehash,
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(createDidSpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    final did = (await fullNodeSimulator
            .getDidRecordsFromHint(didWalletVector.puzzlehash))
        .single
        .did;

    for (var i = 0; i < 5; i++) {
      final didInfo = await fullNodeSimulator.getDidRecordFromHint(
        didWalletVector.puzzlehash,
        did,
      );

      final didMessagesSpendBundle = didWalletService.createSpendBundle(
        didInfo: didInfo!.toDidInfoOrThrow(nathan.keychain),
        keychain: nathan.keychain,
      );

      await fullNodeSimulator.pushTransaction(didMessagesSpendBundle);

      await fullNodeSimulator.moveToNextBlock();
    }
    final didInfo = await fullNodeSimulator.getDidRecordFromHint(
      didWalletVector.puzzlehash,
      did,
    );

    final sendBundle = didWalletService.createSpendBundle(
      newP2Puzzlehash: meera.firstPuzzlehash,
      didInfo: didInfo!.toDidInfoOrThrow(nathan.keychain),
      keychain: nathan.keychain,
    );

    await fullNodeSimulator.pushTransaction(sendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final finalDid = await fullNodeSimulator.getDidRecordFromHint(
      didWalletVector.puzzlehash,
      did,
    );
    expect(finalDid, isNull);
  });

  test('should bulk mint nfts from did', () async {
    final didWalletService = DIDWalletService();
    final didWalletVector = nathan.keychain.unhardenedWalletVectors.last;
    final createDidSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: nathan.standardCoins.sublist(0, 1),
      targetPuzzleHash: didWalletVector.puzzlehash,
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(createDidSpendBundle);

    await fullNodeSimulator.moveToNextBlock();
    final didInfoOriginal = (await fullNodeSimulator
            .getDidRecordsByPuzzleHashes(nathan.puzzlehashes))
        .single;

    final did = didInfoOriginal.did;

    await nathan.refreshCoins();

    final didInfo = await fullNodeSimulator.getDidRecordForDid(did);

    final targetPuzzleHash = nathan.puzzlehashes.first;

    final bulkMintSpendBundle =
        nftWalletService.createDidNftBulkMintSpendBundle(
      minterPuzzlehash: targetPuzzleHash,
      nftMintData: await NftMintingDataWithHashes.makeUniformBulkMintData(
        uriHashProvider: MockUriHashProvider(),
        dataUri: inputMetadata.dataUris.first,
        metadataUri: inputMetadata.metaUris!.first,
        editionTotal: 10,
        totalNftsToMint: 10,
      ),
      fee: 50,
      coins: nathan.standardCoins.sublist(0, 1),
      keychain: nathan.keychain,
      targetDidInfo: didInfo!.toDidInfoOrThrow(nathan.keychain),
      editionTotal: 10,
      changePuzzlehash: targetPuzzleHash,
      targetPuzzlehash: targetPuzzleHash,
    );

    await fullNodeSimulator.pushTransaction(bulkMintSpendBundle);

    await fullNodeSimulator.moveToNextBlock();
    final nftRecords =
        await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash);
    final mintedNftRecords = nftRecords.where(
      (element) => bulkMintSpendBundle.additions.contains(element.coin),
    );
    expect(mintedNftRecords.length, 10);
    final mirror = ChiaEnthusiast(fullNodeSimulator);
    var expectedEditionNumber = 1;
    for (final nftRecord in mintedNftRecords.toList()
      ..sort((a, b) => a.metadata.editionNumber! - b.metadata.editionNumber!)) {
      expect(nftRecord.metadata.editionNumber, expectedEditionNumber);
      final sendBundle = nftWalletService.createSpendBundle(
        targetPuzzlehash: mirror.firstPuzzlehash,
        nftCoin: nftRecord.toNft(nathan.keychain),
        keychain: nathan.keychain,
      );
      await fullNodeSimulator.pushTransaction(sendBundle);
      expectedEditionNumber++;
    }

    await fullNodeSimulator.moveToNextBlock();
    final sentNfts =
        await fullNodeSimulator.getNftRecordsByHint(mirror.firstPuzzlehash);
    expect(sentNfts.length, 10);
  });

  test('should bulk mint nfts from did with no edition numbers', () async {
    final didWalletService = DIDWalletService();
    final didWalletVector = nathan.keychain.unhardenedWalletVectors.last;
    final createDidSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: nathan.standardCoins.sublist(0, 1),
      targetPuzzleHash: didWalletVector.puzzlehash,
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(createDidSpendBundle);

    await fullNodeSimulator.moveToNextBlock();
    final didInfoOriginal = (await fullNodeSimulator
            .getDidRecordsByPuzzleHashes(nathan.puzzlehashes))
        .single;

    final did = didInfoOriginal.did;

    await nathan.refreshCoins();

    final didInfo = await fullNodeSimulator.getDidRecordForDid(did);

    final targetPuzzleHash = nathan.puzzlehashes.first;

    final bulkMintSpendBundle =
        nftWalletService.createDidNftBulkMintSpendBundle(
      minterPuzzlehash: targetPuzzleHash,
      nftMintData: [
        for (var i = 0; i < 10; i++)
          await NftMintingData.unEditioned(
            dataUri: inputMetadata.dataUris.first,
            metaUri: inputMetadata.metaUris!.first,
            mintNumber: i,
          ).attachHashes(MockUriHashProvider()),
      ],
      fee: 50,
      coins: nathan.standardCoins.sublist(0, 1),
      keychain: nathan.keychain,
      targetDidInfo: didInfo!.toDidInfoOrThrow(nathan.keychain),
      changePuzzlehash: targetPuzzleHash,
      editionTotal: null,
      targetPuzzlehash: targetPuzzleHash,
    );

    await fullNodeSimulator.pushTransaction(bulkMintSpendBundle);

    await fullNodeSimulator.moveToNextBlock();
    final nftRecords =
        await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash);
    final mintedNftRecords = nftRecords.where(
      (element) => bulkMintSpendBundle.additions.contains(element.coin),
    );
    expect(mintedNftRecords.length, 10);
    final mirror = ChiaEnthusiast(fullNodeSimulator);

    for (final nftRecord in mintedNftRecords) {
      expect(nftRecord.metadata.editionNumber, null);
      expect(nftRecord.metadata.editionTotal, null);

      final sendBundle = nftWalletService.createSpendBundle(
        targetPuzzlehash: mirror.firstPuzzlehash,
        nftCoin: nftRecord.toNft(nathan.keychain),
        keychain: nathan.keychain,
      );
      await fullNodeSimulator.pushTransaction(sendBundle);
    }

    await fullNodeSimulator.moveToNextBlock();
    final sentNfts =
        await fullNodeSimulator.getNftRecordsByHint(mirror.firstPuzzlehash);
    expect(sentNfts.length, 10);
  });
}
