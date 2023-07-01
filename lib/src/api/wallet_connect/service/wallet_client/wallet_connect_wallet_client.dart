import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

/// Used to interface between user wallet and apps. Executes received requests and sends back responses with data.
class WalletConnectWalletClient {
  WalletConnectWalletClient(
    this.web3Wallet,
    this.fingerprint,
    this.sessionProposalHandler,
    this.requestHandler,
  );

  final Web3Wallet web3Wallet;
  final int fingerprint;
  final WalletConnectSessionProposalHandler sessionProposalHandler;
  final WalletConnectRequestHandler requestHandler;

  Future<void> init() async {
    await web3Wallet.init();
    await requestHandler.indexWalletMap();

    web3Wallet.onSessionProposal.subscribe((SessionProposalEvent? args) async {
      if (args == null) {
        return;
      }

      await sessionProposalHandler.processProposal(
        args: args,
        reject: (WalletConnectError reason) => rejectSession(args.id, reason),
        approve: () => approveSession(args.id),
      );
    });

    for (final type in WalletConnectCommandType.values) {
      web3Wallet.registerRequestHandler(
        chainId: walletConnectChainId,
        method: type.commandName,
        handler: (String topic, dynamic params) =>
            requestHandler.processRequest(type, topic, params),
      );
    }
  }

  Future<PairingInfo> pair(Uri uri) async {
    final pairingInfo = await web3Wallet.pair(uri: uri);

    return pairingInfo;
  }

  Future<void> disconnectPairing(String topic) async {
    await web3Wallet.core.pairing.disconnect(topic: topic);
  }

  Future<ApproveResponse> approveSession(int id) async {
    final namespaces = {
      'chia': Namespace(
        accounts: ['$walletConnectChainId:$fingerprint'],
        methods: requestHandler.supportedCommands,
        events: [],
      )
    };

    final response = await web3Wallet.approveSession(id: id, namespaces: namespaces);

    return response;
  }

  Future<void> rejectSession(int id, WalletConnectError reason) async {
    await web3Wallet.rejectSession(
      id: id,
      reason: reason,
    );
  }

  Future<void> disconnectSession(String topic) async {
    await web3Wallet.disconnectSession(
      topic: topic,
      reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
    );
  }
}
