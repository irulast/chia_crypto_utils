// ignore_for_file: lines_longer_than_80_chars
@Skip('Update isnt finished')
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

  final recoveryDidStandardCoins =
      await fullNodeSimulator.getCoinsByPuzzleHashes([recoveryDidWv.puzzlehash]);

  final didRecoverySpendBundle = didWalletService.createGenerateDIDSpendBundle(
    standardCoins: [recoveryDidStandardCoins[0]],
    targetPuzzleHash: recoveryDidWv.puzzlehash,
    keychain: keychain,
    changePuzzlehash: recoveryDidWv.puzzlehash,
  );

  await fullNodeSimulator.pushTransaction(didRecoverySpendBundle);

  await fullNodeSimulator.moveToNextBlock();

  final recoveryDidInfos =
      await fullNodeSimulator.getDidRecordsByPuzzleHashes([recoveryDidWv.puzzlehash]);
  final recoveryDidWallet = DidWallet(
    recoveryDidWv,
    recoveryDidInfos[0].toDidInfoForPkOrThrow(recoveryDidWv.childPublicKey),
  );

  final didToUpdateWv = keychain.unhardenedMap.values.toList()[1];
  final didToUpdateAddress = Address.fromPuzzlehash(
    didToUpdateWv.puzzlehash,
    didWalletService.blockchainNetwork.addressPrefix,
  );
  await fullNodeSimulator.farmCoins(didToUpdateAddress);
  await fullNodeSimulator.moveToNextBlock();

  final didToUpdateStandardCoins =
      await fullNodeSimulator.getCoinsByPuzzleHashes([didToUpdateWv.puzzlehash]);

  final didToUpdateSpendBundle = didWalletService.createGenerateDIDSpendBundle(
    standardCoins: [didToUpdateStandardCoins[0]],
    targetPuzzleHash: didToUpdateWv.puzzlehash,
    keychain: keychain,
    changePuzzlehash: didToUpdateWv.puzzlehash,
  );

  await fullNodeSimulator.pushTransaction(didToUpdateSpendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final didInfos = await fullNodeSimulator.getDidRecordsByPuzzleHashes([didToUpdateWv.puzzlehash]);
  final didToUpdateInfo = didInfos[0].toDidInfoForPkOrThrow(didToUpdateWv.childPublicKey);

  test('should recover did with single backup id', () async {
    var newInnerPuzzlehash = DIDWalletService.createInnerPuzzle(
      p2Puzzle: didToUpdateInfo.p2Puzzle,
      backupIdsHash: [recoveryDidWallet.didInfo.did].programHash(),
      launcherCoinId: didToUpdateInfo.did,
      nVerificationsRequired: 1,
      metadataProgram: null,
    ).hash();

    final updateSpend = didWalletService.createUpdateSpend(
      didToUpdateInfo,
      didToUpdateWv.childPrivateKey,
      newInnerPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(updateSpend);
    await fullNodeSimulator.moveToNextBlock();

    final recoverableDidInfo = await fullNodeSimulator.getDidRecordForDid(didToUpdateInfo.did);

    final keychainSecret = KeychainCoreSecret.generate();

    final keychain = WalletKeychain.fromCoreSecret(
      keychainSecret,
      walletSize: 3,
    );

    final walletVector = keychain.unhardenedMap.values.first;

    final newPublicKey = walletVector.childPublicKey;
    final newPrivateKey = walletVector.childPrivateKey;

    newInnerPuzzlehash = DIDWalletService.createInnerPuzzleForPk(
      publicKey: newPublicKey,
      backupIdsHash: [recoveryDidWallet.didInfo.did].programHash(),
      launcherCoinId: recoverableDidInfo!.did,
      nVerificationsRequired: 1,
      metadataProgram: null,
    ).hash();

    final attestment = didWalletService.createAttestment(
      attestmentMakerDidInfo: recoveryDidWallet.didInfo,
      recoveringDidInfo: recoverableDidInfo,
      attestmentMakerPrivateKey: recoveryDidWallet.walletVector.childPrivateKey,
      newPublicKey: newPublicKey,
      newInnerPuzzlehash: newInnerPuzzlehash,
    );
    await fullNodeSimulator.pushTransaction(attestment.attestmentSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final messageSpendBundle = attestment.messageSpendBundle;

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
  });
}

class DidWallet {
  DidWallet(this.walletVector, this.didInfo);
  final WalletVector walletVector;
  final DidInfo didInfo;
}
