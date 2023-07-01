import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class SendTransactionCommand implements WalletConnectCommand {
  const SendTransactionCommand({
    this.walletId = 1,
    required this.address,
    required this.amount,
    this.waitForConfirmation = false,
    required this.fee,
    this.memos,
  });

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.sendTransaction;

  final int? walletId;
  final Address address;
  final int amount;
  final int fee;
  final bool waitForConfirmation;
  final List<String>? memos;

  factory SendTransactionCommand.fromParams(Map<String, dynamic> params) {
    return SendTransactionCommand(
      walletId: pick(params, 'walletId').asIntOrNull(),
      address: Address(pick(params, 'address').asStringOrThrow()),
      amount: pick(params, 'amount').asIntOrThrow(),
      fee: pick(params, 'fee').asIntOrThrow(),
      waitForConfirmation: pick(params, 'waitForConfirmation').asBoolOrFalse(),
      memos: pick(params, 'memos').letStringListOrNull((string) => string),
    );
  }

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{
      'walletId': walletId,
      'address': address.address,
      'amount': amount,
      'fee': fee,
      'waitForConfirmation': waitForConfirmation,
      'memos': memos,
    };
  }
}

// Chia Lite Wallet only responds with data field for this command
class SendTransactionResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const SendTransactionResponse(this.delegate, this.sentTransactionData);

  @override
  final WalletConnectCommandBaseResponse delegate;

  factory SendTransactionResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final sentTransactionData = pick(json, 'data').letJsonOrThrow(SentTransactionData.fromJson);
    return SendTransactionResponse(baseResponse, sentTransactionData);
  }

  final SentTransactionData sentTransactionData;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...delegate.toJson(),
      'data': sentTransactionData.toJson(),
    };
  }
}

class SentTransactionData {
  const SentTransactionData({
    required this.transaction,
    required this.transactionId,
    required this.success,
  });

  final TransactionRecord transaction;
  final Bytes transactionId;
  final bool success;

  factory SentTransactionData.fromJson(Map<String, dynamic> json) {
    return SentTransactionData(
      transaction: pick(json, 'transaction').letJsonOrThrow(TransactionRecord.fromJson),
      transactionId: (pick(json, 'transactionId').asStringOrThrow()).hexToBytes(),
      success: pick(json, 'success').asBoolOrThrow(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transaction': transaction.toJson(),
      'transactionId': transactionId.toHex(),
      'success': success,
    };
  }
}
