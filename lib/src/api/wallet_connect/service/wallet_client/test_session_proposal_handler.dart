import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/sign_client_events.dart';

class TestSessionProposalHandler implements WalletConnectSessionProposalHandler {
  TestSessionProposalHandler({this.approveSession = true});

  bool approveSession;

  @override
  Future<bool> handleProposal({required SessionProposalEvent args}) async {
    return approveSession;
  }
}
