import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
class ParsedMixedAmounts {
  const ParsedMixedAmounts({
    this.standard = 0,
    this.cats = const [],
    this.nfts = const [],
  });

  factory ParsedMixedAmounts.fromJson(Map<String, dynamic> json) {
    return ParsedMixedAmounts(
      standard: pick(json, 'xch').asIntOrThrow(),
      cats: pick(json, 'cats').letJsonListOrThrow(ParsedCatInfo.fromJson),
      nfts: pick(json, 'nfts').letJsonListOrThrow(ParsedNftInfo.fromJson),
    );
  }

  final int standard;
  final List<ParsedCatInfo> cats;
  final List<ParsedNftInfo> nfts;

  double get xch => standard / mojosPerXch;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'xch': standard,
      'cats': cats.map((e) => e.toJson()).toList(),
      'nfts': nfts.map((e) => e.toJson()).toList(),
    };
  }
}
