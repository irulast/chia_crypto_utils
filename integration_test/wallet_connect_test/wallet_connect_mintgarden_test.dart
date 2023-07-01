@Skip('This is an interactive test using MintGarden')
@Timeout(Duration(minutes: 5))
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/wallet_connect/service/wallet_client/full_node_request_handler.dart';
import 'package:chia_crypto_utils/src/api/wallet_connect/service/wallet_client/test_session_proposal_handler.dart';
import 'package:test/test.dart';
import 'package:walletconnect_flutter_v2/apis/core/core.dart';
import 'package:walletconnect_flutter_v2/apis/web3wallet/web3wallet.dart';

// To run this test:
// 1. Manually set the mainnetUrl and mnemonic variables below. Use a mnemonic with a DID on it.
// 2. Login to MintGarden, navigate to My Profiles > Claim another profile > WalletConnect > Connect Wallet
// 3. Copy URI, and set it to the mintGardenLink variable below. This link must be updated for every run.
// 4. Run test (individual test, not as suite).
// 5. After connection is established, click 'Fetch profiles' in MintGarden.
// 7. If it shows a DID, test is successful.
// 8. Click 'Disconnect' in MintGarden.

// Note: signing with MintGarden not working yet

Future<void> main() async {
  // Set these variables before running the test
  const mainnetUrl = '';
  const mnemonic = '';
  const mintGardenLink = '';

  const fullNodeHttpRpc = FullNodeHttpRpc(mainnetUrl, timeout: Duration(minutes: 10));

  const fullNodeInterface = ChiaFullNodeInterface(fullNodeHttpRpc);

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final core = Core(projectId: walletConnectProjectId);
  final web3Wallet = Web3Wallet(core: core, metadata: defaultPairingMetadata);
  final coreSecret = KeychainCoreSecret.fromMnemonicString(mnemonic);

  final keychain = WalletKeychain.fromCoreSecret(coreSecret);

  final sessionProposalHandler = TestSessionProposalHandler();

  final requestHandler = FullNodeWalletConnectRequestHandler(
    coreSecret: coreSecret,
    keychain: keychain,
    fullNode: fullNodeInterface,
  );

  final walletClient = WalletConnectWalletClient(
    web3Wallet,
    coreSecret.fingerprint,
    sessionProposalHandler,
    requestHandler,
  );

  test('Should approve session and send wallet data to MintGarden', () async {
    await walletClient.init();

    await walletClient.pair(Uri.parse(mintGardenLink));

    // Wait for test to complete
    await Future<void>.delayed(const Duration(minutes: 2));
  });
}