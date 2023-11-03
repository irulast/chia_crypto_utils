import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_dart_v2_i/walletconnect_dart_v2_i.dart';
// ignore_for_file: use_setters_to_change_properties

typedef WalletConnectSessionProposalHandler = Future<List<int>?> Function(
  SessionProposalEvent sessionProposal,
);

typedef WalletConnectSessionApprovalHandler = Future<void> Function(
  ApproveResponse approveResponse,
);

/// Used to interface between user wallet and apps. Executes received requests and sends back responses with data.
class WalletConnectWalletClient {
  WalletConnectWalletClient(
    this.web3Wallet,
  );

  final Web3Wallet web3Wallet;

  /// Displays session proposal to the user, allowing them to approve or reject. Returns fingerprints
  /// if approved and null if rejected.
  WalletConnectSessionProposalHandler? handleProposal;

  /// Includes any logic for handling the response returned after a session is approved.
  WalletConnectSessionApprovalHandler? handleSessionApproval;
  WalletConnectRequestHandler? requestHandler;

  Future<void> init() async {
    await web3Wallet.init();

    web3Wallet.onSessionProposal
        .subscribe((SessionProposalEvent? sessionProposal) async {
      if (sessionProposal == null) {
        return;
      }

      await processProposal(sessionProposal);
    });
  }

  Future<PairingInfo> pair(Uri uri) async {
    final pairingInfo = await web3Wallet.pair(uri: uri);

    return pairingInfo;
  }

  Future<void> disconnectPairing(String topic) async {
    await web3Wallet.core.pairing.disconnect(topic: topic);
  }

  Future<void> processProposal(
    SessionProposalEvent sessionProposal,
  ) async {
    final requiredNamespaces = sessionProposal.params.requiredNamespaces;

    final chiaNamespace = requiredNamespaces['chia'];

    if (chiaNamespace == null) {
      await rejectSession(
        sessionProposal.id,
        Errors.getSdkError(Errors.NON_CONFORMING_NAMESPACES),
      );
      LoggingContext().info('rejecting due to chia namespace missing');
      return;
    }

    final commands = chiaNamespace.methods
        .where((method) => method.startsWith('chia_'))
        .toList();

    if (handleProposal == null) {
      throw UnregisteredSessionProposalHandler();
    }

    final fingerprints = await handleProposal!(sessionProposal);

    if (fingerprints != null) {
      final approveResponse =
          await approveSession(sessionProposal.id, fingerprints, commands);

      await handleSessionApproval?.call(approveResponse);
    } else {
      await rejectSession(
        sessionProposal.id,
        Errors.getSdkError(Errors.USER_REJECTED),
      );
    }
  }

  Future<ApproveResponse> approveSession(
    int id,
    List<int> fingerprints,
    List<String> commands,
  ) async {
    final accounts = <String>[];

    for (final fingerprint in fingerprints) {
      accounts.add('$walletConnectChainId:$fingerprint');
    }

    final namespaces = {
      'chia': Namespace(
        accounts: accounts,
        methods: commands,
        events: [],
      ),
    };

    final response =
        await web3Wallet.approveSession(id: id, namespaces: namespaces);

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

  void registerProposalHandler(
    WalletConnectSessionProposalHandler proposalHandler,
  ) {
    handleProposal = proposalHandler;
  }

  void registerSessionApprovalHandler(
    WalletConnectSessionApprovalHandler approvalHandler,
  ) {
    handleSessionApproval = approvalHandler;
  }
}

class UnregisteredSessionProposalHandler implements Exception {
  @override
  String toString() => 'Session proposal handler has not been registered';
}
