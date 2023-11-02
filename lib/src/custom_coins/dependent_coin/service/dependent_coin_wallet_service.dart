import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class DependentCoinWalletService {
  final standardWalletService = StandardWalletService();

  static Program makeSolutionFromConditions(List<Condition> conditions) {
    return Program.list([Program.list(conditions)]);
  }

  static Program makeFullPuzzle({
    required Bytes primaryCoinId,
    required Bytes primaryCoinMessage,
  }) {
    return curriedConditionProgram.curry([
      AssertCoinAnnouncementCondition(primaryCoinId, primaryCoinMessage),
    ]);
  }

  DependentCoinsWithCreationBundle createGenerateDependentCoinsSpendBundle({
    required int amountPerCoin,
    required List<PrimaryCoinInfo> primaryCoinInfos,
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
    int fee = 0,
    Puzzlehash? changePuzzleHash,
  }) {
    final originCoin = coins.first;
    final dependentCoins = <DependentCoin>[];
    for (final primaryCoinInfo in primaryCoinInfos) {
      final puzzle = makeFullPuzzle(
        primaryCoinId: primaryCoinInfo.id,
        primaryCoinMessage: primaryCoinInfo.message,
      );
      final puzzleHash = puzzle.hash();

      final dependentCoin = DependentCoin(
        delegate: CoinPrototype(
          parentCoinInfo: originCoin.id,
          puzzlehash: puzzleHash,
          amount: amountPerCoin,
        ),
        primaryCoinId: primaryCoinInfo.id,
        primaryCoinMessage: primaryCoinInfo.message,
      );
      dependentCoins.add(dependentCoin);
    }
    final creationSpendBundle = standardWalletService.createSpendBundle(
      payments: dependentCoins
          .map(
            (e) => Payment(
              amountPerCoin,
              e.puzzlehash,
              memos: <Bytes>[e.primaryCoinId],
            ),
          )
          .toList(),
      coinsInput: coins,
      keychain: keychain,
      changePuzzlehash: changePuzzleHash,
      originId: originCoin.id,
      fee: fee,
    );

    return DependentCoinsWithCreationBundle(
      creationSpendBundle,
      dependentCoins,
    );
  }

  SpendBundle createFeeCoinSpendBundle({
    required DependentCoin dependentCoin,
  }) {
    return SpendBundle(
      coinSpends: [
        CoinSpend(
          coin: dependentCoin,
          puzzleReveal: dependentCoin.fullPuzzle,
          solution: makeSolutionFromConditions(
            [ReserveFeeCondition(dependentCoin.amount)],
          ),
        ),
      ],
    );
  }

  SpendBundle createCoinSpendBundle({
    required DependentCoin dependentCoin,
    required Puzzlehash destinationPuzzlehash,
    int fee = 0,
  }) {
    return SpendBundle(
      coinSpends: [
        CoinSpend(
          coin: dependentCoin,
          puzzleReveal: dependentCoin.fullPuzzle,
          solution: makeSolutionFromConditions([
            ReserveFeeCondition(fee),
            CreateCoinCondition(
              destinationPuzzlehash,
              dependentCoin.amount - fee,
            ),
          ]),
        ),
      ],
    );
  }
}

class PrimaryCoinInfo {
  PrimaryCoinInfo({
    required this.id,
    required this.message,
  });

  factory PrimaryCoinInfo.fromNft(NftRecord nft) {
    return PrimaryCoinInfo(
      id: nft.coin.id,
      message: nft.launcherId,
    );
  }

  final Bytes id;
  final Bytes message;
}

class DependentCoinsWithCreationBundle {
  DependentCoinsWithCreationBundle(this.creationBundle, this.dependentCoins);
  factory DependentCoinsWithCreationBundle.fromJson(Map<String, dynamic> json) {
    final dependentCoins = pick(json, 'dependent_coins')
        .letJsonListOrThrow(DependentCoin.fromJson);
    final creationBundle =
        pick(json, 'creation_bundle').letJsonOrThrow(SpendBundle.fromJson);

    return DependentCoinsWithCreationBundle(creationBundle, dependentCoins);
  }
  final SpendBundle creationBundle;
  final List<DependentCoin> dependentCoins;

  Map<Bytes, DependentCoin> get primaryIdToDependantCoinMap {
    return Map.fromEntries(
      dependentCoins.map((e) => MapEntry(e.primaryCoinId, e)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dependent_coins':
          dependentCoins.map((e) => e.dependentCoinToJson()).toList(),
      'creation_bundle': creationBundle.toJson(),
    };
  }
}
