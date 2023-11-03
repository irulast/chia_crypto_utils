@Skip(
  'These tests should be run manually, as they depend on the WalletConnect relay server',
)
@Timeout(Duration(minutes: 5))
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';
import 'package:walletconnect_dart_v2_i/apis/core/core.dart';
import 'package:walletconnect_dart_v2_i/apis/web3app/web3app.dart';
import 'package:walletconnect_dart_v2_i/apis/web3wallet/web3wallet.dart';

Future<void> main() async {
  final walletCore = Core(projectId: testWalletProjectId);
  final appCore = Core(projectId: walletConnectProjectId);
  final web3Wallet =
      Web3Wallet(core: walletCore, metadata: defaultPairingMetadata);
  final web3App = Web3App(core: appCore, metadata: defaultPairingMetadata);

  test('Should throw exception when session proposal is rejected', () async {
    final walletClient = WalletConnectWalletClient(web3Wallet)
      ..registerProposalHandler((sessionProposal) async => null);

    await walletClient.init();

    final appClient = WalletConnectAppClient(web3App, (Uri uri) async {
      await walletClient.pair(uri);
    });

    await appClient.init();

    expect(
      () async => {await appClient.pair()},
      throwsA(isA<RejectedSessionProposalException>()),
    );
  });
}
