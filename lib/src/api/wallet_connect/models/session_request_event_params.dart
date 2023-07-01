import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/json_rpc_models.dart';

class WalletConnectSessionRequestEventParams {
  const WalletConnectSessionRequestEventParams(this.request, this.chainId);

  final SessionRequestParams request;
  final String chainId;

  factory WalletConnectSessionRequestEventParams.fromJson(Map<String, dynamic> json) {
    return WalletConnectSessionRequestEventParams(
      SessionRequestParams.fromJson(pick(json, 'request').letJsonOrThrow((json) => json)),
      pick(json, 'chainId').asStringOrThrow(),
    );
  }
}
