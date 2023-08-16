import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

/// Used to interface between user wallet and apps. Executes received requests and sends back responses with data.
class WalletConnectWalletClient {
  WalletConnectWalletClient(
    this.web3Wallet,
    this.sessionProposalHandler,
  );

  final Web3Wallet web3Wallet;
  final WalletConnectSessionProposalHandler sessionProposalHandler;
  WalletConnectRequestHandler? requestHandler;

  Future<void> init() async {
    await web3Wallet.init();

    web3Wallet.onSessionProposal.subscribe((SessionProposalEvent? sessionProposal) async {
      if (sessionProposal == null) {
        return;
      }

      await sessionProposalHandler.processProposal(
        sessionProposal: sessionProposal,
        reject: (WalletConnectError reason) => rejectSession(sessionProposal.id, reason),
        approve: (List<String> accounts, List<String> commands) =>
            approveSession(sessionProposal.id, accounts, commands),
      );
    });
  }

  Future<PairingInfo> pair(Uri uri) async {
    final pairingInfo = await web3Wallet.pair(uri: uri);

    return pairingInfo;
  }

  Future<void> disconnectPairing(String topic) async {
    await web3Wallet.core.pairing.disconnect(topic: topic);
  }

  Future<ApproveResponse> approveSession(
    int id,
    List<String> accounts,
    List<String> commands,
  ) async {
    final namespaces = {
      'chia': Namespace(
        accounts: accounts,
        methods: commands,
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

  void registerRequestHandler(WalletConnectRequestHandler requestHandler) {
    for (final type in WalletConnectCommandType.values) {
      web3Wallet.registerRequestHandler(
        chainId: walletConnectChainId,
        method: type.commandName,
        handler: (String topic, dynamic params) {
          // we know that the session data will not be null because there must be a session with the
          // session topic on the request in order to receive the request
          final sessionData = web3Wallet.sessions.get(topic)!;

          return requestHandler.handleRequest(
            sessionData: sessionData,
            type: type,
            params: params,
          );
        },
      );
    }

    this.requestHandler = requestHandler;
  }
}
