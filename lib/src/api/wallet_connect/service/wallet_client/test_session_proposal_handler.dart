import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/sign_client_events.dart';

class TestSessionProposalHandler implements WalletConnectSessionProposalHandler {
  TestSessionProposalHandler({this.approveSession = true})
      : supportedCommands = testSupportedCommandTypes.commandNames;

  bool approveSession;

  @override
  List<String> supportedCommands;

  @override
  Future<bool> handleProposal({required SessionProposalEvent args}) async {
    return approveSession;
  }
}

const testSupportedCommandTypes = [
  WalletConnectCommandType.getCurrentAddress,
  WalletConnectCommandType.getNextAddress,
  WalletConnectCommandType.getSyncStatus,
  WalletConnectCommandType.getWalletBalance,
  WalletConnectCommandType.getWallets,
  WalletConnectCommandType.logIn,
  WalletConnectCommandType.sendTransaction,
  WalletConnectCommandType.signMessageByAddress,
  WalletConnectCommandType.signMessageById,
  WalletConnectCommandType.spendCAT,
  WalletConnectCommandType.verifySignature,
];
