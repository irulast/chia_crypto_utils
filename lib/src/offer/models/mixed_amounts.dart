import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class MixedAmounts with MixedTypeMixin<int, MixedAmounts> {
  factory MixedAmounts({
    int standard = 0,
    Map<Puzzlehash, int> cat = const {},
    Set<Puzzlehash> nft = const {},
  }) {
    return MixedAmounts.fromMap({
      GeneralCoinType.standard: {null: standard},
      GeneralCoinType.cat: cat,
      GeneralCoinType.nft: Map.fromEntries(nft.map((e) => MapEntry(e, 1))),
    });
  }

  const MixedAmounts.fromMap(this.map);
  static const empty = MixedAmounts.fromMap({
    GeneralCoinType.standard: {null: 0},
    GeneralCoinType.cat: {},
    GeneralCoinType.nft: {},
  });

  @override
  final Map<GeneralCoinType, Map<Puzzlehash?, int>> map;

  @override
  int add(int first, int second) {
    return first + second;
  }

  @override
  MixedAmounts clone(Map<GeneralCoinType, Map<Puzzlehash?, int>> map) {
    return MixedAmounts.fromMap(map);
  }

  @override
  int subtract(int first, int second) {
    return first - second;
  }

  @override
  int get defaultValue => 0;

  @override
  String toString() {
    return 'MixedAmounts(standard: $standard, cat: $cat, nftLauncherIds: $nft)';
  }

  MixedAmounts withAddedFee(int fee) {
    return MixedAmounts.fromMap({
      for (final typeEntry in map.entries)
        typeEntry.key: Map.fromEntries(
          typeEntry.value.entries.map((assetEntry) {
            if (typeEntry.key == GeneralCoinType.standard) {
              return MapEntry(assetEntry.key, assetEntry.value + fee);
            }
            return MapEntry(assetEntry.key, assetEntry.value);
          }),
        ),
    });
  }
}

@immutable

/// User facing varaition of [MixedAmounts] that that can only be constructed with standard and cat values
///
/// This is to avoid redundant arguments when a user is using [OfferWalletService].makeOffer, as nfts are already being passed in
class OfferedMixedAmounts {
  const OfferedMixedAmounts({
    this.standard = 0,
    this.cat = const {},
  });

  final int standard;
  final Map<Puzzlehash, int> cat;
  Map<Puzzlehash, int> get nft => {};

  @override
  String toString() {
    return 'OfferedMixedAmounts(standard: $standard, cat: $cat, nft: $nft)';
  }

  Map<GeneralCoinType, Map<Puzzlehash?, int>> get map => {
        GeneralCoinType.standard: {null: standard},
        GeneralCoinType.cat: cat,
      };
  MixedAmounts toMixedAmounts() => MixedAmounts.fromMap(map);
}

extension MixedAmountsBase on MixedAmounts {
  bool get isZero => toGeneralizedMap().values.every((element) => element == 0);

  MixedPayments toPayments(Puzzlehash puzzlehash) {
    return MixedPayments({
      for (final typeEntry in map.entries)
        typeEntry.key: Map.fromEntries(
          typeEntry.value.entries
              .where((element) => element.value > 0)
              .map((assetEntry) {
            return MapEntry(
              assetEntry.key,
              [
                Payment.ofType(assetEntry.value, puzzlehash,
                    type: typeEntry.key)
              ],
            );
          }),
        ),
    });
  }
}
