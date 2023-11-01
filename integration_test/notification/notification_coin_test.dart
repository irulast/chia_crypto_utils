@Timeout(Duration(minutes: 1))
import 'dart:async';

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
  final notificationService = NotificationWalletService();
  final standardWalletService = StandardWalletService();

  final memo = Bytes.encodeFromString('hello, world');
  final memo2 = encodeInt(1000);

  late ChiaEnthusiast sender;
  late Puzzlehash targetPuzzlehash;
  late Coin coinForNotificationSpend;
  setUp(() async {
    sender = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await sender.farmCoins();
    await sender.refreshCoins();

    final receiver = ChiaEnthusiast(fullNodeSimulator);
    targetPuzzlehash = receiver.firstPuzzlehash;

    coinForNotificationSpend = sender.standardCoins.first;
  });

  test('should send and parse notification coin', () async {
    final notificationSpendBundle = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: targetPuzzlehash,
      message: [Memo(memo)],
      amount: minimumNotificationCoinAmount,
      coinsInput: [coinForNotificationSpend],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(notificationSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final coinsByHint =
        await fullNodeSimulator.getCoinsByHints([targetPuzzlehash], includeSpentCoins: true);

    expect(coinsByHint.length, equals(1));

    final notificationCoin = coinsByHint.single;

    final expectedNotificationPuzzlehash = notificationProgram.curry([
      Program.fromBytes(targetPuzzlehash),
      Program.fromInt(minimumNotificationCoinAmount)
    ]).hash();

    expect(notificationCoin.isSpent, isTrue);
    expect(notificationCoin.amount, minimumNotificationCoinAmount);
    expect(notificationCoin.puzzlehash, equals(expectedNotificationPuzzlehash));
    expect(notificationCoin.parentCoinInfo, equals(coinForNotificationSpend.id));

    final fullNotificationCoin =
        await fullNodeSimulator.getNotificationCoinFromCoin(notificationCoin);

    expect(fullNotificationCoin, isNotNull);
    expect(fullNotificationCoin!.targetPuzzlehash, equals(targetPuzzlehash));
    expect(fullNotificationCoin.message.single, equals(memo));
  });

  test('should return null when trying to parse standard hinted coin', () async {
    final standardSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          minimumNotificationCoinAmount,
          targetPuzzlehash,
          memos: <Memo>[Memo(targetPuzzlehash)],
        )
      ],
      coinsInput: [coinForNotificationSpend],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(standardSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final coinsByHint = await fullNodeSimulator.getCoinsByHint(targetPuzzlehash);
    expect(coinsByHint.length, equals(1));

    final coinByHint = coinsByHint.single;

    final notificationCoin = await fullNodeSimulator.getNotificationCoinFromCoin(coinByHint);
    expect(notificationCoin, isNull);
  });

  test('should throw exception when trying to construct notification coin from standard coin spend',
      () async {
    final standardSpendBundle = standardWalletService.createSpendBundle(
      payments: [Payment(minimumNotificationCoinAmount, sender.puzzlehashes[1])],
      coinsInput: [coinForNotificationSpend],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(standardSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final spentCoin = await fullNodeSimulator.getCoinById(coinForNotificationSpend.id);

    final coinSpend = await fullNodeSimulator.getCoinSpend(spentCoin!);
    final childCoin =
        coinSpend!.additions.where((coin) => coin.amount == minimumNotificationCoinAmount).single;

    final secondSpendBundle = standardWalletService.createSpendBundle(
      payments: [Payment(minimumNotificationCoinAmount, targetPuzzlehash)],
      coinsInput: [childCoin],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(secondSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final spentChildCoin = await fullNodeSimulator.getCoinById(childCoin.id);

    expect(
      () async {
        await NotificationCoin.fromParentSpend(
          parentCoinSpend: coinSpend,
          coin: spentChildCoin!,
        );
      },
      throwsA(isA<InvalidNotificationCoinException>()),
    );
  });

  test('should send and parse notification coin with multiple memos', () async {
    final notificationSpendBundle = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: targetPuzzlehash,
      message: [Memo(memo), Memo(memo2)],
      amount: minimumNotificationCoinAmount,
      coinsInput: [coinForNotificationSpend],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(notificationSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final coinsByHint =
        await fullNodeSimulator.getCoinsByHints([targetPuzzlehash], includeSpentCoins: true);

    expect(coinsByHint.length, equals(1));

    final notificationCoin = coinsByHint.single;

    final expectedNotificationPuzzlehash = notificationProgram.curry([
      Program.fromBytes(targetPuzzlehash),
      Program.fromInt(minimumNotificationCoinAmount)
    ]).hash();

    expect(notificationCoin.isSpent, isTrue);
    expect(notificationCoin.amount, minimumNotificationCoinAmount);
    expect(notificationCoin.puzzlehash, equals(expectedNotificationPuzzlehash));
    expect(notificationCoin.parentCoinInfo, equals(coinForNotificationSpend.id));

    final fullNotificationCoin =
        await fullNodeSimulator.getNotificationCoinFromCoin(notificationCoin);

    expect(fullNotificationCoin, isNotNull);
    expect(fullNotificationCoin!.targetPuzzlehash, equals(targetPuzzlehash));
    expect(fullNotificationCoin.message.length, equals(2));
    expect(fullNotificationCoin.message.first, equals(memo));
    expect(fullNotificationCoin.message.last, equals(memo2));
  });

  test('should find received notification coin', () async {
    final notificationSpendBundle = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: targetPuzzlehash,
      message: [Memo(memo)],
      amount: minimumNotificationCoinAmount,
      coinsInput: [coinForNotificationSpend],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(notificationSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final receivedNotificationCoins =
        await fullNodeSimulator.scroungeForReceivedNotificationCoins([targetPuzzlehash]);

    expect(receivedNotificationCoins.length, equals(1));

    final notificationCoin = receivedNotificationCoins.single;

    expect(notificationCoin.amount, equals(minimumNotificationCoinAmount));
    expect(notificationCoin.message.single, equals(memo));
    expect(notificationCoin.targetPuzzlehash, equals(targetPuzzlehash));
    expect(notificationCoin.parentCoinInfo, equals(coinForNotificationSpend.id));
  });

  test('should find multiple received notification coins', () async {
    final notificationSpendBundle = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: targetPuzzlehash,
      message: [Memo(memo)],
      amount: minimumNotificationCoinAmount,
      coinsInput: [coinForNotificationSpend],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(notificationSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final sender2 = ChiaEnthusiast(fullNodeSimulator);
    await sender2.farmCoins();
    await sender2.refreshCoins();
    final coinForNotificationSpend2 = sender2.standardCoins.first;

    final notificationSpendBundle2 = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: targetPuzzlehash,
      message: [Memo(memo2)],
      amount: minimumNotificationCoinAmount,
      coinsInput: [coinForNotificationSpend2],
      keychain: sender2.keychain,
      changePuzzlehash: sender2.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(notificationSpendBundle2);
    await fullNodeSimulator.moveToNextBlock();

    final receivedNotificationCoins =
        await fullNodeSimulator.scroungeForReceivedNotificationCoins([targetPuzzlehash]);

    expect(receivedNotificationCoins.length, equals(2));

    final notificationCoin1 = receivedNotificationCoins
        .where((coin) => coin.parentCoinInfo == coinForNotificationSpend.id)
        .single;

    expect(notificationCoin1.amount, equals(minimumNotificationCoinAmount));
    expect(notificationCoin1.message.single, equals(memo));
    expect(notificationCoin1.targetPuzzlehash, equals(targetPuzzlehash));

    final notificationCoin2 = receivedNotificationCoins
        .where((coin) => coin.parentCoinInfo == coinForNotificationSpend2.id)
        .single;

    expect(notificationCoin2.amount, equals(minimumNotificationCoinAmount));
    expect(notificationCoin2.message.single, equals(memo2));
    expect(notificationCoin2.targetPuzzlehash, equals(targetPuzzlehash));
    expect(notificationCoin2.parentCoinInfo, equals(coinForNotificationSpend2.id));
  });

  test('should find sent notification coin', () async {
    final notificationSpendBundle = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: targetPuzzlehash,
      message: [Memo(memo)],
      amount: minimumNotificationCoinAmount,
      coinsInput: [coinForNotificationSpend],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(notificationSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final sentNotificationCoins =
        await fullNodeSimulator.scroungeForSentNotificationCoins(sender.puzzlehashes);

    expect(sentNotificationCoins.length, equals(1));

    final notificationCoin = sentNotificationCoins.single;

    expect(notificationCoin.amount, equals(minimumNotificationCoinAmount));
    expect(notificationCoin.message.single, equals(memo));
    expect(notificationCoin.targetPuzzlehash, equals(targetPuzzlehash));
    expect(notificationCoin.parentCoinInfo, equals(coinForNotificationSpend.id));
  });

  test('should find multiple sent notification coins', () async {
    final notificationSpendBundle = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: targetPuzzlehash,
      message: [Memo(memo)],
      amount: minimumNotificationCoinAmount,
      coinsInput: [coinForNotificationSpend],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );

    final coinForNotificationSpend2 = sender.standardCoins.last;

    final notificationSpendBundle2 = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: targetPuzzlehash,
      message: [Memo(memo2)],
      amount: minimumNotificationCoinAmount,
      coinsInput: [coinForNotificationSpend2],
      keychain: sender.keychain,
      changePuzzlehash: sender.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(notificationSpendBundle + notificationSpendBundle2);
    await fullNodeSimulator.moveToNextBlock();

    final sentNotificationCoins =
        await fullNodeSimulator.scroungeForSentNotificationCoins(sender.puzzlehashes);

    final notificationCoin1 = sentNotificationCoins
        .where((coin) => coin.parentCoinInfo == coinForNotificationSpend.id)
        .single;

    expect(notificationCoin1.amount, equals(minimumNotificationCoinAmount));
    expect(notificationCoin1.message.single, equals(memo));
    expect(notificationCoin1.targetPuzzlehash, equals(targetPuzzlehash));

    final notificationCoin2 = sentNotificationCoins
        .where((coin) => coin.parentCoinInfo == coinForNotificationSpend2.id)
        .single;

    expect(notificationCoin2.amount, equals(minimumNotificationCoinAmount));
    expect(notificationCoin2.message.single, equals(memo2));
    expect(notificationCoin2.targetPuzzlehash, equals(targetPuzzlehash));
    expect(notificationCoin2.parentCoinInfo, equals(coinForNotificationSpend2.id));
  });
}
