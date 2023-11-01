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

  test('should create and find DID', () async {
    final didsBefore = await fullNodeSimulator
        .getDidRecordsByPuzzleHashes([walletVector.puzzlehash]);

    final didSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: [standardCoins[0]],
      targetPuzzleHash: walletVector.puzzlehash,
      keychain: keychain,
      changePuzzlehash: puzzlehash,
    );

    await fullNodeSimulator.pushTransaction(didSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final didsAfter =
        await fullNodeSimulator.getDidRecordsFromHint(walletVector.puzzlehash);
    expect(didsAfter.length, equals(didsBefore.length + 1));

    final did = await fullNodeSimulator.getCoinById(didsAfter[0].did);
    expect(did, isNotNull);
  });

  test('should create DID with backupIds', () async {
    final didsBefore = await fullNodeSimulator
        .getDidRecordsByPuzzleHashes([walletVector.puzzlehash]);

    final didSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: [standardCoins[1]],
      targetPuzzleHash: walletVector.puzzlehash,
      backupIds:
          keychain.unhardenedMap.values.map((wv) => wv.puzzlehash).toList(),
      keychain: keychain,
      changePuzzlehash: puzzlehash,
    );

    await fullNodeSimulator.pushTransaction(didSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final didsAfter = await fullNodeSimulator
        .getDidRecordsByPuzzleHashes([walletVector.puzzlehash]);
    expect(didsAfter.length, equals(didsBefore.length + 1));
  });

  test('should create DID with fee', () async {
    final didsBefore = await fullNodeSimulator
        .getDidRecordsByPuzzleHashes([walletVector.puzzlehash]);

    final didSpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: [standardCoins[2]],
      targetPuzzleHash: walletVector.puzzlehash,
      keychain: keychain,
      changePuzzlehash: puzzlehash,
      fee: 100,
    );

    await fullNodeSimulator.pushTransaction(didSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final didsAfter = await fullNodeSimulator
        .getDidRecordsByPuzzleHashes([walletVector.puzzlehash]);
    expect(didsAfter.length, equals(didsBefore.length + 1));

    final did = await fullNodeSimulator.getCoinById(didsAfter[0].did);
    expect(did, isNotNull);
  });
}
