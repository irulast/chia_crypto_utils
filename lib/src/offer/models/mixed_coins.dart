import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_nft.dart';
import 'package:meta/meta.dart';

@immutable
class MixedCoins {
  const MixedCoins({
    this.standardCoins = const [],
    this.cats = const [],
    this.nfts = const [],
  });

  factory MixedCoins.fromOfferedCoins(List<OfferedCoin> offeredCoins) {
    final offeredCatCoins = <CatCoin>[];
    final offeredStandardCoins = <CoinPrototype>[];
    final offeredNfts = <Nft>[];

    for (final offeredCoin in offeredCoins) {
      switch (offeredCoin.type) {
        case SpendType.standard:
          offeredStandardCoins.add(offeredCoin.coin);
          break;
        case SpendType.cat:
        case SpendType.cat1:
          offeredCatCoins.add(offeredCoin.coin as CatCoin);
          break;
        case SpendType.nft:
          offeredNfts.add((offeredCoin as OfferedNft).nft);
          break;
        case SpendType.did:
          break;
      }
    }

    return MixedCoins(
      standardCoins: offeredStandardCoins,
      cats: offeredCatCoins,
      nfts: offeredNfts,
    );
  }

  final List<CoinPrototype> standardCoins;
  final List<CatCoin> cats;
  final List<Nft> nfts;

  Map<Puzzlehash, List<CatCoin>> get catMap {
    final catCoinMap = <Puzzlehash, List<CatCoin>>{};
    for (final catCoin in cats) {
      if (catCoinMap.containsKey(catCoin.assetId)) {
        catCoinMap[catCoin.assetId]!.add(catCoin);
      } else {
        catCoinMap[catCoin.assetId] = [catCoin];
      }
    }

    return catCoinMap;
  }

  Map<Puzzlehash, Nft> get nftMap {
    return Map.fromEntries(
      nfts.map((e) => MapEntry(Puzzlehash(e.launcherId), e)),
    );
  }

  List<CoinPrototype> get allCoins =>
      <CoinPrototype>[...standardCoins, ...cats, ...nfts.map((e) => e.coin)];

  @override
  String toString() {
    return 'MixedCoins(standard: $standardCoins, cat: $catMap, nft: $nfts)';
  }
}
