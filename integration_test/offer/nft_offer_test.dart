import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  late ChiaEnthusiast offerMaker;

  late ChiaEnthusiast offerTaker;

  setUp(() async {
    offerMaker = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);
    offerTaker = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);

    await offerMaker.farmCoins();
    await offerTaker.farmCoins();
  });

  final nftWalletService = NftWalletService();
  final offerService = CatOfferWalletService();

  final dependentCoinService = DependentCoinWalletService();

  final inputMetadata = NftMetadata(
    dataUris: const ['https://www.chia.net/img/branding/chia-logo.svg'],
    dataHash: Program.fromInt(0).hash(),
    metaUris: const ['https://www.chia.net/music/branding/chia-logo.svg'],
    metaHash: Program.fromInt(1).hash(),
    editionNumber: 5,
    editionTotal: 50,
  );

  test('should generate and make nft offer', () async {
    final targetPuzzleHash = offerMaker.puzzlehashes[1];
    final spendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: targetPuzzleHash,
      metadata: inputMetadata,
      fee: 50,
      coins: offerMaker.standardCoins,
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);

    await fullNodeSimulator.moveToNextBlock();

    await offerMaker.refreshCoins();

    final nftCoins = await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash);
    expect(nftCoins.single.metadata, inputMetadata);

    final nft = nftCoins.single.toNft(offerMaker.keychain);

    final dependentCoinCreationBundle =
        dependentCoinService.createGenerateDependentCoinsSpendBundle(
      amountPerCoin: 100,
      primaryCoinInfos: [PrimaryCoinInfo.fromNft(nft)],
      coins: offerMaker.standardCoins,
      keychain: offerMaker.keychain,
      changePuzzleHash: offerMaker.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(dependentCoinCreationBundle.creationBundle);
    await fullNodeSimulator.moveToNextBlock();

    final dependentFeeCoinBundle = dependentCoinService.createFeeCoinSpendBundle(
      dependentCoin: dependentCoinCreationBundle.dependentCoins[0],
    );

    await offerMaker.refreshCoins();

    final offerMakerStartingBalance = offerMaker.standardCoins.totalValue;

    final nftForXchOffer = offerService
        .makeOffer(
          coinsForOffer:
              MixedCoins(nfts: [nft], standardCoins: offerMaker.standardCoins.sublist(0, 1)),
          keychain: offerMaker.keychain,
          requestedPayments:
              RequestedMixedPayments(standard: [Payment(5000, offerMaker.puzzlehashes.first)]),
          fee: 100,
          changePuzzlehash: offerMaker.firstPuzzlehash,
        )
        .withAdditionalBundle(dependentFeeCoinBundle);

    final takeTargetPuzzlehash = offerTaker.puzzlehashes.last;

    final takeOffer = offerService.takeOffer(
      askOffer: Offer.fromBech32(nftForXchOffer.toBech32()),
      puzzlehash: takeTargetPuzzlehash,
      keychain: offerTaker.keychain,
      changePuzzlehash: offerTaker.firstPuzzlehash,
      coinsForOffer: MixedCoins(
        standardCoins: offerTaker.standardCoins,
      ),
    );

    await fullNodeSimulator.pushTransaction(takeOffer.toSpendBundle());
    await fullNodeSimulator.moveToNextBlock();
    await fullNodeSimulator.moveToNextBlock();

    await offerMaker.refreshCoins();

    final offerMakerEndingBalance = offerMaker.standardCoins.totalValue;

    expect(offerMakerEndingBalance, offerMakerStartingBalance + 5000 - 100);

    final finalNfts = await fullNodeSimulator.getNftRecordsByHint(
      takeTargetPuzzlehash,
    );
    expect(finalNfts.single.metadata, inputMetadata);
  });

  test('should generate and make 0 cost did nft offer', () async {
    final didWalletService = DIDWalletService();
    final didWalletVector = offerMaker.keychain.unhardenedWalletVectors.last;
    final createDidSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: offerMaker.standardCoins.sublist(0, 1),
      targetPuzzleHash: didWalletVector.puzzlehash,
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(createDidSpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    final didInfo =
        (await fullNodeSimulator.getDidRecordsByPuzzleHashes(offerMaker.puzzlehashes)).single;
    await offerMaker.refreshCoins();
    final targetPuzzleHash = offerMaker.puzzlehashes[1];
    final spendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: targetPuzzleHash,
      metadata: inputMetadata,
      fee: 50,
      coins: offerMaker.standardCoins,
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
      targetDidInfo: didInfo.toDidInfoOrThrow(offerMaker.keychain),
    );

    await fullNodeSimulator.pushTransaction(spendBundle);

    await fullNodeSimulator.moveToNextBlock();

    await offerMaker.refreshCoins();

    final nftCoins = await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash);
    expect(nftCoins.single.metadata, inputMetadata);

    final nft = nftCoins.single.toNft(offerMaker.keychain);

    final dependentCoinCreationBundle =
        dependentCoinService.createGenerateDependentCoinsSpendBundle(
      amountPerCoin: 100,
      primaryCoinInfos: [PrimaryCoinInfo.fromNft(nft)],
      coins: offerMaker.standardCoins,
      keychain: offerMaker.keychain,
      changePuzzleHash: offerMaker.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(dependentCoinCreationBundle.creationBundle);
    await fullNodeSimulator.moveToNextBlock();

    final dependentFeeCoinBundle = dependentCoinService.createFeeCoinSpendBundle(
      dependentCoin: dependentCoinCreationBundle.dependentCoins[0],
    );

    final nftForXchOffer = offerService
        .makeOffer(
          coinsForOffer: MixedCoins(nfts: [nft]),
          keychain: offerMaker.keychain,
          payRoyalties: false,
        )
        .withAdditionalBundle(dependentFeeCoinBundle);

    final takeTargetPuzzlehash = offerTaker.puzzlehashes.last;

    final takeOffer = offerService.takeOffer(
      askOffer: Offer.fromBech32(nftForXchOffer.toBech32()),
      puzzlehash: takeTargetPuzzlehash,
      keychain: offerTaker.keychain,
    );

    await fullNodeSimulator.pushTransaction(takeOffer.toSpendBundle());
    await fullNodeSimulator.moveToNextBlock();
    await fullNodeSimulator.moveToNextBlock();

    final finalNfts = await fullNodeSimulator.getNftRecordsByHint(
      takeTargetPuzzlehash,
    );
    expect(finalNfts.single.metadata, inputMetadata);
  });

  test('should generate and make did nft offer', () async {
    final didWalletService = DIDWalletService();
    final didWalletVector = offerMaker.keychain.unhardenedWalletVectors.last;
    final createDidSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: offerMaker.standardCoins.sublist(0, 1),
      targetPuzzleHash: didWalletVector.puzzlehash,
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(createDidSpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    final didInfo =
        (await fullNodeSimulator.getDidRecordsByPuzzleHashes(offerMaker.puzzlehashes)).single;
    await offerMaker.refreshCoins();
    final targetPuzzleHash = offerMaker.puzzlehashes[1];
    final spendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: targetPuzzleHash,
      metadata: inputMetadata,
      fee: 50,
      coins: offerMaker.standardCoins,
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
      targetDidInfo: didInfo.toDidInfoOrThrow(offerMaker.keychain),
    );

    await fullNodeSimulator.pushTransaction(spendBundle);

    await fullNodeSimulator.moveToNextBlock();

    await offerMaker.refreshCoins();

    final nftCoins = await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash);
    expect(nftCoins.single.metadata.toProgram(), inputMetadata.toProgram());

    final nft = nftCoins.single.toNft(offerMaker.keychain);

    final dependentCoinCreationBundle =
        dependentCoinService.createGenerateDependentCoinsSpendBundle(
      amountPerCoin: 100,
      primaryCoinInfos: [PrimaryCoinInfo.fromNft(nft)],
      coins: offerMaker.standardCoins,
      keychain: offerMaker.keychain,
      changePuzzleHash: offerMaker.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(dependentCoinCreationBundle.creationBundle);
    await fullNodeSimulator.moveToNextBlock();

    final dependentFeeCoinBundle = dependentCoinService.createFeeCoinSpendBundle(
      dependentCoin: dependentCoinCreationBundle.dependentCoins[0],
    );
    await offerMaker.refreshCoins();
    final offerMakerStartingBalance = offerMaker.standardCoins.totalValue;

    final nftForXchOffer = (await offerMaker.offerService.createOffer(
      offeredAmounts: MixedAmounts(nft: {Puzzlehash(nft.launcherId)}),
      requestedPayments:
          RequestedMixedPayments(standard: [Payment(5000, offerMaker.puzzlehashes.first)]),
      changePuzzlehash: offerMaker.firstPuzzlehash,
    ))
        .withAdditionalBundle(dependentFeeCoinBundle);
    const fee = 100;
    final takeTargetPuzzlehash = offerTaker.puzzlehashes.last;

    final takeOffer = await offerTaker.offerService.createTakeOffer(
      nftForXchOffer,
      targetPuzzlehash: takeTargetPuzzlehash,
      changePuzzlehash: offerTaker.firstPuzzlehash,
      fee: fee,
    );

    await fullNodeSimulator.pushTransaction(takeOffer.toSpendBundle());
    await fullNodeSimulator.moveToNextBlock();

    final finalNfts = await fullNodeSimulator.getNftRecordsByHint(
      takeTargetPuzzlehash,
    );
    expect(finalNfts.single.metadata, inputMetadata);
    await offerMaker.refreshCoins();
    final offerMakerEndingBalance = offerMaker.standardCoins.totalValue;

    expect(offerMakerEndingBalance, offerMakerStartingBalance + 5000);
  });

  test('should generate and make did nft offer with cats', () async {
    final didWalletService = DIDWalletService();
    final didWalletVector = offerMaker.keychain.unhardenedWalletVectors.last;
    final createDidSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: offerMaker.standardCoins.sublist(0, 1),
      targetPuzzleHash: didWalletVector.puzzlehash,
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
    );
    final catAssetId = await offerTaker.issueMultiIssuanceCat();

    await fullNodeSimulator.pushTransaction(createDidSpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    final didInfo =
        (await fullNodeSimulator.getDidRecordsByPuzzleHashes(offerMaker.puzzlehashes)).single;
    await offerMaker.refreshCoins();

    print('royalty puzzlehash:${offerMaker.firstPuzzlehash}}');
    final targetPuzzleHash = offerMaker.puzzlehashes[1];
    final spendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: targetPuzzleHash,
      metadata: inputMetadata,
      fee: 50,
      coins: offerMaker.standardCoins,
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
      targetDidInfo: didInfo.toDidInfoOrThrow(offerMaker.keychain),
      royaltyPercentagePoints: 200,
      royaltyPuzzleHash: offerMaker.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);

    await fullNodeSimulator.moveToNextBlock();

    await offerMaker.refreshCoins();

    final nftCoins = await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash);
    expect(nftCoins.single.metadata, inputMetadata);

    final nft = nftCoins.single.toNft(offerMaker.keychain);

    const fee = 100;

    final nftForXchOffer = await offerMaker.offerService.createOffer(
      offeredAmounts: MixedAmounts(nft: {Puzzlehash(nft.launcherId)}),
      requestedPayments: RequestedMixedPayments(
        standard: [Payment(5000, offerMaker.puzzlehashes.first)],
        cat: {
          catAssetId: [CatPayment(500, offerMaker.firstPuzzlehash)],
        },
      ),
      changePuzzlehash: offerMaker.firstPuzzlehash,
    );

    final takeTargetPuzzlehash = offerTaker.puzzlehashes.last;

    final takeOffer = await offerTaker.offerService.createTakeOffer(
      Offer.fromBech32(nftForXchOffer.toBech32()),
      targetPuzzlehash: takeTargetPuzzlehash,
      changePuzzlehash: offerTaker.firstPuzzlehash,
      fee: fee,
    );

    await fullNodeSimulator.pushTransaction(takeOffer.toSpendBundle());
    await fullNodeSimulator.moveToNextBlock();
    await fullNodeSimulator.moveToNextBlock();

    final finalNfts = await fullNodeSimulator.getNftRecordsByHint(
      takeTargetPuzzlehash,
    );
    await offerMaker.refreshCoins();
    await offerTaker.refreshCoins();

    expect(offerMaker.catCoins.totalValue, 510);
    expect(finalNfts.single.metadata, inputMetadata);
  });

  test('did nft offer with royalties', () async {
    final didWalletService = DIDWalletService();
    final didWalletVector = offerMaker.keychain.unhardenedWalletVectors.last;
    final createDidSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: offerMaker.standardCoins.sublist(0, 1),
      targetPuzzleHash: didWalletVector.puzzlehash,
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(createDidSpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    final didInfo =
        (await fullNodeSimulator.getDidRecordsByPuzzleHashes(offerMaker.puzzlehashes)).single;

    final artist = ChiaEnthusiast(fullNodeSimulator);

    await offerMaker.refreshCoins();

    const royaltyPercentagePoints = 200;
    const royaltyPercentage = royaltyPercentagePoints / 10000;

    const requestedAmount = 1000000;

    final createNftSpendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: offerMaker.firstPuzzlehash,
      metadata: inputMetadata,
      fee: 0,
      coins: offerMaker.standardCoins.sublist(0, 1),
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
      targetDidInfo: didInfo.toDidInfoOrThrow(offerMaker.keychain),
      royaltyPercentagePoints: royaltyPercentagePoints,
      royaltyPuzzleHash: artist.firstPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(createNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await offerMaker.refreshCoins();

    final nfts = await fullNodeSimulator.getNftRecordsByHint(offerMaker.firstPuzzlehash);

    final nft = nfts.single.toNft(offerMaker.keychain);

    final offerMakerStartingBalance = offerMaker.standardCoins.totalValue;
    final offerTakerStartingBalance = offerTaker.standardCoins.totalValue;

    final nftForXchOffer = await offerMaker.offerService.createOffer(
      offeredAmounts: MixedAmounts(nft: {Puzzlehash(nft.launcherId)}),
      requestedPayments:
          RequestedMixedPayments(standard: [Payment(requestedAmount, offerMaker.firstPuzzlehash)]),
      changePuzzlehash: offerMaker.firstPuzzlehash,
    );

    final takeTargetPuzzlehash = offerTaker.puzzlehashes.last;

    const fee = 100;

    final takeOffer = await offerTaker.offerService.createTakeOffer(
      Offer.fromBech32(nftForXchOffer.toBech32()),
      targetPuzzlehash: takeTargetPuzzlehash,
      changePuzzlehash: offerTaker.firstPuzzlehash,
      fee: fee,
    );

    final spendBundle = takeOffer.toSpendBundle();
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final finalNfts = await fullNodeSimulator.getNftRecordsByHint(
      takeTargetPuzzlehash,
    );

    expect(finalNfts, isNotEmpty);

    await offerMaker.refreshCoins();
    await offerTaker.refreshCoins();
    await artist.refreshCoins();

    final offerMakerEndingBalance = offerMaker.standardCoins.totalValue;
    final offerTakerEndingBalance = offerTaker.standardCoins.totalValue;
    const expectedRoyaltyAmount = requestedAmount * royaltyPercentage;

    expect(
      offerTakerEndingBalance,
      offerTakerStartingBalance - requestedAmount - fee - expectedRoyaltyAmount,
    );

    expect(artist.standardCoins.totalValue, expectedRoyaltyAmount);

    expect(
      offerMakerEndingBalance,
      offerMakerStartingBalance + requestedAmount,
    );
  });

  test('did nft offer with cat royalties', () async {
    final didWalletService = DIDWalletService();
    final didWalletVector = offerMaker.keychain.unhardenedWalletVectors.last;
    final createDidSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: offerMaker.standardCoins.sublist(0, 1),
      targetPuzzleHash: didWalletVector.puzzlehash,
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
    );

    final catAssetId = await offerTaker.issueMultiIssuanceCat();

    await fullNodeSimulator.pushTransaction(createDidSpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    final didInfo =
        (await fullNodeSimulator.getDidRecordsByPuzzleHashes(offerMaker.puzzlehashes)).single;

    final artist = ChiaEnthusiast(fullNodeSimulator);

    const royaltyPercentagePoints = 200;
    const royaltyPercentage = royaltyPercentagePoints / 10000;
    const requestedStandardAmount = 1000000;
    const requestedCatAmount = 1000;
    await offerMaker.refreshCoins();
    final createNftSpendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: offerMaker.firstPuzzlehash,
      metadata: inputMetadata,
      fee: 0,
      coins: offerMaker.standardCoins.sublist(0, 1),
      keychain: offerMaker.keychain,
      changePuzzlehash: offerMaker.firstPuzzlehash,
      targetDidInfo: didInfo.toDidInfoOrThrow(offerMaker.keychain),
      royaltyPercentagePoints: 200,
      royaltyPuzzleHash: artist.firstPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(createNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await offerMaker.refreshCoins();

    final nfts = await fullNodeSimulator.getNftRecordsByHint(offerMaker.firstPuzzlehash);

    final offerMakerStartingCatBalance = offerMaker.catCoins.totalValue;
    final offerMakerStartingStandardBalance = offerMaker.standardCoins.totalValue;

    final nft = nfts.single.toNft(offerMaker.keychain);
    final nftForXchOffer = await offerMaker.offerService.createOffer(
      offeredAmounts: MixedAmounts(nft: {Puzzlehash(nft.launcherId)}),
      requestedPayments: RequestedMixedPayments(
        standard: [Payment(requestedStandardAmount, offerMaker.firstPuzzlehash)],
        cat: {
          catAssetId: [CatPayment(requestedCatAmount, offerMaker.firstPuzzlehash)],
        },
      ),
      changePuzzlehash: offerMaker.firstPuzzlehash,
    );

    final takeTargetPuzzlehash = offerTaker.puzzlehashes.last;

    final initialTakerStandardBalance = offerTaker.standardCoins.totalValue;
    final initialTakerCatBalance = offerTaker.catCoinMap[catAssetId]!.totalValue;

    const fee = 100;

    final takeOffer = await offerTaker.offerService.createTakeOffer(
      Offer.fromBech32(nftForXchOffer.toBech32()),
      targetPuzzlehash: takeTargetPuzzlehash,
      fee: fee,
      changePuzzlehash: offerTaker.firstPuzzlehash,
    );

    final spendBundle = takeOffer.toSpendBundle();
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final finalNfts = await fullNodeSimulator.getNftRecordsByHint(
      takeTargetPuzzlehash,
    );

    expect(finalNfts, isNotEmpty);

    await offerMaker.refreshCoins();
    await offerTaker.refreshCoins();
    await artist.refreshCoins();

    final offerTakerEndingStandardBalance = offerTaker.standardCoins.totalValue;
    final offerTakerEndingCatBalance = offerTaker.catCoinMap[catAssetId]!.totalValue;

    const standardRoyaltyAmount = royaltyPercentage * requestedStandardAmount;

    const catRoyaltyAmount = royaltyPercentage * requestedCatAmount;

    expect(
      offerTakerEndingStandardBalance,
      initialTakerStandardBalance - requestedStandardAmount - fee - standardRoyaltyAmount,
    );

    expect(
      offerTakerEndingCatBalance,
      initialTakerCatBalance - requestedCatAmount - catRoyaltyAmount,
    );

    final offerMakerEndingCatBalance = offerMaker.catCoins.totalValue;
    final offerMakerEndingStandardBalance = offerMaker.standardCoins.totalValue;

    expect(artist.standardCoins.totalValue, royaltyPercentage * requestedStandardAmount);
    expect(artist.catCoins.totalValue, royaltyPercentage * requestedCatAmount);

    expect(offerMakerEndingCatBalance, offerMakerStartingCatBalance + requestedCatAmount);
    expect(
      offerMakerEndingStandardBalance,
      offerMakerStartingStandardBalance + requestedStandardAmount,
    );
  });
}
