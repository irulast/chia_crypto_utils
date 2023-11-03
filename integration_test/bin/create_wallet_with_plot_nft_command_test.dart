@Timeout(Duration(minutes: 3))

import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:test_process/test_process.dart';

import 'test_process_extension.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  const poolUrl = 'https://xch.spacefarmers.io';

  test('should create plot nft', () async {
    final process = await TestProcess.start(
      'dart',
      [
        'bin/chia_crypto_utils.dart',
        'Create-WalletWithPlotNFT',
        '--full-node-url',
        SimulatorUtils.defaultUrl,
        '--pool-url',
        poolUrl,
      ],
    );

    const sendText =
        'Please send 1 mojo and enough XCH to cover the fee to create a Ploft NFT to';

    final mnemonicStdout = await process.waitForStdout('Mnemonic');
    final mnemonic = mnemonicStdout.split(':').last.trim();

    final coreSecret = KeychainCoreSecret.fromMnemonicString(mnemonic);
    final keychain = WalletKeychain.fromCoreSecret(coreSecret);

    var plotNfts =
        await fullNodeSimulator.scroungeForPlotNfts(keychain.puzzlehashes);

    expect(plotNfts, isEmpty);

    final sendStdout = await process.waitForStdout(sendText);

    final address = Address(sendStdout.split(':').last.trim());

    await fullNodeSimulator.farmCoins(address);

    await process.stdout.next;

    process.enter();

    fullNodeSimulator.run();

    await process.nextUntilExit();

    plotNfts =
        await fullNodeSimulator.scroungeForPlotNfts(keychain.puzzlehashes);

    expect(plotNfts.length, equals(1));

    fullNodeSimulator.stop();
  });
}
