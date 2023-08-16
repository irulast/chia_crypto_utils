import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/sign_client_events.dart';

class TestSessionProposalHandler implements WalletConnectSessionProposalHandler {
  TestSessionProposalHandler([this.fingerprints]);

  final List<int>? fingerprints;

  @override
  Future<List<int>?> handleProposal({required SessionProposalEvent sessionProposal}) async {
    return fingerprints;
  }
}

const testSupportedCommandTypes = [
  WalletConnectCommandType.getCurrentAddress,
  WalletConnectCommandType.getNextAddress,
  WalletConnectCommandType.getNFTInfo,
  WalletConnectCommandType.getNFTs,
  WalletConnectCommandType.getNFTsCount,
  WalletConnectCommandType.getSyncStatus,
  WalletConnectCommandType.getWalletBalance,
  WalletConnectCommandType.getWallets,
  WalletConnectCommandType.logIn,
  WalletConnectCommandType.sendTransaction,
  WalletConnectCommandType.signMessageByAddress,
  WalletConnectCommandType.signMessageById,
  WalletConnectCommandType.spendCAT,
  WalletConnectCommandType.takeOffer,
  WalletConnectCommandType.transferNFT,
  WalletConnectCommandType.verifySignature,
  WalletConnectCommandType.createOfferForIds,
  WalletConnectCommandType.checkOfferValidity,
];
