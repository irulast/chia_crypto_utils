@Timeout(Duration(minutes: 2))
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
  final exchangeOfferRecordHydrationService =
      ExchangeOfferRecordHydrationService(fullNodeSimulator);

  late ChiaEnthusiast nathan;
  setUp(() async {
    nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await nathan.farmCoins();
    await nathan.refreshCoins();
  });

  test('should throw exception when trying to hydrate invalid initialization coin', () async {
    expect(
      () async {
        await exchangeOfferRecordHydrationService.hydrateExchangeInitializationCoin(
          nathan.standardCoins.first,
          nathan.keychainSecret.masterPrivateKey,
          nathan.keychain,
        );
      },
      throwsA(isA<InvalidInitializationCoinException>()),
    );
  });

  test('should throw exception when trying to hydrate invalid message coin', () async {
    // creating notification coin that isn't an exchange message coin
    final notificationService = NotificationWalletService();

    final targetPuzzlehash = nathan.puzzlehashes[1];

    final notificationSpendBundle = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: targetPuzzlehash,
      message: [Memo(encodeInt(1000))],
      amount: minimumNotificationCoinAmount,
      coinsInput: [nathan.standardCoins.first],
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(notificationSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final notificationCoin =
        (await fullNodeSimulator.scroungeForReceivedNotificationCoins([targetPuzzlehash])).single;

    expect(
      () async {
        await exchangeOfferRecordHydrationService.hydrateSentMessageCoin(
          notificationCoin,
          nathan.keychain,
        );
      },
      throwsA(isA<InvalidMessageCoinException>()),
    );
  });
}
