import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_flutter_v2/apis/models/basic_models.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/sign_client_events.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/sign_client_models.dart';
import 'package:walletconnect_flutter_v2/apis/utils/errors.dart';

/// Handles session proposals received from apps that have been paired with wallet client.
abstract class WalletConnectSessionProposalHandler {
  /// Displays session proposal information to user and allows them to reject or approve the session,
  /// and, in the case of approval, select the fingerprints they would like to pair.
  Future<List<int>?> handleProposal({
    required SessionProposalEvent sessionProposal,
  });
}

extension ProcessProposal on WalletConnectSessionProposalHandler {
  /// Validates session proposal before handling proposal.
  Future<void> processProposal({
    required SessionProposalEvent sessionProposal,
    required Future<void> Function(WalletConnectError reason) reject,
    required Future<ApproveResponse> Function(List<String> accounts, List<String> commands) approve,
  }) async {
    final requiredNamespaces = sessionProposal.params.requiredNamespaces;

    final chiaNamespace = requiredNamespaces['chia'];

    if (chiaNamespace == null) {
      await reject(Errors.getSdkError(Errors.NON_CONFORMING_NAMESPACES));
      LoggingContext().info('rejecting due to chia namespace missing');
      return;
    }

    final commands = <String>[];
    requiredNamespaces.forEach(
      (key, value) {},
    );

    commands.addAll(
      chiaNamespace.methods.where((method) => method.startsWith('chia_')),
    );

    final fingerprints = await handleProposal(sessionProposal: sessionProposal);

    if (fingerprints != null) {
      final accounts = <String>[];

      for (final fingerprint in fingerprints) {
        accounts.add('$walletConnectChainId:$fingerprint');
      }

      await approve(accounts, commands);
    } else {
      await reject(Errors.getSdkError(Errors.USER_REJECTED));
    }
  }
}
