@Skip('These tests should be run manually, as they depend on the WalletConnect relay server')
@Timeout(Duration(minutes: 5))
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';
import 'package:walletconnect_flutter_v2/apis/core/core.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:walletconnect_flutter_v2/apis/web3wallet/web3wallet.dart';

Future<void> main() async {
  final walletCore = Core(projectId: testWalletProjectId);
  final appCore = Core(projectId: walletConnectProjectId);
  final web3Wallet = Web3Wallet(core: walletCore, metadata: defaultPairingMetadata);
  final web3App = Web3App(core: appCore, metadata: defaultPairingMetadata);
  final coreSecret = KeychainCoreSecret.generate();

  late final WalletConnectWalletClient walletClient;
  late final WalletConnectAppClient appClient;
  setUp(() async {
    walletClient = WalletConnectWalletClient(web3Wallet)
      ..registerProposalHandler((sessionProposal) async => [coreSecret.fingerprint]);

    await walletClient.init();

    appClient = WalletConnectAppClient(web3App, (Uri uri) async {
      await walletClient.pair(uri);
    });

    await appClient.init();
  });

  test('app should connect and disconnect', () async {
    final sessionData = await appClient.pair();

    expect(appClient.isConnected, isTrue);

    await appClient.disconnectPairing(sessionData.pairingTopic);

    await Future<void>.delayed(const Duration(seconds: 1));

    expect(appClient.isConnected, isFalse);
  });

  test('app should correctly reflect disconnection after wallet disconnects', () async {
    final sessionData = await appClient.pair();

    expect(appClient.isConnected, isTrue);

    await walletClient.disconnectSession(sessionData.topic);

    await Future<void>.delayed(const Duration(seconds: 5));

    expect(appClient.isConnected, isFalse);
  });
}
