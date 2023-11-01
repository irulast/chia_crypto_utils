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

  final keychain = WalletKeychain.fromCoreSecret(
    keychainSecret,
    walletSize: 3,
  );

  final walletVector = keychain.unhardenedMap.values.first;
  final exitWalletVector = keychain.unhardenedMap.values.toList()[1];

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final didWalletService = DIDWalletService();

  final puzzlehash = walletVector.puzzlehash;
  final address = Address.fromPuzzlehash(
      puzzlehash, didWalletService.blockchainNetwork.addressPrefix);

  await fullNodeSimulator.farmCoins(address);
  await fullNodeSimulator.farmCoins(address);
  await fullNodeSimulator.moveToNextBlock();

  final standardCoins =
      await fullNodeSimulator.getCoinsByPuzzleHashes([puzzlehash]);

  final didSpendBundle = didWalletService.createGenerateDIDSpendBundle(
    standardCoins: [standardCoins[0]],
    targetPuzzleHash: walletVector.puzzlehash,
    keychain: keychain,
    changePuzzlehash: puzzlehash,
  );

  await fullNodeSimulator.pushTransaction(didSpendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final didsAfterCreation =
      await fullNodeSimulator.getDidRecordsFromHint(walletVector.puzzlehash);

  final didInfo = didsAfterCreation[0];

  test('should cash out did', () async {
    final exitSpendBundle = didWalletService.createExitSpend(
      exitWalletVector.puzzlehash,
      didInfo.toDidInfoForPkOrThrow(walletVector.childPublicKey),
      walletVector.childPrivateKey,
    );
    await fullNodeSimulator.pushTransaction(exitSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final didAfterDestruction = await fullNodeSimulator
        .getDidRecordsByPuzzleHashes(
            [walletVector.puzzlehash, exitWalletVector.puzzlehash]);
    expect(didAfterDestruction.length, equals(0));

    final newStandardCoins = await fullNodeSimulator
        .getCoinsByPuzzleHashes([exitWalletVector.puzzlehash]);
    expect(newStandardCoins.length, equals(1));

    final newStandardCoin = newStandardCoins[0];
    expect(newStandardCoin.amount, equals(didInfo.coin.amount - 1));

    // should be able to spend standardCoin
    final standardSpendBundle =
        didWalletService.standardWalletService.createSpendBundle(
      payments: [Payment(newStandardCoin.amount, exitWalletVector.puzzlehash)],
      coinsInput: [newStandardCoin],
      keychain: keychain,
    );

    await fullNodeSimulator.pushTransaction(standardSpendBundle);
    await fullNodeSimulator.moveToNextBlock();
  });
}
