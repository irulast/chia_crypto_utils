// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

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

  final keychainSecret = KeychainCoreSecret.generate();

  final keychain = WalletKeychain.fromCoreSecret(
    keychainSecret,
    walletSize: 1,
  );
  final walletVector = keychain.unhardenedMap.values.first;

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final didWalletService = DIDWalletService();

  final puzzlehash = walletVector.puzzlehash;
  final address = Address.fromPuzzlehash(
    puzzlehash,
    didWalletService.blockchainNetwork.addressPrefix,
  );

  await fullNodeSimulator.farmCoins(address);
  await fullNodeSimulator.moveToNextBlock();

  final standardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([puzzlehash]);

  final didSpendBundle = didWalletService.createGenerateDIDSpendBundle(
    standardCoins: [standardCoins[0]],
    targetPuzzleHash: walletVector.puzzlehash,
    keychain: keychain,
    changePuzzlehash: puzzlehash,
  );

  await fullNodeSimulator.pushTransaction(didSpendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final didRecords = await fullNodeSimulator.getDidRecordsByPuzzleHashes([walletVector.puzzlehash]);
  assert(didRecords.length == 1, 'should creste one did');
  final origionalDidRecord = didRecords[0];

  test('should correctly verify did signature', () async {
    final didInfo = origionalDidRecord.toDidInfoOrThrow(keychain);

    final walletVector = keychain.getWalletVectorOrThrow(didInfo.p2Puzzle.hash());
    final message = Bytes.encodeFromString('sup');
    final signature = AugSchemeMPL.sign(
      calculateSyntheticPrivateKey(walletVector.childPrivateKey),
      message,
    );

    // send synethetic public key, message, and signature

    expect(
      AugSchemeMPL.verify(
        didInfo.syntheticPublicKey,
        message,
        signature,
      ),
      true,
    );
  });
}
