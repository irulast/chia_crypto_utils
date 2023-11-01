import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class DidApprovalInfo {
  DidApprovalInfo(this.messageSpendBundle, this.didInnerHash);

  final SpendBundle messageSpendBundle;
  final Puzzlehash didInnerHash;
}
