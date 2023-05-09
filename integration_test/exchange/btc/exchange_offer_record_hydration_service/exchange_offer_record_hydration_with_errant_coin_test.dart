@Timeout(Duration(minutes: 5))
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

  final simulatorHttpRpc = SimulatorHttpRpc(
    SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );

  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final crossChainOfferService = CrossChainOfferService(fullNodeSimulator);
  final exchangeOfferService = ExchangeOfferService(fullNodeSimulator);
  final exchangeOfferRecordHydrationService =
      ExchangeOfferRecordHydrationService(fullNodeSimulator);

  // constants
  const makerExchangeType = ExchangeType.xchToBtc;
  const mojos = 200000000;
  const satoshis = 100;
  const exchangeValidityTime = 600;
  const paymentRequest =
      'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';
  final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);
  final paymentHash = decodedPaymentRequest.paymentHash!;
  final preimage = '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();

  late ChiaEnthusiast maker;
  late PrivateKey makerMasterPrivateKey;
  late int makerDerivationIndex;
  late PrivateKey makerPrivateKey;
  late JacobianPoint makerPublicKey;
  late Puzzlehash messagePuzzlehash;
  late int offerValidityTime;
  late String serializedOfferFile;
  late Coin initializationCoin;
  late DateTime initializedTime;

  late ChiaEnthusiast taker;
  late PrivateKey takerMasterPrivateKey;
  late int takerDerivationIndex;
  late PrivateKey takerPrivateKey;
  late JacobianPoint takerPublicKey;
  late String serializedTakerOfferFile;
  late Puzzlehash escrowPuzzlehash;

  late ChiaEnthusiast errantCoinSender;
  late PrivateKey errantCoinSenderPrivateKey;
  setUp(() async {
    // maker side
    maker = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    for (var i = 0; i < 2; i++) {
      await maker.farmCoins();
    }
    await maker.refreshCoins();

    makerMasterPrivateKey = maker.keychainSecret.masterPrivateKey;
    makerDerivationIndex = ExchangeOfferService.randomDerivationIndexForExchange();

    final makerWalletVector = await WalletVector.fromPrivateKeyAsync(
      makerMasterPrivateKey,
      makerDerivationIndex,
    );

    makerPrivateKey = makerWalletVector.childPrivateKey;
    makerPublicKey = makerPrivateKey.getG1();

    messagePuzzlehash = makerWalletVector.puzzlehash;

    final messageAddress = Address.fromContext(messagePuzzlehash);

    const offerValidityTimeHours = 1;
    final currentUnixTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    offerValidityTime = currentUnixTimeStamp + (offerValidityTimeHours * 60 * 60);

    final offerFile = crossChainOfferService.createXchToBtcOfferFile(
      amountMojos: mojos,
      amountSatoshis: satoshis,
      messageAddress: messageAddress,
      validityTime: offerValidityTime,
      requestorPublicKey: makerPublicKey,
      paymentRequest: decodedPaymentRequest,
    );

    serializedOfferFile = await offerFile.serializeAsync(makerPrivateKey);

    // maker pushes initialization spend bundle to create offer
    final unspentInitializationCoin = maker.standardCoins.first;

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

    initializationCoin = (await fullNodeSimulator.getCoinById(unspentInitializationCoin.id))!;
    initializedTime =
        (await fullNodeSimulator.getDateTimeFromBlockIndex(initializationCoin.spentBlockIndex))!;

    // taker side
    taker = ChiaEnthusiast(fullNodeSimulator, walletSize: 10);
    await taker.farmCoins();
    await taker.refreshCoins();

    takerMasterPrivateKey = taker.keychainSecret.masterPrivateKey;
    takerDerivationIndex = Random.secure().nextInt(10);

    final takerWalletVector = await WalletVector.fromPrivateKeyAsync(
      takerMasterPrivateKey,
      takerDerivationIndex,
    );

    takerPrivateKey = takerWalletVector.childPrivateKey;
    takerPublicKey = takerWalletVector.childPublicKey;

    final takerOfferFile = crossChainOfferService.createBtcToXchAcceptFile(
      serializedOfferFile: serializedOfferFile,
      validityTime: exchangeValidityTime,
      requestorPublicKey: takerPublicKey,
    );

    serializedTakerOfferFile = await takerOfferFile.serializeAsync(takerPrivateKey);

    escrowPuzzlehash = BtcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: takerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: makerPublicKey,
    );

    // malicious actor sending errant coins
    errantCoinSender = ChiaEnthusiast(fullNodeSimulator);
    await errantCoinSender.farmCoins();
    await errantCoinSender.refreshCoins();
    final errantCoinSenderWalletVector =
        await WalletVector.fromPrivateKeyAsync(errantCoinSender.keychainSecret.masterPrivateKey, 1);
    errantCoinSenderPrivateKey = errantCoinSenderWalletVector.childPrivateKey;
  });

  test(
      'should correctly restore exchange offer record when errant coin has been sent to escrow puzzlehash with initialization coin id',
      () async {
    // taker sends message coin
    final coinForMessageSpend = taker.standardCoins.first;

    await exchangeOfferService.sendMessageCoin(
      initializationCoinId: initializationCoin.id,
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
      initializationCoinId: initializationCoin.id,
      serializedOfferFile: serializedOfferFile,
      messagePuzzlehash: messagePuzzlehash,
      exchangeType: makerExchangeType,
    );

    await exchangeOfferService.acceptMessageCoin(
      initializationCoinId: initializationCoin.id,
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
    final expectedMessageCoinAcceptedTime =
        await fullNodeSimulator.getDateTimeFromBlockIndex(spentMessageCoinChild!.spentBlockIndex);

    // maker transfers funds to escrow puzzlehash
    final makerEscrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: makerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: takerPublicKey,
    );

    final escrowCoinParent = maker.standardCoins.first;

    await exchangeOfferService.transferFundsToEscrowPuzzlehash(
      initializationCoinId: initializationCoin.id,
      mojos: mojos,
      escrowPuzzlehash: makerEscrowPuzzlehash,
      requestorPrivateKey: makerPrivateKey,
      coinsInput: [escrowCoinParent],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final escrowCoin = (await fullNodeSimulator.getCoinsByPuzzleHashes([makerEscrowPuzzlehash]))
        .where((coin) => coin.parentCoinInfo == escrowCoinParent.id)
        .single;
    final spentEscrowCoinParent = await fullNodeSimulator.getCoinById(escrowCoin.parentCoinInfo);
    final expectedEscrowTransferCompletedTime =
        await fullNodeSimulator.getDateTimeFromBlockIndex(spentEscrowCoinParent!.spentBlockIndex);

    // wait for sufficient confirmations
    await fullNodeSimulator.moveToNextBlock(32);
    final expectedEscrowTransferConfirmedTime = await fullNodeSimulator.getCurrentBlockDateTime();

    // malicious actor sends an errant coin to the leaked escrow puzzlehash
    final memos = ExchangeCoinMemos(
      initializationCoinId: initializationCoin.id,
      requestorPrivateKey: errantCoinSenderPrivateKey,
    ).toMemos();

    final errantCoinSpendBundle = StandardWalletService().createSpendBundle(
      payments: [
        Payment(
          1,
          escrowPuzzlehash,
          memos: memos,
        )
      ],
      coinsInput: [errantCoinSender.standardCoins.first],
      keychain: errantCoinSender.keychain,
      changePuzzlehash: errantCoinSender.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(errantCoinSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    // taker sweeps escrow puzzlehash
    await exchangeOfferService.sweepEscrowPuzzlehash(
      initializationCoinId: initializationCoin.id,
      escrowPuzzlehash: escrowPuzzlehash,
      requestorPuzzlehash: taker.firstPuzzlehash,
      requestorPrivateKey: takerPrivateKey,
      exchangeValidityTime: exchangeValidityTime,
      paymentHash: paymentHash,
      preimage: preimage,
      fulfillerPublicKey: makerPublicKey,
    );

    await fullNodeSimulator.moveToNextBlock();

    final spentEscrowCoin = await fullNodeSimulator.getCoinById(escrowCoin.id);
    final expectedSweepTime =
        await fullNodeSimulator.getDateTimeFromBlockIndex(spentEscrowCoin!.spentBlockIndex);

    // restoring exchange offer record
    final initializationCoins =
        await fullNodeSimulator.scroungeForExchangeInitializationCoins(maker.puzzlehashes);

    expect(initializationCoins.length, equals(1));
    expect(initializationCoins.contains(initializationCoin), isTrue);

    final hydratedExchangeOfferRecord =
        await exchangeOfferRecordHydrationService.hydrateExchangeInitializationCoin(
      initializationCoins.single,
      makerMasterPrivateKey,
      maker.keychain,
    );

    expect(hydratedExchangeOfferRecord, isNotNull);
    expect(
      hydratedExchangeOfferRecord.initializationCoinId,
      equals(initializationCoin.id),
    );
    expect(
      hydratedExchangeOfferRecord.derivationIndex,
      equals(makerDerivationIndex),
    );
    expect(
      hydratedExchangeOfferRecord.type.name,
      equals(makerExchangeType.name),
    );
    expect(
      hydratedExchangeOfferRecord.role.name,
      equals(ExchangeRole.maker.name),
    );
    expect(
      hydratedExchangeOfferRecord.mojos,
      equals(mojos),
    );
    expect(
      hydratedExchangeOfferRecord.satoshis,
      equals(satoshis),
    );
    expect(
      hydratedExchangeOfferRecord.messagePuzzlehash,
      equals(messagePuzzlehash),
    );
    expect(
      hydratedExchangeOfferRecord.requestorPublicKey,
      equals(makerPublicKey),
    );
    expect(
      hydratedExchangeOfferRecord.offerValidityTime,
      equals(offerValidityTime),
    );
    expect(
      hydratedExchangeOfferRecord.serializedMakerOfferFile,
      equals(serializedOfferFile),
    );
    expect(
      hydratedExchangeOfferRecord.lightningPaymentRequest!.paymentRequest,
      equals(paymentRequest),
    );
    expect(
      hydratedExchangeOfferRecord.initializedTime,
      equals(initializedTime),
    );
    expect(hydratedExchangeOfferRecord.messageCoinId, equals(messageCoinInfo.messageCoin.id));
    expect(
      hydratedExchangeOfferRecord.messageCoinReceivedTime,
      equals(messageCoinInfo.messageCoinReceivedTime),
    );
    expect(
      hydratedExchangeOfferRecord.serializedTakerOfferFile,
      equals(serializedTakerOfferFile),
    );
    expect(
      hydratedExchangeOfferRecord.exchangeValidityTime,
      equals(exchangeValidityTime),
    );
    expect(hydratedExchangeOfferRecord.fulfillerPublicKey, equals(takerPublicKey));
    expect(
      hydratedExchangeOfferRecord.escrowPuzzlehash,
      equals(escrowPuzzlehash),
    );
    expect(
      hydratedExchangeOfferRecord.messageCoinAcceptedTime,
      equals(expectedMessageCoinAcceptedTime),
    );
    expect(hydratedExchangeOfferRecord.escrowCoinId, escrowCoin.id);
    expect(
      hydratedExchangeOfferRecord.escrowTransferCompletedTime,
      equals(expectedEscrowTransferCompletedTime),
    );
    expect(
      hydratedExchangeOfferRecord.escrowTransferConfirmedTime,
      expectedEscrowTransferConfirmedTime,
    );
    expect(hydratedExchangeOfferRecord.sweepTime, equals(expectedSweepTime));
    expect(hydratedExchangeOfferRecord.sweepConfirmedTime, isNull);
    expect(hydratedExchangeOfferRecord.clawbackTime, isNull);
    expect(hydratedExchangeOfferRecord.clawbackConfirmedTime, isNull);
    expect(hydratedExchangeOfferRecord.canceledTime, isNull);
  });
}
