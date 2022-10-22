import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class MempoolItem {
  MempoolItem({
    required this.additions,
    required this.removals,
    required this.fee,
    required this.spendBundle,
    required this.spendBundleId,
  });

  factory MempoolItem.fromJson(Map<String, dynamic> json) {
    final additions = List<Map<String, dynamic>>.from(json['additions'] as Iterable)
        .map(CoinPrototype.fromJson)
        .toList();
    final removals = List<Map<String, dynamic>>.from(json['removals'] as Iterable)
        .map(CoinPrototype.fromJson)
        .toList();

    final fee = json['fee'] as int;
    final spendBundle = SpendBundle.fromJson(json['spend_bundle'] as Map<String, dynamic>);
    final spendBundleId = Bytes.fromHex(json['spend_bundle_name'] as String);

    return MempoolItem(
      additions: additions,
      removals: removals,
      fee: fee,
      spendBundle: spendBundle,
      spendBundleId: spendBundleId,
    );
  }
  Map<String, dynamic> toJson() => <String, dynamic>{
        'additions': additions.map((e) => e.toJson()).toList(),
        'removals': removals.map((e) => e.toJson()).toList(),
        'spend_bundle': spendBundle.toJson(),
        'fee': fee,
        'spend_bundle_name': spendBundleId.toHex(),
      };

  final List<CoinPrototype> additions;
  final List<CoinPrototype> removals;

  final int fee;

  // final NpcResult npcResult;

  final SpendBundle spendBundle;

  final Bytes spendBundleId;
}
