import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

/// User facing varaition of [MixedPayments] that uses [NftRequestedPayment] instead of [NftPayment] for nft payments
///
/// This is to elegantly force the user to provide us with required puzzle driver info when using [OfferWalletService].makeOffer
class RequestedMixedPayments {
  RequestedMixedPayments({
    this.standard = const [],
    Map<Puzzlehash, List<CatPayment>> this.cat = const {},
    List<NftRequestedPayment> nfts = const [],
  }) : nft = Map.fromEntries(
            nfts.map((e) => MapEntry(Puzzlehash(e.nftRecord.launcherId), [e])));

  final List<Payment> standard;

  /// map of asset id -> list of payments
  final Map<Puzzlehash, List<Payment>> cat;

  /// map of launcher id -> list of payments
  final Map<Puzzlehash, List<NftRequestedPayment>> nft;

  MixedPayments toMixedPayments() => MixedPayments({
        GeneralCoinType.standard: {null: standard},
        GeneralCoinType.cat: cat,
        GeneralCoinType.nft: Map.fromEntries(
          nft.entries.map(
              (e) => MapEntry(e.key, [NftPayment(e.value.single.puzzlehash)])),
        ),
      });

  @override
  String toString() {
    return 'RequestedMixedPayments(standard: $standard, cat: $cat, nft: $nft)';
  }

  MixedAmounts toMixedAmounts() => MixedAmounts(
        standard: standard.totalValue,
        cat: cat.map((key, value) => MapEntry(key, value.totalValue)),
        nft: nft.keys.toSet(),
      );
}

@immutable
class MixedPayments with MixedTypeMixin<List<Payment>, MixedPayments> {
  const MixedPayments(this.map);

  /// map of coin type -> asset id -> list of payments
  @override
  final Map<GeneralCoinType, Map<Puzzlehash?, List<Payment>>> map;

  @override
  List<Payment> get defaultValue => [];

  @override
  String toString() {
    return 'MixedPayments($map)';
  }

  @override
  MixedPayments clone(
      Map<GeneralCoinType, Map<Puzzlehash?, List<Payment>>> map) {
    return MixedPayments(map);
  }

  @override
  List<Payment> add(List<Payment> first, List<Payment> second) {
    return first + second;
  }

  @override
  List<Payment> subtract(List<Payment> first, List<Payment> second) {
    throw UnimplementedError();
  }
}

extension Notarize on MixedPayments {
  MixedNotarizedPayments toMixedNotarizedPayments(Bytes nonce) {
    return MixedNotarizedPayments({
      for (final entry in map.entries)
        entry.key: entry.value.map(
          (assetId, payments) => MapEntry(assetId,
              payments.map((p) => p.toNotarizedPayment(nonce)).toList()),
        ),
    });
  }
}
