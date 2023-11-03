@Skip('multiple recovery ids is not working')
// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final didWalletService = DIDWalletService();

  final recoveryEnthusiasts = <ChiaEnthusiast>[];
  for (var i = 0; i < 5; i++) {
    final chiaEnthusiast = ChiaEnthusiast(fullNodeSimulator);
    await chiaEnthusiast.farmCoins();
    await chiaEnthusiast.issueDid();
  }

  final recoverableEnthusiast = ChiaEnthusiast(fullNodeSimulator);
  await recoverableEnthusiast.farmCoins();
  await recoverableEnthusiast.issueDid(
    recoveryEnthusiasts
        .map(
          (e) => e.didInfo!.did,
        )
        .toList(),
  );

  test('should recover did with multiple backup ids', () async {
    final firstRecoveringEnthusiast = ChiaEnthusiast(fullNodeSimulator);

    var newInnerPuzzlehash = DIDWalletService.createInnerPuzzleForPk(
      publicKey: firstRecoveringEnthusiast.firstWalletVector.childPublicKey,
      backupIdsHash:
          recoveryEnthusiasts.map((e) => e.didInfo!.did).toList().programHash(),
      launcherCoinId: recoverableEnthusiast.didInfo!.did,
      nVerificationsRequired:
          recoveryEnthusiasts.map((e) => e.didInfo!.did).toList().length,
      metadataProgram: null,
    ).hash();

    var messageSpendBundle = SpendBundle(coinSpends: const []);

    for (final recoveryEnthusiast in recoveryEnthusiasts) {
      final attestment = didWalletService.createAttestment(
        attestmentMakerDidInfo: recoveryEnthusiast.didInfo!,
        recoveringDidInfo: recoverableEnthusiast.didInfo!,
        attestmentMakerPrivateKey:
            recoveryEnthusiast.firstWalletVector.childPrivateKey,
        newPublicKey:
            firstRecoveringEnthusiast.firstWalletVector.childPublicKey,
        newInnerPuzzlehash: newInnerPuzzlehash,
      );
      await fullNodeSimulator.pushTransaction(attestment.attestmentSpendBundle);
      await fullNodeSimulator.moveToNextBlock();

      messageSpendBundle += attestment.messageSpendBundle;
    }

    final firstRecoverySpendBundle = didWalletService.createRecoverySpendBundle(
      recoverableEnthusiast.didInfo!,
      firstRecoveringEnthusiast.firstWalletVector.childPrivateKey,
      newInnerPuzzlehash,
      recoveryEnthusiasts.map((e) => e.didInfo!.recoveryInfo).toList(),
      recoveryEnthusiasts.map((e) => e.didInfo!.did).toList(),
      messageSpendBundle,
    );
    // recoverySpendBundle.debug();
    await fullNodeSimulator.pushTransaction(firstRecoverySpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    for (final recoveryEnthusiast in recoveryEnthusiasts) {
      await recoveryEnthusiast.refreshDidInfo();
    }

    await firstRecoveringEnthusiast
        .recoverDid(recoverableEnthusiast.didInfo!.did);

    expect(
      firstRecoveringEnthusiast.didInfo!.p2Puzzle,
      equals(
        getPuzzleFromPk(
          firstRecoveringEnthusiast.firstWalletVector.childPublicKey,
        ),
      ),
    );

    final secondRecoveringEnthusiast = ChiaEnthusiast(fullNodeSimulator);

    newInnerPuzzlehash = DIDWalletService.createInnerPuzzleForPk(
      publicKey: secondRecoveringEnthusiast.firstWalletVector.childPublicKey,
      backupIdsHash:
          recoveryEnthusiasts.map((e) => e.didInfo!.did).toList().programHash(),
      launcherCoinId: firstRecoveringEnthusiast.didInfo!.did,
      nVerificationsRequired:
          recoveryEnthusiasts.map((e) => e.didInfo!.did).toList().length,
      metadataProgram: null,
    ).hash();

    messageSpendBundle = SpendBundle(coinSpends: const []);

    for (final recoveryEnthusiast in recoveryEnthusiasts) {
      final attestment = didWalletService.createAttestment(
        attestmentMakerDidInfo: recoveryEnthusiast.didInfo!,
        recoveringDidInfo: firstRecoveringEnthusiast.didInfo!,
        attestmentMakerPrivateKey:
            recoveryEnthusiast.firstWalletVector.childPrivateKey,
        newPublicKey:
            secondRecoveringEnthusiast.firstWalletVector.childPublicKey,
        newInnerPuzzlehash: newInnerPuzzlehash,
      );
      await fullNodeSimulator.pushTransaction(attestment.attestmentSpendBundle);
      await fullNodeSimulator.moveToNextBlock();

      messageSpendBundle += attestment.messageSpendBundle;
    }

    final secondRecoverySpendBundle =
        didWalletService.createRecoverySpendBundle(
      firstRecoveringEnthusiast.didInfo!,
      secondRecoveringEnthusiast.firstWalletVector.childPrivateKey,
      newInnerPuzzlehash,
      recoveryEnthusiasts.map((e) => e.didInfo!.recoveryInfo).toList(),
      recoveryEnthusiasts.map((e) => e.didInfo!.did).toList(),
      messageSpendBundle,
    );
    // recoverySpendBundle.debug();
    await fullNodeSimulator.pushTransaction(secondRecoverySpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    await secondRecoveringEnthusiast
        .recoverDid(recoverableEnthusiast.didInfo!.did);

    expect(
      secondRecoveringEnthusiast.didInfo!.p2Puzzle,
      equals(
        getPuzzleFromPk(
          secondRecoveringEnthusiast.firstWalletVector.childPublicKey,
        ),
      ),
    );
  });
}
