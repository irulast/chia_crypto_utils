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

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final walletCore = Core(projectId: testWalletProjectId);
  final appCore = Core(projectId: walletConnectProjectId);
  final web3Wallet = Web3Wallet(core: walletCore, metadata: defaultPairingMetadata);
  final web3App = Web3App(core: appCore, metadata: defaultPairingMetadata);

  test('Should throw exception when session proposal is rejected', () async {
    final meera = ChiaEnthusiast(fullNodeSimulator);

    final sessionProposalHandler = TestSessionProposalHandler(approveSession: false);

    final fingerprint = meera.keychainSecret.fingerprint;

    final requestHandler = FullNodeWalletConnectRequestHandler(
      coreSecret: meera.keychainSecret,
      keychain: meera.keychain,
      fullNode: fullNodeSimulator,
    );

    final walletClient = WalletConnectWalletClient(
      web3Wallet,
      fingerprint,
      sessionProposalHandler,
      requestHandler,
    );

    await walletClient.init();

    final appClient = WalletConnectAppClient(web3App, (Uri uri) async {
      await walletClient.pair(uri);
    });

    await appClient.init();

    expect(
      () async => {await appClient.pair(requiredCommandTypes: testSupportedCommandTypes)},
      throwsA(isA<RejectedSessionProposalException>()),
    );
  });
}
