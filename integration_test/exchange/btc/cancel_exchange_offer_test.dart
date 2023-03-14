@Timeout(Duration(minutes: 1))
import 'dart:async';
import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/service/exchange_offer_service.dart';
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

  final maker = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
  for (var i = 0; i < 3; i++) {
    await maker.farmCoins();
  }
  await maker.refreshCoins();

  final makerMasterPrivateKey = maker.keychainSecret.masterPrivateKey;
  final makerDerivationIndex = Random.secure().nextInt(9000000) + 1000000;

  final makerWalletVector = WalletVector.fromPrivateKey(
    makerMasterPrivateKey,
    makerDerivationIndex,
  );

  final makerPrivateKey = makerWalletVector.childPrivateKey;
  final makerPublicKey = makerPrivateKey.getG1();

  const mojos = 200000000;
  const satoshis = 100;

  final exchangeWalletVector = WalletVector.fromPrivateKey(makerPrivateKey, 1);
  final messagePuzzlehash = exchangeWalletVector.puzzlehash;
  final messageAddress = Address.fromContext(messagePuzzlehash);

  const offerValidityTimeHours = 1;
  final currentUnixTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final offerValidityTime = currentUnixTimeStamp + (offerValidityTimeHours * 60 * 60);

  const paymentRequest =
      'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';
  final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

  final offerFile = crossChainOfferService.createXchToBtcOfferFile(
    amountMojos: mojos,
    amountSatoshis: satoshis,
    messageAddress: messageAddress,
    validityTime: offerValidityTime,
    requestorPublicKey: makerPublicKey,
    paymentRequest: decodedPaymentRequest,
  );

  final serializedOfferFile = offerFile.serialize(makerPrivateKey);

  final initializationCoin = maker.standardCoins.first;
  final initializationCoinId = initializationCoin.id;

  await exchangeOfferService.pushInitializationSpendBundle(
    messagePuzzlehash: messagePuzzlehash,
    initializationCoin: initializationCoin,
    keychain: maker.keychain,
    derivationIndex: makerDerivationIndex,
    serializedOfferFile: serializedOfferFile,
    changePuzzlehash: maker.firstPuzzlehash,
  );
  await fullNodeSimulator.moveToNextBlock();
  await maker.refreshCoins();

  final spentInitializationCoin = await fullNodeSimulator.getCoinById(initializationCoinId);
  final initializationCoinSpend = await fullNodeSimulator.getCoinSpend(spentInitializationCoin!);

  final taker = ChiaEnthusiast(fullNodeSimulator, walletSize: 10);
  for (var i = 0; i < 3; i++) {
    await taker.farmCoins();
  }
  await taker.refreshCoins();

  final takerMasterPrivateKey = taker.keychainSecret.masterPrivateKey;
  final takerDerivationIndex = Random.secure().nextInt(10);

  final takerWalletVector = WalletVector.fromPrivateKey(
    takerMasterPrivateKey,
    takerDerivationIndex,
  );

  final takerPrivateKey = takerWalletVector.childPrivateKey;
  final takerPublicKey = takerWalletVector.childPublicKey;

  const exchangeValidityTime = 600;

  final offerAcceptFile = crossChainOfferService.createBtcToXchAcceptFile(
    serializedOfferFile: serializedOfferFile,
    validityTime: exchangeValidityTime,
    requestorPublicKey: takerPublicKey,
  );

  final serializedOfferAcceptFile = offerAcceptFile.serialize(takerPrivateKey);

  test(
      'should spend initialization coin and create 3 mojo child coin with memos in expected format',
      () async {
    final memos = await initializationCoinSpend!.memos;

    expect(memos.length, equals(2));
    expect(memos.first, encodeInt(makerDerivationIndex));
    expect(memos.last, equals(Bytes.encodeFromString(serializedOfferFile)));
  });

  test(
      'should cancel an exchange offer by spending 3 mojo child of initialization coin at message puzzlehash with expected memo',
      () async {
    final cancelCoinId = initializationCoinSpend!.additions
        .where((addition) => addition.puzzlehash == messagePuzzlehash && addition.amount == 3)
        .single
        .id;
    final unspentCancelCoin = await fullNodeSimulator.getCoinById(cancelCoinId);

    expect(unspentCancelCoin!.spentBlockIndex == 0, isTrue);

    await exchangeOfferService.cancelExchangeOffer(
      initializationCoinId: initializationCoinId,
      messagePuzzlehash: messagePuzzlehash,
      masterPrivateKey: makerMasterPrivateKey,
      derivationIndex: makerDerivationIndex,
    );
    await fullNodeSimulator.moveToNextBlock();

    final spentCancelCoin = await fullNodeSimulator.getCoinById(cancelCoinId);

    expect(spentCancelCoin!.isSpent, isTrue);

    final cancellationCoinSpend = await fullNodeSimulator.getCoinSpend(spentCancelCoin);
    final memos = await cancellationCoinSpend!.memos;

    expect(memos.contains(initializationCoinId), isTrue);
  });
}
