@Timeout(Duration(minutes: 3))
import 'dart:async';
import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final crossChainOfferFileService = CrossChainOfferFileService();
  final exchangeOfferService = ExchangeOfferService(fullNodeSimulator);

  // constants
  const mojos = 200000000;
  const satoshis = 100;
  const exchangeValidityTime = 600;
  const paymentRequest =
      'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';
  final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);
  final paymentHash = decodedPaymentRequest.paymentHash!;
  final preimage = '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();

  test(
      'should make and take XCH to BTC offer and complete exchange by sweeping XCH to BTC holder with preimage',
      () async {
    // maker side
    final maker = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    for (var i = 0; i < 2; i++) {
      await maker.farmCoins();
    }
    await maker.refreshCoins();

    final makerMasterPrivateKey = maker.keychainSecret.masterPrivateKey;
    final makerDerivationIndex = ExchangeOfferService.randomDerivationIndexForExchange();

    final makerWalletVector = await WalletVector.fromPrivateKeyAsync(
      makerMasterPrivateKey,
      makerDerivationIndex,
    );

    final makerPrivateKey = makerWalletVector.childPrivateKey;
    final makerPublicKey = makerPrivateKey.getG1();

    final messagePuzzlehash = makerWalletVector.puzzlehash;

    final messageAddress = Address.fromContext(messagePuzzlehash);

    const offerValidityTimeHours = 1;
    final currentUnixTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final offerValidityTime = currentUnixTimeStamp + (offerValidityTimeHours * 60 * 60);

    final unspentInitializationCoin = maker.standardCoins.first;
    final initializationCoinId = unspentInitializationCoin.id;

    final offerFile = crossChainOfferFileService.createXchToBtcMakerOfferFile(
      initializationCoinId: initializationCoinId,
      amountMojos: mojos,
      amountSatoshis: satoshis,
      messageAddress: messageAddress,
      validityTime: offerValidityTime,
      requestorPublicKey: makerPublicKey,
      paymentRequest: decodedPaymentRequest,
    );

    final serializedOfferFile = await offerFile.serializeAsync(makerPrivateKey);

    // maker pushes initialization spend bundle to create offer
    await exchangeOfferService.pushInitializationSpendBundle(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [unspentInitializationCoin],
      initializationCoinId: unspentInitializationCoin.id,
      keychain: maker.keychain,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      changePuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    // taker side
    final taker = ChiaEnthusiast(fullNodeSimulator, walletSize: 10);
    await taker.farmCoins();
    await taker.refreshCoins();

    final takerMasterPrivateKey = taker.keychainSecret.masterPrivateKey;
    final takerDerivationIndex = Random.secure().nextInt(10);

    final takerWalletVector = await WalletVector.fromPrivateKeyAsync(
      takerMasterPrivateKey,
      takerDerivationIndex,
    );

    final takerPrivateKey = takerWalletVector.childPrivateKey;
    final takerPublicKey = takerWalletVector.childPublicKey;

    final takerOfferFile = crossChainOfferFileService.createBtcToXchTakerOfferFile(
      initializationCoinId: initializationCoinId,
      serializedMakerOfferFile: serializedOfferFile,
      validityTime: exchangeValidityTime,
      requestorPublicKey: takerPublicKey,
    );

    final serializedTakerOfferFile = await takerOfferFile.serializeAsync(takerPrivateKey);

    final escrowPuzzlehash = BtcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: takerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: makerPublicKey,
    );

    // taker sends message coin
    final coinForMessageSpend = taker.standardCoins.first;

    await exchangeOfferService.sendMessageCoin(
      initializationCoinId: initializationCoinId,
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedTakerOfferFile,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    // maker accepts message coin
    final messageCoinInfo = await exchangeOfferService.getNextValidMessageCoin(
      initializationCoinId: initializationCoinId,
      serializedOfferFile: serializedOfferFile,
      messagePuzzlehash: messagePuzzlehash,
      exchangeType: ExchangeType.xchToBtc,
    );

    await exchangeOfferService.acceptMessageCoin(
      initializationCoinId: initializationCoinId,
      messageCoin: messageCoinInfo!.messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();

    final spentMessageCoinChild =
        await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoinInfo.messageCoin);

    expect(spentMessageCoinChild, isNotNull);

    // maker transfers funds to escrow puzzlehash
    final makerEscrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: makerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: takerPublicKey,
    );

    await maker.refreshCoins();
    await taker.refreshCoins();
    final startingMakerBalance = maker.standardCoins.totalValue;
    final startingTakerBalance = taker.standardCoins.totalValue;

    var escrowPuzzlehashCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([escrowPuzzlehash]);
    expect(escrowPuzzlehashCoins.totalValue, equals(0));

    await exchangeOfferService.transferFundsToEscrowPuzzlehash(
      initializationCoinId: initializationCoinId,
      mojos: mojos,
      escrowPuzzlehash: makerEscrowPuzzlehash,
      requestorPrivateKey: makerPrivateKey,
      coinsInput: [maker.standardCoins.first],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();

    escrowPuzzlehashCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([escrowPuzzlehash]);
    expect(escrowPuzzlehashCoins.totalValue, equals(mojos));

    // wait for sufficient confirmations
    await fullNodeSimulator.moveToNextBlock(blocks: blocksForSufficientConfirmation);

    // taker sweeps escrow puzzlehash
    await exchangeOfferService.sweepEscrowPuzzlehash(
      initializationCoinId: initializationCoinId,
      escrowPuzzlehash: escrowPuzzlehash,
      requestorPuzzlehash: taker.firstPuzzlehash,
      requestorPrivateKey: takerPrivateKey,
      exchangeValidityTime: exchangeValidityTime,
      paymentHash: paymentHash,
      preimage: preimage,
      fulfillerPublicKey: makerPublicKey,
    );

    await fullNodeSimulator.moveToNextBlock();

    await maker.refreshCoins();
    await taker.refreshCoins();

    final endingMakerBalance = maker.standardCoins.totalValue;
    final endingTakerBalance = taker.standardCoins.totalValue;

    expect(endingMakerBalance, equals(startingMakerBalance - mojos));
    expect(endingTakerBalance, equals(startingTakerBalance + mojos));
  });

  test(
      'should make and take BTC to XCH offer and complete exchange by sweeping XCH to BTC holder with preimage',
      () async {
    // maker side
    final maker = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await maker.farmCoins();
    await maker.refreshCoins();

    final makerMasterPrivateKey = maker.keychainSecret.masterPrivateKey;
    final makerDerivationIndex = ExchangeOfferService.randomDerivationIndexForExchange();

    final makerWalletVector = await WalletVector.fromPrivateKeyAsync(
      makerMasterPrivateKey,
      makerDerivationIndex,
    );

    final makerPrivateKey = makerWalletVector.childPrivateKey;
    final makerPublicKey = makerPrivateKey.getG1();

    final messagePuzzlehash = makerWalletVector.puzzlehash;

    final messageAddress = Address.fromContext(messagePuzzlehash);

    const offerValidityTimeHours = 1;
    final currentUnixTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final offerValidityTime = currentUnixTimeStamp + (offerValidityTimeHours * 60 * 60);

    final unspentInitializationCoin = maker.standardCoins.first;
    final initializationCoinId = unspentInitializationCoin.id;

    final offerFile = crossChainOfferFileService.createBtcToXchMakerOfferFile(
      initializationCoinId: initializationCoinId,
      amountMojos: mojos,
      amountSatoshis: satoshis,
      messageAddress: messageAddress,
      validityTime: offerValidityTime,
      requestorPublicKey: makerPublicKey,
    );

    final serializedOfferFile = await offerFile.serializeAsync(makerPrivateKey);

    // maker pushes initialization spend bundle to create offer
    await exchangeOfferService.pushInitializationSpendBundle(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [unspentInitializationCoin],
      initializationCoinId: unspentInitializationCoin.id,
      keychain: maker.keychain,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      changePuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    // taker side
    final taker = ChiaEnthusiast(fullNodeSimulator, walletSize: 10);
    for (var i = 0; i < 2; i++) {
      await taker.farmCoins();
    }
    await taker.refreshCoins();

    final takerMasterPrivateKey = taker.keychainSecret.masterPrivateKey;
    final takerDerivationIndex = Random.secure().nextInt(10);

    final takerWalletVector = await WalletVector.fromPrivateKeyAsync(
      takerMasterPrivateKey,
      takerDerivationIndex,
    );

    final takerPrivateKey = takerWalletVector.childPrivateKey;
    final takerPublicKey = takerWalletVector.childPublicKey;

    final takerOfferFile = crossChainOfferFileService.createXchToBtcTakerOfferFile(
      initializationCoinId: initializationCoinId,
      serializedMakerOfferFile: serializedOfferFile,
      validityTime: exchangeValidityTime,
      requestorPublicKey: takerPublicKey,
      paymentRequest: decodedPaymentRequest,
    );

    final serializedTakerOfferFile = await takerOfferFile.serializeAsync(takerPrivateKey);

    final escrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: takerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: makerPublicKey,
    );

    // taker sends message coin
    final coinForMessageSpend = taker.standardCoins.first;

    await exchangeOfferService.sendMessageCoin(
      initializationCoinId: initializationCoinId,
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedTakerOfferFile,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    // maker accepts message coin
    final messageCoinInfo = await exchangeOfferService.getNextValidMessageCoin(
      initializationCoinId: initializationCoinId,
      serializedOfferFile: serializedOfferFile,
      messagePuzzlehash: messagePuzzlehash,
      exchangeType: ExchangeType.btcToXch,
      satoshis: satoshis,
    );

    await exchangeOfferService.acceptMessageCoin(
      initializationCoinId: initializationCoinId,
      messageCoin: messageCoinInfo!.messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();

    final spentMessageCoinChild =
        await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoinInfo.messageCoin);

    expect(spentMessageCoinChild, isNotNull);

    await maker.refreshCoins();
    await taker.refreshCoins();
    final startingMakerBalance = maker.standardCoins.totalValue;
    final startingTakerBalance = taker.standardCoins.totalValue;

    var escrowPuzzlehashCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([escrowPuzzlehash]);
    expect(escrowPuzzlehashCoins.totalValue, equals(0));

    // taker transfers funds to escrow puzzlehash
    await exchangeOfferService.transferFundsToEscrowPuzzlehash(
      initializationCoinId: initializationCoinId,
      mojos: mojos,
      escrowPuzzlehash: escrowPuzzlehash,
      requestorPrivateKey: takerPrivateKey,
      coinsInput: [taker.standardCoins.first],
      keychain: taker.keychain,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();

    escrowPuzzlehashCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([escrowPuzzlehash]);
    expect(escrowPuzzlehashCoins.totalValue, equals(mojos));

    // wait for sufficient confirmations
    await fullNodeSimulator.moveToNextBlock(blocks: blocksForSufficientConfirmation);

    // maker sweeps escrow puzzlehash
    final makerEscrowPuzzlehash = BtcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: makerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: takerPublicKey,
    );

    await exchangeOfferService.sweepEscrowPuzzlehash(
      initializationCoinId: initializationCoinId,
      escrowPuzzlehash: makerEscrowPuzzlehash,
      requestorPuzzlehash: maker.firstPuzzlehash,
      requestorPrivateKey: makerPrivateKey,
      exchangeValidityTime: exchangeValidityTime,
      paymentHash: paymentHash,
      preimage: preimage,
      fulfillerPublicKey: takerPublicKey,
    );

    await fullNodeSimulator.moveToNextBlock();

    await maker.refreshCoins();
    await taker.refreshCoins();

    final endingMakerBalance = maker.standardCoins.totalValue;
    final endingTakerBalance = taker.standardCoins.totalValue;

    expect(endingMakerBalance, equals(startingMakerBalance + mojos));
    expect(endingTakerBalance, equals(startingTakerBalance - mojos));
  });
}
