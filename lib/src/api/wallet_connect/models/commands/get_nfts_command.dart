import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class GetNftsCommand implements WalletConnectCommand {
  const GetNftsCommand({
    required this.walletIds,
    this.startIndex,
    this.num,
  });
  factory GetNftsCommand.fromParams(Map<String, dynamic> params) {
    return GetNftsCommand(
      walletIds: pick(params, 'walletIds')
          .asListOrThrow<int>((json) => json.asIntOrThrow()),
      startIndex: pick(params, 'startIndex').asIntOrNull(),
      num: pick(params, 'num').asIntOrNull(),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.getNFTs;

  final List<int> walletIds;
  final int? startIndex;
  final int? num;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{
      'walletIds': walletIds,
      'startIndex': startIndex,
      'num': num,
    };
  }
}

class GetNftsResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const GetNftsResponse(this.delegate, this.nfts);
  factory GetNftsResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final nfts = pick(json, 'data').asMapOrThrow<String, List<dynamic>>().map(
          (key, value) => MapEntry(
            int.parse(key),
            value
                .map(
                  (nftJson) =>
                      NftInfo.fromJson(nftJson as Map<String, dynamic>),
                )
                .toList(),
          ),
        );

    return GetNftsResponse(baseResponse, nfts);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final Map<int, List<NftInfo>> nfts;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...delegate.toJson(),
      'data': nfts.map(
        (key, value) => MapEntry(
          key.toString(),
          value.map((nftInfo) => nftInfo.toJson()).toList(),
        ),
      ),
    };
  }
}
