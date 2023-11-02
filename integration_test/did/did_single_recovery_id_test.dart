// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  final keychainSecret = KeychainCoreSecret.generate();

  final keychain = WalletKeychain.fromCoreSecret(keychainSecret);
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final didWalletService = DIDWalletService();

  final recoveryDidWv = keychain.unhardenedMap.values.toList()[0];
  final recoveryDidAddress = Address.fromPuzzlehash(
    recoveryDidWv.puzzlehash,
    didWalletService.blockchainNetwork.addressPrefix,
  );
  await fullNodeSimulator.farmCoins(recoveryDidAddress);
  await fullNodeSimulator.moveToNextBlock();

  final recoveryDidStandardCoins = await fullNodeSimulator
      .getCoinsByPuzzleHashes([recoveryDidWv.puzzlehash]);

  final didRecoverySpendBundle = didWalletService.createGenerateDIDSpendBundle(
    standardCoins: [recoveryDidStandardCoins[0]],
    targetPuzzleHash: recoveryDidWv.puzzlehash,
    keychain: keychain,
    changePuzzlehash: recoveryDidWv.puzzlehash,
  );

  await fullNodeSimulator.pushTransaction(didRecoverySpendBundle);

  await fullNodeSimulator.moveToNextBlock();

  final recoveryDidInfos =
      await fullNodeSimulator.getDidRecordsFromHint(recoveryDidWv.puzzlehash);
  var recoveryDidWallet = DidWallet(
    recoveryDidWv,
    recoveryDidInfos[0].toDidInfoForPkOrThrow(recoveryDidWv.childPublicKey),
  );

  final recoverableDidWv = keychain.unhardenedMap.values.toList()[1];
  final recoverableDidAddress = Address.fromPuzzlehash(
    recoverableDidWv.puzzlehash,
    didWalletService.blockchainNetwork.addressPrefix,
  );
  await fullNodeSimulator.farmCoins(recoverableDidAddress);
  await fullNodeSimulator.moveToNextBlock();

  final recoverableDidStandardCoins = await fullNodeSimulator
      .getCoinsByPuzzleHashes([recoverableDidWv.puzzlehash]);

  final recoverableDidSpendBundle =
      didWalletService.createGenerateDIDSpendBundle(
    standardCoins: [recoverableDidStandardCoins[0]],
    targetPuzzleHash: recoverableDidWv.puzzlehash,
    keychain: keychain,
    changePuzzlehash: recoverableDidWv.puzzlehash,
    backupIds: [recoveryDidWallet.didInfo.did],
  );

  await fullNodeSimulator.pushTransaction(recoverableDidSpendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final didInfos = await fullNodeSimulator
      .getDidRecordsByPuzzleHashes([recoverableDidWv.puzzlehash]);
  var recoverableDidInfo = didInfos[0];

  test('should recover did with single backup id', () async {
    final keychainSecret = KeychainCoreSecret.generate();
    final keychain = WalletKeychain.fromCoreSecret(
      keychainSecret,
      walletSize: 3,
    );
    final walletVector = keychain.unhardenedMap.values.first;

    var newPublicKey = walletVector.childPublicKey;
    var newPrivateKey = walletVector.childPrivateKey;

    var newInnerPuzzlehash = DIDWalletService.createInnerPuzzleForPk(
      publicKey: newPublicKey,
      backupIdsHash: [recoveryDidWallet.didInfo.did].programHash(),
      launcherCoinId: recoverableDidInfo.did,
      nVerificationsRequired: 1,
      metadataProgram: null,
    ).hash();

    var attestment = didWalletService.createAttestment(
      attestmentMakerDidInfo: recoveryDidWallet.didInfo,
      recoveringDidInfo: recoverableDidInfo,
      attestmentMakerPrivateKey: recoveryDidWallet.walletVector.childPrivateKey,
      newPublicKey: newPublicKey,
      newInnerPuzzlehash: newInnerPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(attestment.attestmentSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    var messageSpendBundle = attestment.messageSpendBundle;

    final recoverySpendBundle = didWalletService.createRecoverySpendBundle(
      recoverableDidInfo,
      newPrivateKey,
      newInnerPuzzlehash,
      [recoveryDidWallet.didInfo.recoveryInfo],
      [recoveryDidWallet.didInfo.did],
      messageSpendBundle,
    );
    await fullNodeSimulator.pushTransaction(recoverySpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    print('finished first recovery');

    recoveryDidWallet = DidWallet(
      recoveryDidWallet.walletVector,
      (await fullNodeSimulator
              .getDidRecordForDid(recoveryDidWallet.didInfo.did))!
          .toDidInfoForPkOrThrow(recoveryDidWallet.walletVector.childPublicKey),
    );

    recoverableDidInfo =
        (await fullNodeSimulator.getDidRecordForDid(recoverableDidInfo.did))!
            .toDidInfoForPkOrThrow(newPublicKey);

    expect(
      (recoverableDidInfo as DidInfo).p2Puzzle,
      equals(getPuzzleFromPk(newPublicKey)),
    );

    final newerWalletVector = keychain.unhardenedMap.values.toList()[1];
    newPublicKey = newerWalletVector.childPublicKey;
    newPrivateKey = newerWalletVector.childPrivateKey;

    newInnerPuzzlehash = DIDWalletService.createInnerPuzzleForPk(
      publicKey: newPublicKey,
      backupIdsHash: [recoveryDidWallet.didInfo.did].programHash(),
      launcherCoinId: recoverableDidInfo.did,
      nVerificationsRequired: 1,
      metadataProgram: null,
    ).hash();

    attestment = didWalletService.createAttestment(
      attestmentMakerDidInfo: recoveryDidWallet.didInfo,
      recoveringDidInfo: recoverableDidInfo,
      attestmentMakerPrivateKey: recoveryDidWallet.walletVector.childPrivateKey,
      newPublicKey: newPublicKey,
      newInnerPuzzlehash: newInnerPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(attestment.attestmentSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    messageSpendBundle = attestment.messageSpendBundle;

    final recoverySpendBundle1 = didWalletService.createRecoverySpendBundle(
      recoverableDidInfo,
      newPrivateKey,
      newInnerPuzzlehash,
      [recoveryDidWallet.didInfo.recoveryInfo],
      [recoveryDidWallet.didInfo.did],
      messageSpendBundle,
    );
    await fullNodeSimulator.pushTransaction(recoverySpendBundle1);
    await fullNodeSimulator.moveToNextBlock();

    print('finished second recovery');

    recoverableDidInfo =
        (await fullNodeSimulator.getDidRecordForDid(recoverableDidInfo.did))!
            .toDidInfoForPkOrThrow(newPublicKey);
    expect(
      (recoverableDidInfo as DidInfo).p2Puzzle,
      equals(getPuzzleFromPk(newPublicKey)),
    );
  });
}

class DidWallet {
  DidWallet(this.walletVector, this.didInfo);
  final WalletVector walletVector;
  final DidInfo didInfo;
}
