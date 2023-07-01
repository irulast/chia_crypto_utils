import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class TransferNftCommand implements WalletConnectCommand {
  const TransferNftCommand({
    required this.walletId,
    required this.targetAddress,
    required this.nftCoinIds,
    required this.fee,
  });

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.transferNFT;

  final int walletId;
  final Address targetAddress;
  final List<Bytes> nftCoinIds;
  final int fee;

  factory TransferNftCommand.fromParams(Map<String, dynamic> params) {
    return TransferNftCommand(
      walletId: pick(params, 'walletId').asIntOrThrow(),
      targetAddress: Address(pick(params, 'targetAddress').asStringOrThrow()),
      nftCoinIds: pick(params, 'nftCoinIds').letStringListOrThrow((string) => string.hexToBytes()),
      fee: pick(params, 'fee').asIntOrThrow(),
    );
  }

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{
      'walletId': walletId,
      'targetAddress': targetAddress.address,
      'nftCoinIds': nftCoinIds.map((coinId) => coinId.toHex()).toList(),
      'fee': fee,
    };
  }
}

class TransferNftResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const TransferNftResponse(this.delegate, this.transferNftData);

  @override
  final WalletConnectCommandBaseResponse delegate;
  final TransferNftData transferNftData;

  factory TransferNftResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final transferNftData = pick(json, 'data').letJsonOrThrow(TransferNftData.fromJson);
    return TransferNftResponse(baseResponse, transferNftData);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': transferNftData.toJson(),
    };
  }
}

class TransferNftData {
  const TransferNftData({
    required this.spendBundle,
    required this.walletId,
    this.transactionNumber,
  });

  final SpendBundle spendBundle;

  final List<int> walletId;
  final int? transactionNumber;

  factory TransferNftData.fromJson(Map<String, dynamic> json) {
    // Chia lite wallet may return either int or List<int> so here we always convert it to List<int>
    final walletIdPick = pick(json, 'walletId');

    late final List<int> walletId;
    try {
      walletId = walletIdPick.asListOrThrow((p0) => p0.asIntOrThrow());
    } catch (e) {
      walletId = [walletIdPick.asIntOrThrow()];
    }

    return TransferNftData(
      spendBundle: pick(json, 'spendBundle').letJsonOrThrow(SpendBundle.fromCamelJson),
      walletId: walletId,
      transactionNumber: pick(json, 'txNum').asIntOrNull(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'spendBundle': spendBundle.toCamelJson(),
      'walletId': walletId,
      'txNum': transactionNumber,
    };
  }
}
