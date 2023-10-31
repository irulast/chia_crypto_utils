@Skip('These tests should be run manually, as they depend on the WalletConnect relay server')
@Timeout(Duration(minutes: 5))
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';
import 'package:walletconnect_flutter_v2/apis/core/core.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/session_models.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:walletconnect_flutter_v2/apis/web3wallet/web3wallet.dart';

// If one of these tests is taking a while or times out, try running it again. This could be an issue
// with the relay.
Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final enhancedFullNodeHttpRpc = EnhancedFullNodeHttpRpc(
    SimulatorUtils.simulatorUrl,
  );

  final enhancedFullNodeInterface = EnhancedChiaFullNodeInterface(enhancedFullNodeHttpRpc);

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final nftWalletService = NftWalletService();
  final catOfferService = CatOfferWalletService();

  const message = 'hello, world';
  const catAmount = 1000;
  const standardAmount = 10000000;
  const fee = 50;

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
  );

  late ChiaEnthusiast meera;
  late ChiaEnthusiast nathan;
  late int fingerprint;
  late NftInfo nftInfo;
  late NftRecord nftRecord;
  late Puzzlehash meeraCoinAssetId;
  late WalletConnectWalletClient walletClient;
  late WalletConnectAppClient appClient;
  late SessionData sessionData;
  late FullNodeWalletConnectRequestHandler requestHandler;
  late Map<int, ChiaWalletInfo> walletMap;
  setUp(() async {
    // set up wallet with standard coins, cat, did, and nft
    meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);

    await meera.farmCoins(5);

    meeraCoinAssetId = await meera.issueMultiIssuanceCat();
    meera.keychain.addOuterPuzzleHashesForAssetId(meeraCoinAssetId);

    await meera.issueDid([Program.fromBool(true).hash()]);

    final spendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: meera.firstPuzzlehash,
      metadata: inputMetadata,
      fee: 50,
      coins: [meera.standardCoins.first],
      keychain: meera.keychain,
      changePuzzlehash: meera.firstPuzzlehash,
      targetDidInfo: meera.didInfo,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);

    await fullNodeSimulator.moveToNextBlock();

    nftRecord = (await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash)).single;

    final nftRecordWithMintInfo = (await nftRecord.fetchMintInfo(fullNodeSimulator))!;

    nftInfo = NftInfo.fromNftRecordWithMintInfo(nftRecordWithMintInfo);

    nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);
    await nathan.farmCoins();

    await meera.refreshCoins();
    await nathan.refreshCoins();

    // set up WalletConnect wallet client
    final walletCore = Core(projectId: testWalletProjectId);
    final web3Wallet = Web3Wallet(core: walletCore, metadata: defaultPairingMetadata);

    fingerprint = meera.keychainSecret.fingerprint;

    requestHandler = FullNodeWalletConnectRequestHandler(
      coreSecret: meera.keychainSecret,
      keychain: meera.keychain,
      fullNode: enhancedFullNodeInterface,
    );

    await requestHandler.initializeWalletMap();
    walletMap = requestHandler.walletInfoMap!;

    walletClient = WalletConnectWalletClient(
      web3Wallet,
    )
      ..registerProposalHandler(
        (sessionProposal) async => [fingerprint],
      )
      ..registerRequestHandler(requestHandler);

    await walletClient.init();

    // set up WalletConnect app client
    final appCore = Core(projectId: walletConnectProjectId);
    final web3App = Web3App(core: appCore, metadata: defaultPairingMetadata);

    appClient = WalletConnectAppClient(web3App, (Uri uri) async {
      await walletClient.pair(uri);
    });

    await appClient.init();

    // pair with wallet client
    sessionData = await appClient.pair();
  });

  tearDown(() async {
    await walletClient.disconnectPairing(sessionData.pairingTopic);
  });

  test('Should request and receive current address data', () async {
    final response = await appClient.getCurrentAddress(fingerprint: fingerprint);

    expect(response.address, equals(meera.firstPuzzlehash.toAddressWithContext()));
  });

  test('Should make request and throw exception when request is rejected', () async {
    requestHandler.approveRequest = false;

    expect(
      () async => {await appClient.getCurrentAddress(fingerprint: fingerprint)},
      throwsA(isA<ErrorResponseException>()),
    );
  });

  test('Should request and receive next address data', () async {
    final initialLastIndex = meera.puzzlehashes.length - 1;

    final response = await appClient.getNextAddress(fingerprint: fingerprint);

    final expectedNewAddress = meera.puzzlehashes[initialLastIndex + 1].toAddressWithContext();

    expect(response.address.address, equals(expectedNewAddress.address));
  });

  test('Should request and receive NFT info', () async {
    final response =
        await appClient.getNFTInfo(fingerprint: fingerprint, coinId: nftInfo.nftCoinId);

    expect(response.nftInfo.toJson(), equals(nftInfo.toJson()));
  });

  test('Should request and receive NFTs data', () async {
    final nftWalletIds = walletMap.nftWallets().keys.toList();

    final response = await appClient.getNFTs(fingerprint: fingerprint, walletIds: nftWalletIds);

    expect(response.nfts.length, equals(1));
    expect(response.nfts.entries.single.value.single.toJson(), equals(nftInfo.toJson()));
  });

  test('Should request and receive paginated NFTs data', () async {
    final nftWalletIds = walletMap.nftWallets().keys.toList();

    final response = await appClient.getNFTs(
      fingerprint: fingerprint,
      walletIds: nftWalletIds,
      startIndex: 0,
      num: 3,
    );

    expect(response.nfts.length, equals(1));
  });

  test('Should request and receive NFT count data', () async {
    final response = await appClient.getNFTsCount(
      fingerprint: fingerprint,
      walletIds: List<int>.generate(walletMap.length, (i) => i + 1),
    );

    expect(response.total, equals(1));
    expect(response.countData.entries.first.value, equals(1));
  });

  test('Should request and receive sync status', () async {
    final response = await appClient.getSyncStatus(fingerprint: fingerprint);

    expect(response.syncStatusData.synced, isTrue);
    expect(response.syncStatusData.syncing, isFalse);
    expect(response.syncStatusData.genesisInitialized, isTrue);
  });

  test('Should request and receive wallet balance data', () async {
    final response = await appClient.getWalletBalance(fingerprint: fingerprint);

    expect(response.balance.confirmedWalletBalance, equals(meera.standardCoins.totalValue));
    expect(response.balance.fingerprint, equals(fingerprint));
    expect(response.balance.pendingChange, equals(0));
    expect(response.balance.pendingCoinRemovalCount, equals(0));
    expect(response.balance.pendingChange, equals(0));
    expect(response.balance.spendableBalance, equals(meera.standardCoins.totalValue));
    expect(response.balance.unconfirmedWalletBalance, equals(meera.standardCoins.totalValue));
    expect(response.balance.unspentCoinCount, equals(meera.standardCoins.length));
    expect(response.balance.walletId, equals(1));
    expect(response.balance.walletType, equals(ChiaWalletType.standard));
  });

  test('Should request and receive wallets data', () async {
    final response = await appClient.getWallets(fingerprint: fingerprint);

    expect(response.wallets.length, equals(4));

    final walletTypes = response.wallets.map((wallet) => wallet.type);

    final standardWallets = walletTypes.where((type) => type == ChiaWalletType.standard);
    final nftWallets = walletTypes.where((type) => type == ChiaWalletType.nft);
    final didWallets = walletTypes.where((type) => type == ChiaWalletType.did);
    final catWallets = walletTypes.where((type) => type == ChiaWalletType.cat);

    expect(standardWallets.length, equals(1));
    expect(nftWallets.length, equals(1));
    expect(didWallets.length, equals(1));
    expect(catWallets.length, equals(1));
  });

  test('Should make transaction request, wait for confirmation, and receive sent transaction data',
      () async {
    final meeraStartingBalance = meera.standardCoins.totalValue;
    final nathanStartingBalance = nathan.standardCoins.totalValue;

    fullNodeSimulator.run();

    final response = await appClient.sendTransaction(
      fingerprint: fingerprint,
      address: nathan.firstPuzzlehash.toAddressWithContext(),
      amount: standardAmount,
      fee: fee,
      waitForConfirmation: true,
    );

    fullNodeSimulator.stop();

    expect(response.sentTransactionData.success, isTrue);
    expect(response.sentTransactionData.transaction.amount, equals(standardAmount));
    expect(response.sentTransactionData.transaction.feeAmount, equals(fee));
    expect(response.sentTransactionData.transaction.toPuzzlehash, equals(nathan.firstPuzzlehash));
    expect(response.sentTransactionData.transaction.confirmed, isTrue);

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingBalance = meera.standardCoins.totalValue;
    final nathanEndingBalance = nathan.standardCoins.totalValue;

    expect(meeraEndingBalance, equals(meeraStartingBalance - fee - standardAmount));
    expect(nathanEndingBalance, equals(nathanStartingBalance + standardAmount));
  });

  test(
      'Should make a transaction request and receive sent transaction data without waiting for confirmation',
      () async {
    final meeraStartingBalance = meera.standardCoins.totalValue;
    final nathanStartingBalance = nathan.standardCoins.totalValue;

    final response = await appClient.sendTransaction(
      fingerprint: fingerprint,
      address: nathan.firstPuzzlehash.toAddressWithContext(),
      amount: standardAmount,
      fee: fee,
    );

    expect(response.sentTransactionData.success, isTrue);
    expect(response.sentTransactionData.transaction.amount, equals(standardAmount));
    expect(response.sentTransactionData.transaction.feeAmount, equals(fee));
    expect(response.sentTransactionData.transaction.toPuzzlehash, equals(nathan.firstPuzzlehash));
    expect(response.sentTransactionData.transaction.confirmed, isFalse);

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingBalance = meera.standardCoins.totalValue;
    final nathanEndingBalance = nathan.standardCoins.totalValue;

    expect(meeraEndingBalance, equals(meeraStartingBalance - fee - standardAmount));
    expect(nathanEndingBalance, equals(nathanStartingBalance + standardAmount));
  });

  test('Should make a CAT transaction request and receive sent transaction data', () async {
    final meeraStartingCatBalance = meera.catCoins.totalValue;
    final nathanStartingCatBalance = nathan.catCoins.totalValue;

    final response = await appClient.sendTransaction(
      walletId: walletMap.catWallets().keys.first,
      fingerprint: fingerprint,
      address: nathan.firstPuzzlehash.toAddressWithContext(),
      amount: catAmount,
      fee: fee,
    );

    expect(response.sentTransactionData.success, isTrue);
    expect(response.sentTransactionData.transaction.amount, equals(catAmount));
    expect(response.sentTransactionData.transaction.feeAmount, equals(fee));
    expect(response.sentTransactionData.transaction.toPuzzlehash, equals(nathan.firstPuzzlehash));
    expect(response.sentTransactionData.transaction.confirmed, isFalse);

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingCatBalance = meera.catCoins.totalValue;
    final nathanEndingCatBalance = nathan.catCoins.totalValue;

    expect(meeraEndingCatBalance, equals(meeraStartingCatBalance - catAmount));
    expect(nathanEndingCatBalance, equals(nathanStartingCatBalance + catAmount));
  });

  test('Should make a NFT transaction request and receive data', () async {
    var meeraNfts = await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash);
    expect(meeraNfts.length, equals(1));

    var nathanNfts = await fullNodeSimulator.getNftRecordsByHint(nathan.firstPuzzlehash);
    expect(nathanNfts, isEmpty);

    final response = await appClient.sendTransaction(
      fingerprint: fingerprint,
      walletId: walletMap.nftWallets().keys.first,
      address: nathan.firstPuzzlehash.toAddressWithContext(),
      amount: 1,
      fee: 50,
    );

    expect(response.sentTransactionData.success, isTrue);
    expect(response.sentTransactionData.transaction.amount, equals(1));
    expect(response.sentTransactionData.transaction.feeAmount, equals(fee));
    expect(response.sentTransactionData.transaction.toPuzzlehash, equals(nathan.firstPuzzlehash));
    expect(response.sentTransactionData.transaction.confirmed, isFalse);

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    meeraNfts = await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash);
    expect(meeraNfts, isEmpty);

    nathanNfts = await fullNodeSimulator.getNftRecordsByHint(nathan.firstPuzzlehash);
    expect(nathanNfts.length, equals(1));
    expect(nathanNfts.single.launcherId, equals(nftInfo.launcherId));
  });

  test('Should make request to spend CAT and receive sent transaction data', () async {
    final meeraStartingCatBalance = meera.catCoins.totalValue;
    final nathanStartingCatBalance = nathan.catCoins.totalValue;

    final response = await appClient.spendCat(
      fingerprint: fingerprint,
      address: nathan.firstPuzzlehash.toAddressWithContext(),
      amount: catAmount,
      fee: fee,
      walletId: walletMap.catWallets().keys.first,
    );

    expect(response.sentTransactionData.success, isTrue);
    expect(response.sentTransactionData.transaction.amount, equals(catAmount));
    expect(response.sentTransactionData.transaction.feeAmount, equals(fee));
    expect(response.sentTransactionData.transaction.toPuzzlehash, equals(nathan.firstPuzzlehash));
    expect(response.sentTransactionData.transaction.confirmed, isFalse);

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingCatBalance = meera.catCoins.totalValue;
    final nathanEndingCatBalance = nathan.catCoins.totalValue;

    expect(meeraEndingCatBalance, equals(meeraStartingCatBalance - catAmount));
    expect(nathanEndingCatBalance, equals(nathanStartingCatBalance + catAmount));
  });

  test('Should request to take CAT for XCH offer and receive response', () async {
    final nathanStartingStandardBalance = nathan.standardCoins.totalValue;
    final nathanStartingCatBalance = nathan.catCoins.totalValue;
    final meeraStartingStandardBalance = meera.standardCoins.totalValue;
    final meeraStartingCatBalance = meera.catCoins.totalValue;

    final targetPuzzlehash = nathan.firstPuzzlehash;

    final offer = await nathan.offerService.createOffer(
      offeredAmounts: MixedAmounts(standard: standardAmount),
      changePuzzlehash: targetPuzzlehash,
      requestedPayments: RequestedMixedPayments(
        cat: {
          meeraCoinAssetId: [CatPayment(catAmount, targetPuzzlehash)],
        },
      ),
    );

    fullNodeSimulator.run();

    final response = await appClient.takeOffer(
      fingerprint: fingerprint,
      offer: offer.toBech32(),
      fee: fee,
    );

    fullNodeSimulator.stop();

    expect(response.takeOfferData.success, isTrue);
    expect(response.takeOfferData.tradeRecord.takenOffer, equals(offer.toBech32()));

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingStandardBalance = meera.standardCoins.totalValue;
    final meeraEndingCatBalance = meera.catCoins.totalValue;
    final nathanEndingStandardBalance = nathan.standardCoins.totalValue;
    final nathanEndingCatBalance = nathan.catCoins.totalValue;

    expect(
      meeraEndingStandardBalance,
      equals(meeraStartingStandardBalance + standardAmount - fee),
    );
    expect(meeraEndingCatBalance, equals(meeraStartingCatBalance - catAmount));

    expect(
      nathanEndingStandardBalance,
      equals(nathanStartingStandardBalance - standardAmount),
    );
    expect(nathanEndingCatBalance, equals(nathanStartingCatBalance + catAmount));
  });

  test('Should request to take XCH for CAT offer and receive response', () async {
    await nathan.issueMultiIssuanceCat();

    final nathanStartingStandardBalance = nathan.standardCoins.totalValue;
    final nathanStartingCatBalance = nathan.catCoins.totalValue;
    final meeraStartingStandardBalance = meera.standardCoins.totalValue;
    final meeraStartingCatBalance = meera.catCoins.totalValue;

    final nathanCoinAssetId = nathan.catCoinMap.keys.first;

    final targetPuzzlehash = nathan.firstPuzzlehash;

    final offer = catOfferService.makeOffer(
      coinsForOffer: MixedCoins(cats: nathan.catCoins, standardCoins: [nathan.standardCoins.first]),
      offeredAmounts: OfferedMixedAmounts(cat: {nathanCoinAssetId: catAmount}),
      changePuzzlehash: targetPuzzlehash,
      requestedPayments:
          RequestedMixedPayments(standard: [Payment(standardAmount, targetPuzzlehash)]),
      keychain: nathan.keychain,
      fee: fee,
    );

    fullNodeSimulator.run();

    final response = await appClient.takeOffer(
      fingerprint: fingerprint,
      offer: offer.toBech32(),
      fee: fee,
    );

    fullNodeSimulator.stop();

    expect(response.takeOfferData.success, isTrue);
    expect(response.takeOfferData.tradeRecord.takenOffer, equals(offer.toBech32()));

    await fullNodeSimulator.moveToNextBlock();

    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingStandardBalance = meera.standardCoins.totalValue;
    final meeraEndingCatBalance = meera.catCoins.totalValue;
    final nathanEndingStandardBalance = nathan.standardCoins.totalValue;
    final nathanEndingCatBalance = nathan.catCoins.totalValue;

    expect(
      meeraEndingStandardBalance,
      equals(meeraStartingStandardBalance - standardAmount - fee),
    );
    expect(meeraEndingCatBalance, equals(meeraStartingCatBalance + catAmount));

    expect(
      nathanEndingStandardBalance,
      equals(nathanStartingStandardBalance + standardAmount - fee),
    );
    expect(nathanEndingCatBalance, equals(nathanStartingCatBalance - catAmount));
  });

  test('Should request to take XCH for NFT offer and receive response', () async {
    // generate an NFT without owner DID for offer
    final spendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: meera.puzzlehashes[2],
      metadata: inputMetadata,
      fee: 50,
      coins: [meera.standardCoins.first],
      keychain: meera.keychain,
      changePuzzlehash: meera.puzzlehashes[1],
    );

    await fullNodeSimulator.pushTransaction(spendBundle);

    await fullNodeSimulator.moveToNextBlock();

    await meera.farmCoins();

    final requestedNftRecord =
        (await fullNodeSimulator.getNftRecordsByHint(meera.puzzlehashes[2])).single;

    final nathanStartingStandardBalance = nathan.standardCoins.totalValue;
    final meeraStartingStandardBalance = meera.standardCoins.totalValue;

    var nathanNfts = await enhancedFullNodeInterface.getNftRecordsByHints(nathan.puzzlehashes);
    expect(nathanNfts, isEmpty);

    final targetPuzzlehash = nathan.firstPuzzlehash;

    final offer = await nathan.offerService.createOffer(
      offeredAmounts: MixedAmounts(standard: standardAmount),
      changePuzzlehash: targetPuzzlehash,
      requestedPayments: RequestedMixedPayments(
        nfts: [NftRequestedPayment(targetPuzzlehash, requestedNftRecord)],
      ),
    );

    fullNodeSimulator.run();

    final response = await appClient.takeOffer(
      fingerprint: fingerprint,
      offer: offer.toBech32(),
      fee: fee,
    );

    fullNodeSimulator.stop();

    expect(response.takeOfferData.success, isTrue);
    expect(response.takeOfferData.tradeRecord.takenOffer, equals(offer.toBech32()));

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingStandardBalance = meera.standardCoins.totalValue;
    final nathanEndingStandardBalance = nathan.standardCoins.totalValue;

    expect(
      meeraEndingStandardBalance,
      equals(meeraStartingStandardBalance + standardAmount - fee),
    );

    expect(
      nathanEndingStandardBalance,
      equals(nathanStartingStandardBalance - standardAmount),
    );

    nathanNfts = await enhancedFullNodeInterface.getNftRecordsByHints(nathan.puzzlehashes);
    expect(nathanNfts.length, equals(1));
    expect(nathanNfts.single.launcherId, equals(requestedNftRecord.launcherId));
  });

  test('Should request to take NFT for XCH offer and receive response', () async {
    final spendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: nathan.puzzlehashes[1],
      metadata: inputMetadata,
      fee: 50,
      coins: [nathan.standardCoins.first],
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);

    await fullNodeSimulator.moveToNextBlock();

    await nathan.farmCoins();

    final offeredNftRecord =
        (await fullNodeSimulator.getNftRecordsByHint(nathan.puzzlehashes[1])).single;

    final offeredNft = offeredNftRecord.toNft(nathan.keychain);

    await fullNodeSimulator.moveToNextBlock();

    await nathan.refreshCoins();

    final nathanStartingStandardBalance = nathan.standardCoins.totalValue;
    final meeraStartingStandardBalance = meera.standardCoins.totalValue;

    var meeraNfts = await enhancedFullNodeInterface.getNftRecordsByHints(meera.puzzlehashes);
    expect(meeraNfts.length, equals(1));

    final targetPuzzlehash = nathan.firstPuzzlehash;

    final offer = catOfferService.makeOffer(
      coinsForOffer: MixedCoins(nfts: [offeredNft], standardCoins: [nathan.standardCoins.first]),
      changePuzzlehash: targetPuzzlehash,
      requestedPayments: RequestedMixedPayments(
        standard: [Payment(standardAmount, targetPuzzlehash)],
      ),
      keychain: nathan.keychain,
      fee: fee,
    );
    fullNodeSimulator.run();

    final response = await appClient.takeOffer(
      fingerprint: fingerprint,
      offer: offer.toBech32(),
      fee: fee,
    );

    fullNodeSimulator.stop();

    expect(response.takeOfferData.success, isTrue);
    expect(response.takeOfferData.tradeRecord.takenOffer, equals(offer.toBech32()));

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingStandardBalance = meera.standardCoins.totalValue;
    final nathanEndingStandardBalance = nathan.standardCoins.totalValue;

    expect(
      meeraEndingStandardBalance,
      equals(meeraStartingStandardBalance - standardAmount - fee),
    );

    expect(
      nathanEndingStandardBalance,
      equals(nathanStartingStandardBalance + standardAmount - fee),
    );

    meeraNfts = await enhancedFullNodeInterface.getNftRecordsByHints(meera.puzzlehashes);
    expect(meeraNfts.length, equals(2));

    final newNft = meeraNfts.where((nft) => nft.launcherId != nftRecord.launcherId);
    expect(newNft.length, equals(1));

    expect(newNft.single.launcherId, equals(offeredNftRecord.launcherId));
  });

  test('Should make a transfer NFT request and receive data', () async {
    var meeraNfts = await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash);
    expect(meeraNfts.length, equals(1));

    var nathanNfts = await fullNodeSimulator.getNftRecordsByHint(nathan.firstPuzzlehash);
    expect(nathanNfts, isEmpty);

    final response = await appClient.transferNFT(
      fingerprint: fingerprint,
      walletId: walletMap.nftWallets().keys.first,
      targetAddress: nathan.firstPuzzlehash.toAddressWithContext(),
      nftCoinIds: [nftInfo.nftCoinId],
      fee: 50,
    );

    expect(
      response.transferNftData.spendBundle.coins.map((coin) => coin.id).contains(nftInfo.nftCoinId),
      isTrue,
    );

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    meeraNfts = await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash);
    expect(meeraNfts, isEmpty);

    nathanNfts = await fullNodeSimulator.getNftRecordsByHint(nathan.firstPuzzlehash);

    expect(nathanNfts.length, equals(1));

    expect(nathanNfts.single.launcherId, equals(nftInfo.launcherId));
  });

  test('Should request to sign by address and receive signature data', () async {
    final walletVector = meera.keychain.getWalletVector(meera.puzzlehashes[2]);

    final response = await appClient.signMessageByAddress(
      fingerprint: fingerprint,
      address: walletVector!.puzzlehash.toAddressWithContext(),
      message: message,
    );

    final expectedMessage = constructChip002Message(message);

    final verification = AugSchemeMPL.verify(
      response.signData.publicKey,
      expectedMessage,
      response.signData.signature,
    );

    expect(verification, isTrue);
  });

  test('Should request to sign by id and receive signature data', () async {
    final didInfo = meera.didInfo!;

    final response = await appClient.signMessageById(
      fingerprint: fingerprint,
      id: didInfo.did,
      message: message,
    );

    final expectedMessage = constructChip002Message(message);

    final verification = AugSchemeMPL.verify(
      response.signData.publicKey,
      expectedMessage,
      response.signData.signature,
    );

    expect(verification, isTrue);
  });

  test(
      'Should request and receive verify signature data when signature is valid on UTF-8 encoded message',
      () async {
    final walletVector = meera.keychain.getWalletVector(meera.puzzlehashes[2]);

    final signature =
        AugSchemeMPL.sign(walletVector!.childPrivateKey, Bytes.encodeFromString(message));

    final response = await appClient.verifySignature(
      fingerprint: fingerprint,
      publicKey: walletVector.childPublicKey,
      message: message,
      signature: signature,
      signingMode: SigningMode.blsMessageAugUtf8,
    );

    expect(response.verifySignatureData.isValid, isTrue);
  });

  test(
      'Should request and receive verify signature data when signature is valid on hex encoded message',
      () async {
    final walletVector = meera.keychain.getWalletVector(meera.puzzlehashes[2]);

    final hexMessage = Bytes.encodeFromString(message).toHex();

    final signature = AugSchemeMPL.sign(walletVector!.childPrivateKey, hexMessage.hexToBytes());

    final response = await appClient.verifySignature(
      fingerprint: fingerprint,
      publicKey: walletVector.childPublicKey,
      message: hexMessage,
      signature: signature,
      signingMode: SigningMode.blsMessageAugHex,
    );

    expect(response.verifySignatureData.isValid, isTrue);
  });

  test(
      'Should request and receive verify signature data when signature is valid on CHIP-002 encoded message',
      () async {
    final walletVector = meera.keychain.getWalletVector(meera.puzzlehashes[2]);

    final chip002Message = constructChip002Message(message);

    final signature = AugSchemeMPL.sign(walletVector!.childPrivateKey, chip002Message);

    final response = await appClient.verifySignature(
      fingerprint: fingerprint,
      publicKey: walletVector.childPublicKey,
      message: message,
      signature: signature,
      signingMode: SigningMode.chip0002,
    );

    expect(response.verifySignatureData.isValid, isTrue);
  });

  test(
      'Should request and receive verify signature data when signature is does not match public key',
      () async {
    final walletVector = meera.keychain.getWalletVector(meera.puzzlehashes[2]);

    final signature =
        AugSchemeMPL.sign(walletVector!.childPrivateKey, Bytes.encodeFromString(message));

    final response = await appClient.verifySignature(
      fingerprint: fingerprint,
      publicKey: nathan.keychain.unhardenedWalletVectors.first.childPublicKey,
      message: message,
      signature: signature,
      signingMode: SigningMode.blsMessageAugUtf8,
    );

    expect(response.verifySignatureData.isValid, isFalse);
  });

  test('Should request log in and receive response', () async {
    final response = await appClient.logIn(fingerprint: fingerprint);

    expect(response.logInData.fingerprint, equals(fingerprint));
    expect(response.logInData.success, isTrue);
  });

  test('Should get did info and sign did spendbundle', () async {
    // mint did
    if (meera.didInfo == null) {
      await meera.issueDid();
    }

    final didSigningService = WalletConnectDidSigningService(appClient, fullNodeSimulator);

    final didInfo = await didSigningService.getDidInfoForDid(meera.didInfo!.did);

    expect(didInfo.did, equals(meera.didInfo!.did));
  });
  test('Should request to create offer file and receive response', () async {
    final catWalletId =
        walletMap.entries.firstWhere((entry) => entry.value.type == ChiaWalletType.cat).key;

    final response = await appClient.createOfferForIds(
      fingerprint: fingerprint,
      offer: {'1': standardAmount, catWalletId.toString(): -catAmount},
    );

    final offer = response.createOfferData.offer;

    final offeredCats = offer.offeredAmounts.cat.entries;

    expect(offeredCats.length, equals(1));
    expect(offeredCats.single.value, equals(catAmount));
    expect(offeredCats.single.key, equals(meeraCoinAssetId));
    expect(offer.requestedAmounts.standard, equals(standardAmount));
  });

  test('Should request to check offer validity of still valid offer and receive response',
      () async {
    final targetPuzzlehash = nathan.firstPuzzlehash;

    final offer = await nathan.offerService.createOffer(
      offeredAmounts: MixedAmounts(standard: standardAmount),
      changePuzzlehash: targetPuzzlehash,
      requestedPayments: RequestedMixedPayments(
        cat: {
          meeraCoinAssetId: [CatPayment(catAmount, targetPuzzlehash)],
        },
      ),
    );

    final response = await appClient.checkOfferValidity(fingerprint: fingerprint, offer: offer);

    expect(response.offerValidityData.valid, isTrue);
  });

  test('Should request to check offer validity of completed offer and receive response', () async {
    final targetPuzzlehash = nathan.firstPuzzlehash;

    final offer = await nathan.offerService.createOffer(
      offeredAmounts: MixedAmounts(standard: standardAmount),
      changePuzzlehash: targetPuzzlehash,
      requestedPayments: RequestedMixedPayments(
        cat: {
          meeraCoinAssetId: [CatPayment(catAmount, targetPuzzlehash)],
        },
      ),
    );

    fullNodeSimulator.run();

    final takeOfferResponse = await appClient.takeOffer(
      fingerprint: fingerprint,
      offer: offer.toBech32(),
      fee: fee,
    );

    fullNodeSimulator.stop();

    expect(takeOfferResponse.takeOfferData.success, isTrue);

    final validityResponse =
        await appClient.checkOfferValidity(fingerprint: fingerprint, offer: offer);

    expect(validityResponse.offerValidityData.valid, isFalse);
  });

  test('Should request to add CAT token to wallet and receive response', () async {
    final assetId =
        Puzzlehash.fromHex('8ebf855de6eb146db5602f0456d2f0cbe750d57f821b6f91a8592ee9f1d4cf31');
    const name = 'Marmot Coin';

    final response = await appClient.addCatToken(
      fingerprint: fingerprint,
      assetId: assetId,
      name: name,
    );

    final walletMap = requestHandler.walletInfoMap!;

    final newWallet = walletMap[response.walletId];

    expect(newWallet, isNotNull);
    expect(newWallet!.type, equals(ChiaWalletType.cat));

    final newCatWallet = newWallet as CatWalletInfo;

    expect(newCatWallet.assetId, equals(assetId));
    expect(newCatWallet.name, equals(name));
  });
}
