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

  final simulatorHttpRpc = SimulatorHttpRpc(
    SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );

  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final crossChainOfferService = CrossChainOfferService(fullNodeSimulator);
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
  const fee = 50;

  late ChiaEnthusiast maker;
  late PrivateKey makerMasterPrivateKey;
  late int makerDerivationIndex;
  late PrivateKey makerPrivateKey;
  late JacobianPoint makerPublicKey;
  late Puzzlehash messagePuzzlehash;
  late int offerValidityTime;
  late String serializedOfferFile;
  late Coin initializationCoin;
  late CoinSpend initializationCoinSpend;

  late ChiaEnthusiast taker;
  late PrivateKey takerMasterPrivateKey;
  late int takerDerivationIndex;
  late PrivateKey takerPrivateKey;
  late JacobianPoint takerPublicKey;
  late String serializedOfferAcceptFile;
  late Puzzlehash escrowPuzzlehash;
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
      keychain: maker.keychain,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      changePuzzlehash: maker.firstPuzzlehash,
      initializationCoinId: unspentInitializationCoin.id,
    );
    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    initializationCoin = (await fullNodeSimulator.getCoinById(unspentInitializationCoin.id))!;

    initializationCoinSpend = (await fullNodeSimulator.getCoinSpend(initializationCoin))!;

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

    final offerAcceptFile = crossChainOfferService.createBtcToXchAcceptFile(
      serializedOfferFile: serializedOfferFile,
      validityTime: exchangeValidityTime,
      requestorPublicKey: takerPublicKey,
    );

    serializedOfferAcceptFile = await offerAcceptFile.serializeAsync(takerPrivateKey);

    escrowPuzzlehash = BtcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: takerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: makerPublicKey,
    );
  });

  test(
      'should spend initialization coin and create 3 mojo child coin with memos in expected format',
      () async {
    final memos = await initializationCoinSpend.memos;

    expect(memos.length, equals(2));
    expect(memos.first, encodeInt(makerDerivationIndex));
    expect(memos.last, equals(Bytes.encodeFromString(serializedOfferFile)));
  });

  test('should find valid initialization coin', () async {
    final initializationCoins =
        await fullNodeSimulator.scroungeForExchangeInitializationCoins(maker.puzzlehashes);
    expect(initializationCoins.length, equals(1));
    expect(initializationCoins.single.id, equals(initializationCoin.id));
  });

  test('should find multiple valid initialization coins', () async {
    final makerDerivationIndex2 = ExchangeOfferService.randomDerivationIndexForExchange();

    final makerWalletVector2 = await WalletVector.fromPrivateKeyAsync(
      makerMasterPrivateKey,
      makerDerivationIndex2,
    );

    final messagePuzzlehash2 = makerWalletVector2.puzzlehash;

    final initializationCoin2 = maker.standardCoins.first;

    await exchangeOfferService.pushInitializationSpendBundle(
      messagePuzzlehash: messagePuzzlehash2,
      initializationCoinId: initializationCoin2.id,
      coinsInput: [initializationCoin2],
      keychain: maker.keychain,
      derivationIndex: makerDerivationIndex2,
      serializedOfferFile: serializedOfferFile,
      changePuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final initializationCoins =
        await fullNodeSimulator.scroungeForExchangeInitializationCoins(maker.puzzlehashes);
    expect(initializationCoins.length, equals(2));

    final initializationCoinIds = initializationCoins.map((coin) => coin.id).toList();

    expect(initializationCoinIds, contains(initializationCoin.id));
    expect(initializationCoinIds, contains(initializationCoin2.id));
  });

  test('should not find incorrectly spent initialization coin', () async {
    final standardWalletService = StandardWalletService();

    final initializationCoin2 = maker.standardCoins.first;

    final incorrectInitializationSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          4,
          messagePuzzlehash,
          memos: <Memo>[
            Memo(encodeInt(makerDerivationIndex)),
            Memo(Bytes.encodeFromString(serializedOfferFile)),
          ],
        )
      ],
      coinsInput: [initializationCoin2],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(incorrectInitializationSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final initializationCoins =
        await fullNodeSimulator.scroungeForExchangeInitializationCoins(maker.puzzlehashes);

    final filteredInitializationCoins =
        initializationCoins.where((coin) => coin.parentCoinInfo == initializationCoin2.id);

    expect(filteredInitializationCoins, isEmpty);
  });

  test('should correctly find cancel coin', () async {
    final cancelCoinId = initializationCoinSpend.additions
        .where((addition) => addition.puzzlehash == messagePuzzlehash && addition.amount == 3)
        .single
        .id;
    final expectedCancelCoin = await fullNodeSimulator.getCoinById(cancelCoinId);

    final cancelCoin =
        await exchangeOfferService.getCancelCoin(initializationCoin, messagePuzzlehash);
    expect(cancelCoin, equals(expectedCancelCoin));
  });

  test(
      'should throw exception when trying to find cancel coin from an offer that has not been initialized',
      () async {
    final makerDerivationIndex2 = ExchangeOfferService.randomDerivationIndexForExchange();

    final makerWalletVector2 = await WalletVector.fromPrivateKeyAsync(
      makerMasterPrivateKey,
      makerDerivationIndex2,
    );

    final messagePuzzlehash2 = makerWalletVector2.puzzlehash;

    final initializationCoin2 = maker.standardCoins.first;

    expect(
      () async {
        await exchangeOfferService.getCancelCoin(initializationCoin2, messagePuzzlehash2);
      },
      throwsA(isA<MissingCancelCoinException>()),
    );
  });

  test(
      'should cancel an exchange offer by spending 3 mojo child of initialization coin at message puzzlehash with expected memo',
      () async {
    final unspentCancelCoin =
        await exchangeOfferService.getCancelCoin(initializationCoin, messagePuzzlehash);

    expect(unspentCancelCoin.isNotSpent, isTrue);

    await exchangeOfferService.cancelExchangeOffer(
      initializationCoinId: initializationCoin.id,
      messagePuzzlehash: messagePuzzlehash,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      targetPuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();

    final spentCancelCoin = await fullNodeSimulator.getCoinById(unspentCancelCoin.id);

    expect(spentCancelCoin!.isSpent, isTrue);

    final cancelationCoinSpend = await fullNodeSimulator.getCoinSpend(spentCancelCoin);
    final memos = await cancelationCoinSpend!.memos;

    expect(memos.contains(initializationCoin.id), isTrue);
  });

  test('should throw exception when trying to cancel an offer that has already been canceled',
      () async {
    final unspentCancelCoin =
        await exchangeOfferService.getCancelCoin(initializationCoin, messagePuzzlehash);

    expect(unspentCancelCoin.isNotSpent, isTrue);

    await exchangeOfferService.cancelExchangeOffer(
      initializationCoinId: initializationCoin.id,
      messagePuzzlehash: messagePuzzlehash,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      targetPuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();

    expect(
      () async {
        await exchangeOfferService.cancelExchangeOffer(
          initializationCoinId: initializationCoin.id,
          messagePuzzlehash: messagePuzzlehash,
          masterPrivateKey: makerMasterPrivateKey,
          derivationIndex: makerDerivationIndex,
          targetPuzzlehash: maker.firstPuzzlehash,
        );
      },
      throwsA(isA<DoubleSpendException>()),
    );
  });

  test('should send message coin with expected memo format', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      initializationCoinId: initializationCoin.id,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final spentMessageCoinParent = await fullNodeSimulator.getCoinById(coinForMessageSpend.id);
    final messageCoinSpend = await fullNodeSimulator.getCoinSpend(spentMessageCoinParent!);

    final memos = await messageCoinSpend!.memos;

    expect(memos.length, equals(3));
    expect(memos[0], equals(Bytes(messagePuzzlehash)));
    expect(memos[1], equals(initializationCoin.id));
    expect(memos[2], equals(Bytes.encodeFromString(serializedOfferAcceptFile)));

    final messageCoins =
        await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true);

    expect(messageCoins.length, equals(1));
  });

  test(
      'should throw exception when trying to send message coin for an offer that has already been canceled',
      () async {
    final unspentCancelCoin =
        await exchangeOfferService.getCancelCoin(initializationCoin, messagePuzzlehash);

    expect(unspentCancelCoin.isNotSpent, isTrue);

    await exchangeOfferService.cancelExchangeOffer(
      initializationCoinId: initializationCoin.id,
      messagePuzzlehash: messagePuzzlehash,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      targetPuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();

    final coinForMessageSpend = taker.standardCoins.first;

    expect(
      () async {
        await exchangeOfferService.sendMessageCoin(
          messagePuzzlehash: messagePuzzlehash,
          coinsInput: [coinForMessageSpend],
          keychain: taker.keychain,
          serializedTakerOfferFile: serializedOfferAcceptFile,
          initializationCoinId: initializationCoin.id,
          changePuzzlehash: taker.firstPuzzlehash,
        );
      },
      throwsA(isA<OfferCanceledException>()),
    );
  });

  test('should correctly find message coin child', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      initializationCoinId: initializationCoin.id,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoin =
        (await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true)).single;

    final expectedMessageCoinChild =
        (await fullNodeSimulator.getCoinsByPuzzleHashes([messagePuzzlehash]))
            .where((coin) => coin.parentCoinInfo == messageCoin.id)
            .toList()
            .single;

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, expectedMessageCoinChild);
  });

  test('should decline message coin by spending it with no memo', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      initializationCoinId: initializationCoin.id,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoin =
        (await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true)).single;

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, isNotNull);
    expect(messageCoinChild!.isNotSpent, isTrue);

    await exchangeOfferService.declineMessageCoin(
      initializationCoinId: initializationCoin.id,
      messageCoin: messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();

    final spentMessageCoin = await fullNodeSimulator.getCoinById(messageCoin.id);
    expect(spentMessageCoin!.isSpent, isTrue);
    final declinationCoinSpend = await fullNodeSimulator.getCoinSpend(spentMessageCoin);
    final memos = await declinationCoinSpend!.memos;
    expect(memos.isEmpty, isTrue);
  });

  test('should decline message coin with fee', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      initializationCoinId: initializationCoin.id,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoin =
        (await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true)).single;

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, isNotNull);
    expect(messageCoinChild!.isNotSpent, isTrue);

    final startingMakerBalance = maker.standardCoins.totalValue;

    await exchangeOfferService.declineMessageCoin(
      initializationCoinId: initializationCoin.id,
      messageCoin: messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
      fee: fee,
      coinsForFee: [maker.standardCoins[1]],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final endingMakerBalance = maker.standardCoins.totalValue;
    expect(endingMakerBalance, equals(startingMakerBalance - fee + minimumNotificationCoinAmount));
  });

  test('should accept message coin by spending with expected memo', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      initializationCoinId: initializationCoin.id,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoin =
        (await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true)).single;

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, isNotNull);
    expect(messageCoinChild!.isNotSpent, isTrue);

    await exchangeOfferService.acceptMessageCoin(
      initializationCoinId: initializationCoin.id,
      messageCoin: messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
      coinsForFee: [maker.standardCoins[1]],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();

    final spentMessageCoinChild = await fullNodeSimulator.getCoinById(messageCoinChild.id);
    expect(spentMessageCoinChild!.isSpent, isTrue);
    final acceptanceCoinSpend = await fullNodeSimulator.getCoinSpend(spentMessageCoinChild);
    final memos = await acceptanceCoinSpend!.memos;
    expect(memos.contains(initializationCoin.id), isTrue);
  });

  test('should accept message coin with fee', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      initializationCoinId: initializationCoin.id,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoin =
        (await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true)).single;

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, isNotNull);
    expect(messageCoinChild!.isNotSpent, isTrue);

    final startingMakerBalance = maker.standardCoins.totalValue;

    await exchangeOfferService.acceptMessageCoin(
      initializationCoinId: initializationCoin.id,
      messageCoin: messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
      fee: fee,
      coinsForFee: [maker.standardCoins[1]],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final endingMakerBalance = maker.standardCoins.totalValue;
    expect(endingMakerBalance, equals(startingMakerBalance - fee + minimumNotificationCoinAmount));
  });

  test('should throw exception if fee is greater than zero and inputs for fee are missing',
      () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      initializationCoinId: initializationCoin.id,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoin =
        (await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true)).single;

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, isNotNull);
    expect(messageCoinChild!.isNotSpent, isTrue);

    expect(
      () async {
        await exchangeOfferService.acceptMessageCoin(
          initializationCoinId: initializationCoin.id,
          messageCoin: messageCoin,
          masterPrivateKey: makerMasterPrivateKey,
          derivationIndex: makerDerivationIndex,
          serializedOfferFile: serializedOfferFile,
          targetPuzzlehash: maker.firstPuzzlehash,
          fee: 50,
          keychain: maker.keychain,
          changePuzzlehash: maker.firstPuzzlehash,
        );
      },
      throwsA(isA<MissingInputsForFeeException>()),
    );
  });

  test('should throw exception when trying to accept already declined message coin', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      initializationCoinId: initializationCoin.id,
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoin =
        (await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true)).single;

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, isNotNull);
    expect(messageCoinChild!.isNotSpent, isTrue);

    await exchangeOfferService.declineMessageCoin(
      initializationCoinId: initializationCoin.id,
      messageCoin: messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();

    expect(
      () async {
        await exchangeOfferService.acceptMessageCoin(
          initializationCoinId: initializationCoin.id,
          messageCoin: messageCoin,
          masterPrivateKey: makerMasterPrivateKey,
          derivationIndex: makerDerivationIndex,
          serializedOfferFile: serializedOfferFile,
          targetPuzzlehash: maker.firstPuzzlehash,
        );
      },
      throwsA(isA<DoubleSpendException>()),
    );
  });

  test('should throw exception when trying to decline already accepted message coin', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      initializationCoinId: initializationCoin.id,
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoin =
        (await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true)).single;

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, isNotNull);
    expect(messageCoinChild!.isNotSpent, isTrue);

    await exchangeOfferService.acceptMessageCoin(
      initializationCoinId: initializationCoin.id,
      messageCoin: messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();

    expect(
      () async {
        await exchangeOfferService.declineMessageCoin(
          initializationCoinId: initializationCoin.id,
          messageCoin: messageCoin,
          masterPrivateKey: makerMasterPrivateKey,
          derivationIndex: makerDerivationIndex,
          serializedOfferFile: serializedOfferFile,
          targetPuzzlehash: maker.firstPuzzlehash,
        );
      },
      throwsA(isA<DoubleSpendException>()),
    );
  });

  test('should get info for next valid message coin', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      initializationCoinId: initializationCoin.id,
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoin =
        (await fullNodeSimulator.getCoinsByHint(messagePuzzlehash, includeSpentCoins: true)).single;

    final messageCoinSpentTime =
        await fullNodeSimulator.getDateTimeFromBlockIndex(messageCoin.spentBlockIndex);

    final messageCoinInfo = await exchangeOfferService.getNextValidMessageCoin(
      initializationCoinId: initializationCoin.id,
      serializedOfferFile: serializedOfferFile,
      messagePuzzlehash: messagePuzzlehash,
      exchangeType: ExchangeType.xchToBtc,
    );

    expect(messageCoinInfo, isNotNull);
    expect(messageCoinInfo!.messageCoin, equals(messageCoin));
    expect(messageCoinInfo.serializedOfferAcceptFile, equals(serializedOfferAcceptFile));
    expect(messageCoinInfo.fulfillerPublicKey, equals(takerPublicKey));
    expect(messageCoinInfo.messageCoinReceivedTime, equals(messageCoinSpentTime));
    expect(messageCoinInfo.exchangeValidityTime, equals(exchangeValidityTime));
  });

  test('should not get message coin info for coin with wrong offer file type', () async {
    final xchToBtcOfferAcceptFile = crossChainOfferService.createXchToBtcAcceptFile(
      serializedOfferFile: serializedOfferFile,
      validityTime: exchangeValidityTime,
      requestorPublicKey: takerPublicKey,
      paymentRequest: decodedPaymentRequest,
    );

    final serializedXchToBtcOfferAcceptFile =
        await xchToBtcOfferAcceptFile.serializeAsync(takerPrivateKey);

    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      initializationCoinId: initializationCoin.id,
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedXchToBtcOfferAcceptFile,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final messageCoinInfo = await exchangeOfferService.getNextValidMessageCoin(
      initializationCoinId: initializationCoin.id,
      serializedOfferFile: serializedOfferFile,
      messagePuzzlehash: messagePuzzlehash,
      exchangeType: ExchangeType.xchToBtc,
    );

    expect(messageCoinInfo, isNull);
  });

  test('should correctly parse message coin info for accepted message coin', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      initializationCoinId: initializationCoin.id,
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final unspentMessageCoinInfo = await exchangeOfferService.getNextValidMessageCoin(
      initializationCoinId: initializationCoin.id,
      serializedOfferFile: serializedOfferFile,
      messagePuzzlehash: messagePuzzlehash,
      exchangeType: ExchangeType.xchToBtc,
    );

    await exchangeOfferService.acceptMessageCoin(
      initializationCoinId: initializationCoin.id,
      messageCoin: unspentMessageCoinInfo!.messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
      coinsForFee: [maker.standardCoins[1]],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();

    final messageCoins =
        await fullNodeSimulator.scroungeForReceivedNotificationCoins([messagePuzzlehash]);

    expect(messageCoins.length, equals(1));

    final messageCoin = messageCoins.single;

    final messageCoinInfo = await exchangeOfferService.parseAndValidateReceivedMessageCoin(
      messageCoin: messageCoin,
      initializationCoinId: initializationCoin.id,
      serializedOfferFile: serializedOfferFile,
      messagePuzzlehash: messagePuzzlehash,
      exchangeType: ExchangeType.xchToBtc,
    );

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, isNotNull);
    expect(messageCoinChild!.isSpent, isTrue);

    final messageCoinChildSpentTime =
        await fullNodeSimulator.getDateTimeFromBlockIndex(messageCoinChild.spentBlockIndex);

    expect(messageCoinInfo, isNotNull);
    expect(messageCoinInfo!.messageCoin, equals(messageCoin));
    expect(messageCoinInfo.serializedOfferAcceptFile, equals(serializedOfferAcceptFile));
    expect(messageCoinInfo.fulfillerPublicKey, equals(takerPublicKey));
    expect(
      messageCoinInfo.messageCoinReceivedTime,
      equals(messageCoinInfo.messageCoinReceivedTime),
    );
    expect(messageCoinInfo.exchangeValidityTime, equals(exchangeValidityTime));
    expect(messageCoinInfo.messageCoinAcceptedTime, equals(messageCoinChildSpentTime));
    expect(messageCoinInfo.messageCoinDeclinedTime, isNull);
  });

  test('should correctly parse message coin info for declined message coin', () async {
    final coinForMessageSpend = taker.standardCoins.first;
    await exchangeOfferService.sendMessageCoin(
      initializationCoinId: initializationCoin.id,
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: [coinForMessageSpend],
      keychain: taker.keychain,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final unspentMessageCoinInfo = await exchangeOfferService.getNextValidMessageCoin(
      initializationCoinId: initializationCoin.id,
      serializedOfferFile: serializedOfferFile,
      messagePuzzlehash: messagePuzzlehash,
      exchangeType: ExchangeType.xchToBtc,
    );

    await exchangeOfferService.declineMessageCoin(
      initializationCoinId: initializationCoin.id,
      messageCoin: unspentMessageCoinInfo!.messageCoin,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
      serializedOfferFile: serializedOfferFile,
      targetPuzzlehash: maker.firstPuzzlehash,
      coinsForFee: [maker.standardCoins[1]],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );
    await fullNodeSimulator.moveToNextBlock();

    final messageCoins =
        await fullNodeSimulator.scroungeForReceivedNotificationCoins([messagePuzzlehash]);

    expect(messageCoins.length, equals(1));

    final messageCoin = messageCoins.single;

    final messageCoinInfo = await exchangeOfferService.parseAndValidateReceivedMessageCoin(
      messageCoin: messageCoin,
      initializationCoinId: initializationCoin.id,
      serializedOfferFile: serializedOfferFile,
      messagePuzzlehash: messagePuzzlehash,
      exchangeType: ExchangeType.xchToBtc,
    );

    final messageCoinChild = await fullNodeSimulator.getSingleChildCoinFromCoin(messageCoin);

    expect(messageCoinChild, isNotNull);
    expect(messageCoinChild!.isSpent, isTrue);

    final messageCoinChildSpentTime =
        await fullNodeSimulator.getDateTimeFromBlockIndex(messageCoinChild.spentBlockIndex);

    expect(messageCoinInfo, isNotNull);
    expect(messageCoinInfo!.messageCoin, equals(messageCoin));
    expect(messageCoinInfo.serializedOfferAcceptFile, equals(serializedOfferAcceptFile));
    expect(messageCoinInfo.fulfillerPublicKey, equals(takerPublicKey));
    expect(
      messageCoinInfo.messageCoinReceivedTime,
      equals(messageCoinInfo.messageCoinReceivedTime),
    );
    expect(messageCoinInfo.exchangeValidityTime, equals(exchangeValidityTime));
    expect(messageCoinInfo.messageCoinDeclinedTime, equals(messageCoinChildSpentTime));
    expect(messageCoinInfo.messageCoinAcceptedTime, isNull);
  });

  test('should transfer funds to escrow puzzlehash', () async {
    final makerEscrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: makerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: takerPublicKey,
    );

    final startingMakerBalance = maker.standardCoins.totalValue;

    await exchangeOfferService.transferFundsToEscrowPuzzlehash(
      initializationCoinId: initializationCoin.id,
      mojos: mojos,
      escrowPuzzlehash: makerEscrowPuzzlehash,
      requestorPrivateKey: makerPrivateKey,
      coinsInput: [maker.standardCoins.first],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final endingMakerBalance = maker.standardCoins.totalValue;

    final escrowCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([escrowPuzzlehash]);

    expect(escrowCoins.totalValue, equals(mojos));
    expect(endingMakerBalance, equals(startingMakerBalance - mojos));
  });

  test('should sweep escrow puzzlehash', () async {
    final makerEscrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: makerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: takerPublicKey,
    );

    await exchangeOfferService.transferFundsToEscrowPuzzlehash(
      initializationCoinId: initializationCoin.id,
      mojos: mojos,
      escrowPuzzlehash: makerEscrowPuzzlehash,
      requestorPrivateKey: makerPrivateKey,
      coinsInput: [maker.standardCoins.first],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final startingTakerBalance = taker.standardCoins.totalValue;

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
    await taker.refreshCoins();

    final endingTakerBalance = taker.standardCoins.totalValue;

    final escrowCoinsAfterSweep =
        await fullNodeSimulator.getCoinsByPuzzleHashes([escrowPuzzlehash]);

    expect(escrowCoinsAfterSweep, isEmpty);
    expect(endingTakerBalance, equals(startingTakerBalance + mojos));
  });

  test('should sweep escrow puzzlehash with fee', () async {
    final makerEscrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: makerPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: takerPublicKey,
    );

    await exchangeOfferService.transferFundsToEscrowPuzzlehash(
      initializationCoinId: initializationCoin.id,
      mojos: mojos,
      escrowPuzzlehash: makerEscrowPuzzlehash,
      requestorPrivateKey: makerPrivateKey,
      coinsInput: [maker.standardCoins.first],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final startingTakerBalance = taker.standardCoins.totalValue;

    await exchangeOfferService.sweepEscrowPuzzlehash(
      initializationCoinId: initializationCoin.id,
      escrowPuzzlehash: escrowPuzzlehash,
      requestorPuzzlehash: taker.firstPuzzlehash,
      requestorPrivateKey: takerPrivateKey,
      exchangeValidityTime: exchangeValidityTime,
      paymentHash: paymentHash,
      preimage: preimage,
      fulfillerPublicKey: makerPublicKey,
      fee: fee,
      keychain: taker.keychain,
      coinsForFee: [taker.standardCoins.first],
      changePuzzlehash: taker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await taker.refreshCoins();

    final endingTakerBalance = taker.standardCoins.totalValue;

    final escrowCoinsAfterSweep =
        await fullNodeSimulator.getCoinsByPuzzleHashes([escrowPuzzlehash]);

    expect(escrowCoinsAfterSweep, isEmpty);
    expect(endingTakerBalance, equals(startingTakerBalance + mojos - fee));
  });

  test('should claw back escrow funds', () async {
    // shorten delay for testing purposes
    const shortenedValidity = 5;

    // maker transfers funds to escrow puzzlehash
    final makerEscrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: makerPrivateKey,
      clawbackDelaySeconds: shortenedValidity,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: takerPublicKey,
    );

    await exchangeOfferService.transferFundsToEscrowPuzzlehash(
      initializationCoinId: initializationCoin.id,
      mojos: mojos,
      escrowPuzzlehash: makerEscrowPuzzlehash,
      requestorPrivateKey: makerPrivateKey,
      coinsInput: [maker.standardCoins.first],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final startingMakerBalance = maker.standardCoins.totalValue;

    // the earliest you can spend a time-locked coin is 2 blocks later, since the time is checked
    // against the timestamp of the previous block
    for (var i = 0; i < 2; i++) {
      await fullNodeSimulator.moveToNextBlock();
    }

    // wait until clawback delay period has passed
    await Future<void>.delayed(const Duration(seconds: 10), () async {
      // maker claws back funds at escrow puzzlehash
      await exchangeOfferService.clawbackEscrowFunds(
        initializationCoinId: initializationCoin.id,
        escrowPuzzlehash: makerEscrowPuzzlehash,
        requestorPuzzlehash: maker.firstPuzzlehash,
        requestorPrivateKey: makerPrivateKey,
        exchangeValidityTime: shortenedValidity,
        paymentHash: paymentHash,
        fulfillerPublicKey: takerPublicKey,
      );

      await fullNodeSimulator.moveToNextBlock();
      await maker.refreshCoins();

      final endingMakerBalance = maker.standardCoins.totalValue;
      expect(endingMakerBalance, equals(startingMakerBalance + mojos));
    });
  });

  test('should claw back escrow funds with fee', () async {
    // shorten delay for testing purposes
    const shortenedValidity = 5;

    // maker transfers funds to escrow puzzlehash
    final makerEscrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: makerPrivateKey,
      clawbackDelaySeconds: shortenedValidity,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: takerPublicKey,
    );

    await exchangeOfferService.transferFundsToEscrowPuzzlehash(
      initializationCoinId: initializationCoin.id,
      mojos: mojos,
      escrowPuzzlehash: makerEscrowPuzzlehash,
      requestorPrivateKey: makerPrivateKey,
      coinsInput: [maker.standardCoins.first],
      keychain: maker.keychain,
      changePuzzlehash: maker.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();
    await maker.refreshCoins();

    final startingMakerBalance = maker.standardCoins.totalValue;

    // the earliest you can spend a time-locked coin is 2 blocks later, since the time is checked
    // against the timestamp of the previous block
    for (var i = 0; i < 2; i++) {
      await fullNodeSimulator.moveToNextBlock();
    }

    // wait until clawback delay period has passed
    await Future<void>.delayed(const Duration(seconds: 10), () async {
      // maker claws back funds at escrow puzzlehash
      await exchangeOfferService.clawbackEscrowFunds(
        initializationCoinId: initializationCoin.id,
        escrowPuzzlehash: makerEscrowPuzzlehash,
        requestorPuzzlehash: maker.firstPuzzlehash,
        requestorPrivateKey: makerPrivateKey,
        exchangeValidityTime: shortenedValidity,
        paymentHash: paymentHash,
        fulfillerPublicKey: takerPublicKey,
        fee: fee,
        coinsForFee: [maker.standardCoins.first],
        keychain: maker.keychain,
        changePuzzlehash: maker.firstPuzzlehash,
      );

      await fullNodeSimulator.moveToNextBlock();
      await maker.refreshCoins();

      final endingMakerBalance = maker.standardCoins.totalValue;
      expect(endingMakerBalance, equals(startingMakerBalance + mojos - fee));
    });
  });
}
