@Skip(
    'These tests should be run manually, as they depend on the WalletConnect relay server')
@Timeout(Duration(minutes: 5))
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';
import 'package:walletconnect_flutter_v2/apis/core/core.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:walletconnect_flutter_v2/apis/web3wallet/web3wallet.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final walletCore = Core(projectId: testWalletProjectId);
  final appCore = Core(projectId: walletConnectProjectId);
  final web3Wallet =
      Web3Wallet(core: walletCore, metadata: defaultPairingMetadata);
  final web3App = Web3App(core: appCore, metadata: defaultPairingMetadata);

  test('Should approve session with multiple fingerprints', () async {
    final coreSecret1 = KeychainCoreSecret.generate();
    final coreSecret2 = KeychainCoreSecret.generate();
    final coreSecret3 = KeychainCoreSecret.generate();

    final fingerprints = [
      coreSecret1.fingerprint,
      coreSecret2.fingerprint,
      coreSecret3.fingerprint,
    ];

    final walletClient = WalletConnectWalletClient(
      web3Wallet,
    )..registerProposalHandler(
        (sessionProposal) async => fingerprints,
      );

    await walletClient.init();

    final appClient = WalletConnectAppClient(web3App, (Uri uri) async {
      await walletClient.pair(uri);
    });

    await appClient.init();

    final sessionData = await appClient.pair();

    expect(sessionData.fingerprints.length, equals(fingerprints.length));
    expect(sessionData.fingerprints.contains(fingerprints[0]), isTrue);
    expect(sessionData.fingerprints.contains(fingerprints[1]), isTrue);
    expect(sessionData.fingerprints.contains(fingerprints[2]), isTrue);

    await walletClient.disconnectSession(sessionData.topic);
  });
}
