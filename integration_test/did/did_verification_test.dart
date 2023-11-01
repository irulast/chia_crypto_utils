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

  final didInfos = await fullNodeSimulator.getDidRecordsByPuzzleHashes([walletVector.puzzlehash]);
  assert(didInfos.length == 1, 'should creste one did');
  final did = didInfos[0].did;

  test('should correctly verify did signature', () async {
    final message = Bytes.encodeFromString('sup');
    final signature = AugSchemeMPL.sign(
      calculateSyntheticPrivateKey(walletVector.childPrivateKey),
      message,
    );

    final didInfo = await fullNodeSimulator.getDidRecordForDid(did);
    expect(
      AugSchemeMPL.verify(
        didInfo!.toDidInfoFromParentInfoOrThrow().syntheticPublicKey,
        message,
        signature,
      ),
      true,
    );
  });
}
