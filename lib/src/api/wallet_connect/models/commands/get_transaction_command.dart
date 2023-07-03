import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:tuple/tuple.dart';

class GetTransactionCommand implements WalletConnectCommand {
  const GetTransactionCommand({
    required this.transactionId,
  });

  factory GetTransactionCommand.fromParams(Map<String, dynamic> params) {
    return GetTransactionCommand(
      transactionId: pick(params, 'transactionId').letStringOrThrow(Bytes.fromHex),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.getTransaction;

  final Bytes transactionId;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'transactionId': transactionId.toHex()};
  }
}

class GetTransactionResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const GetTransactionResponse(
    this.delegate,
    this.transactionRecord,
  );

  factory GetTransactionResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final transactionRecord = pick(json, 'data').letJsonOrThrow(TransactionRecord.fromJson);
    return GetTransactionResponse(baseResponse, transactionRecord);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;

  final TransactionRecord transactionRecord;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...delegate.toJson(),
      'data': transactionRecord.toJson(),
    };
  }
}

class TransactionRecord {
  const TransactionRecord({
    required this.additions,
    required this.amount,
    required this.confirmed,
    required this.confirmedAtHeight,
    required this.createdAtTime,
    required this.feeAmount,
    required this.memos,
    required this.name,
    required this.removals,
    required this.sent,
    this.sentTo = const [],
    this.spendBundle,
    required this.toAddress,
    required this.toPuzzlehash,
    this.tradeId,
    required this.type,
    required this.walletId,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    // Chia Lite Wallet might return memos as Map<String, List<String>> or Map<String, String>
    // here we always convert it to Map<Bytes, List<Bytes>>

    final memoMap = pick(json, 'memos').asMapOrThrow<String, dynamic>();

    late final Map<Bytes, List<Memo>> memos;
    if (memoMap.isNotEmpty) {
      try {
        memos = memoMap.map(
          (key, value) => MapEntry(
            key.hexToBytes(),
            (value as List<dynamic>).map((memo) => Memo(memo.toString().hexToBytes())).toList(),
          ),
        );
      } catch (e) {
        memos = memoMap.map(
          (key, value) => MapEntry(
            key.hexToBytes(),
            [Memo((value as String).hexToBytes())],
          ),
        );
      }
    } else {
      memos = {};
    }

    return TransactionRecord(
      additions: pick(json, 'additions').letJsonListOrThrow(CoinPrototype.fromCamelJson),
      amount: pick(json, 'amount').asIntOrThrow(),
      confirmed: pick(json, 'confirmed').asBoolOrThrow(),
      confirmedAtHeight: pick(json, 'confirmedAtHeight').asIntOrThrow(),
      createdAtTime: pick(json, 'createdAtTime').asIntOrThrow(),
      feeAmount: pick(json, 'feeAmount').asIntOrThrow(),
      memos: memos,
      name: (pick(json, 'name').asStringOrThrow()).hexToBytes(),
      removals: pick(json, 'removals').letJsonListOrThrow(CoinPrototype.fromCamelJson),
      sent: pick(json, 'sent').asIntOrThrow(),
      sentTo: pick(json, 'sentTo').asListOrEmpty((p0) => p0.asString()),
      toAddress: Address(pick(json, 'toAddress').asStringOrThrow()),
      toPuzzlehash: Puzzlehash.fromHex(pick(json, 'toPuzzleHash').asStringOrThrow()),
      type: ChiaTransactionType.values[pick(json, 'type').asIntOrThrow()],
      walletId: pick(json, 'walletId').asIntOrThrow(),
      spendBundle: pick(json, 'spendBundle').letJsonOrNull(SpendBundle.fromCamelJson),
      tradeId: (pick(json, 'tradeId').asStringOrNull())?.hexToBytes(),
    );
  }

  final List<CoinPrototype> additions;
  final int amount;
  final bool confirmed;
  final int confirmedAtHeight;
  final int createdAtTime;
  final int feeAmount;
  final Map<Bytes, List<Memo>> memos;
  final Bytes name;
  final List<CoinPrototype> removals;
  final int sent;
  final List<String> sentTo;
  final SpendBundle? spendBundle;
  final Address toAddress;
  final Puzzlehash toPuzzlehash;
  final Bytes? tradeId;
  final ChiaTransactionType type;
  final int walletId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'additions': additions.map((coin) => coin.toCamelJson()).toList(),
      'amount': amount,
      'confirmed': confirmed,
      'confirmedAtHeight': confirmedAtHeight,
      'createdAtTime': createdAtTime,
      'feeAmount': feeAmount,
      'memos': memos
          .map((key, value) => MapEntry(key.toHex(), value.map((memo) => memo.toHex()).toList())),
      'name': name.toHex(),
      'removals': removals.map((coin) => coin.toCamelJson()).toList(),
      'sent': sent,
      'sentTo': sentTo,
      'toAddress': toAddress.address,
      'toPuzzleHash': toPuzzlehash.toHex(),
      'type': type.index,
      'walletId': walletId,
      'spendBundle': spendBundle?.toCamelJson(),
      'tradeId': tradeId?.toHex(),
    };
  }
}

enum ChiaTransactionType {
  incoming,
  outgoing,
  coinbaseReward,
  feeReward,
  incomingTrade,
  outgoingTrade;
}

class Peer {
  const Peer(this.peerId, this.inclusionStatus, this.errorMessage);

  final String peerId;
  final InclusionStatus inclusionStatus;
  final String? errorMessage;

  Tuple3<String, InclusionStatus, String?> toTuple() {
    return Tuple3(peerId, inclusionStatus, errorMessage);
  }

  Peer? maybeFromList(List<String> list) {
    try {
      return Peer(list[0], InclusionStatus.fromIndex(int.parse(list[1])), list[3]);
    } catch (e) {
      return null;
    }
  }
}

enum InclusionStatus {
  success(1),
  pending(2),
  failed(3);

  const InclusionStatus(this.value);

  factory InclusionStatus.fromIndex(int index) =>
      InclusionStatus.values.where((value) => value.value == index).single;

  final int value;
}
