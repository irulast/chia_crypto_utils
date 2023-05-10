// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:compute/compute.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
abstract class CatCoin implements CoinPrototype {
  factory CatCoin({
    required CoinSpend parentCoinSpend,
    required Puzzlehash assetId,
    required Program lineageProof,
    required Program catProgram,
    required CoinPrototype delegate,
  }) {
    return _CatCoin(
      parentCoinSpend: parentCoinSpend,
      catProgram: catProgram,
      lineageProof: lineageProof,
      assetId: assetId,
      delegate: delegate,
    );
  }
  factory CatCoin.eve({
    required CoinSpend parentCoinSpend,
    required Puzzlehash assetId,
    required Program catProgram,
    required CoinPrototype coin,
  }) =>
      CatCoin(
        parentCoinSpend: parentCoinSpend,
        assetId: assetId,
        lineageProof: Program.nil,
        catProgram: catProgram,
        delegate: coin,
      );

  factory CatCoin.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    final parentSpend = CoinSpend.fromStream(iterator);
    final coin = CoinPrototype.fromStream(iterator);
    return CatCoin.fromParentSpend(
      parentCoinSpend: parentSpend,
      coin: coin,
    );
  }

  factory CatCoin.fromParentSpend({
    required CoinSpend parentCoinSpend,
    required CoinPrototype coin,
  }) {
    final uncurriedCatProgram = parentCoinSpend.puzzleReveal.uncurry();
    return _CatCoin._fromUncurriedPuzzle(
      parentCoinSpend: parentCoinSpend,
      uncurriedCatProgram: uncurriedCatProgram,
      coin: coin,
    );
  }

  factory CatCoin.fromJson(Map<String, dynamic> json) {
    final coin = pick(json, 'coin').letJsonOrThrow(CoinPrototype.fromJson);
    final parentSpend = pick(json, 'parent_spend').letJsonOrThrow(CoinSpend.fromJson);

    return CatCoin.fromParentSpend(
      parentCoinSpend: parentSpend,
      coin: coin,
    );
  }

  static Future<CatCoin> fromParentSpendAsync({
    required CoinSpend parentCoinSpend,
    required CoinPrototype coin,
  }) async {
    final uncurriedCatProgram = await parentCoinSpend.puzzleReveal.uncurryAsync();
    return _CatCoin._fromUncurriedPuzzle(
      parentCoinSpend: parentCoinSpend,
      uncurriedCatProgram: uncurriedCatProgram,
      coin: coin,
    );
  }

  CoinSpend get parentCoinSpend;
  CoinPrototype get delegate;
  Puzzlehash get assetId;
  Program get lineageProof;
  Program get catProgram;
}

class _CatCoin with CoinPrototypeDecoratorMixin implements CatCoin {
  const _CatCoin({
    required this.parentCoinSpend,
    required this.catProgram,
    required this.lineageProof,
    required this.assetId,
    required this.delegate,
  });
  factory _CatCoin._fromUncurriedPuzzle({
    required CoinSpend parentCoinSpend,
    required ModAndArguments uncurriedCatProgram,
    required CoinPrototype coin,
  }) {
    final uncurriedArguments = uncurriedCatProgram.arguments;
    final unCurriedCatMod = uncurriedCatProgram.mod;
    if (unCurriedCatMod != cat1Program && unCurriedCatMod != cat2Program) {
      throw InvalidCatException();
    }

    final assetId = Puzzlehash(uncurriedArguments[1].atom);
    final lineageProof = Program.list([
      Program.fromBytes(
        parentCoinSpend.coin.parentCoinInfo,
      ),
      // third argument to the cat puzzle is the inner puzzle
      Program.fromBytes(
        uncurriedArguments[2].hash(),
      ),
      Program.fromInt(parentCoinSpend.coin.amount)
    ]);
    return _CatCoin(
      parentCoinSpend: parentCoinSpend,
      catProgram: unCurriedCatMod,
      lineageProof: lineageProof,
      assetId: assetId,
      delegate: coin,
    );
  }
  @override
  final CoinSpend parentCoinSpend;
  @override
  final Puzzlehash assetId;
  @override
  final Program lineageProof;
  @override
  final Program catProgram;
  @override
  final CoinPrototype delegate;

  @override
  String toString() =>
      'CatCoin(id: $id, parentCoinInfo: $parentCoinInfo, puzzlehash: $puzzlehash, amount: $amount, assetId: $assetId)';
}

extension CatFunctionality on CatCoin {
  SpendType get type {
    if (catProgram == cat2Program) {
      return SpendType.cat;
    }
    if (catProgram == cat1Program) {
      return SpendType.cat1;
    }
    throw InvalidCatException();
  }

  Bytes toCatBytes() {
    return parentCoinSpend.toBytes() + toCoinPrototype().toBytes();
  }

  Map<String, dynamic> toCatJson() => {
        'coin': delegate.toJson(),
        'parent_spend': parentCoinSpend.toJson(),
      };

  CoinPrototype toCoinPrototype() => CoinPrototype(
        parentCoinInfo: parentCoinInfo,
        puzzlehash: puzzlehash,
        amount: amount,
      );

  /// current p2Puzzlehash of [CatCoin] calculated by looking through [CreateCoinCondition]s of parent solution
  ///
  /// client can optionally pass in their standard puzzlehashes to make parsing more efficient in case of airdrop
  Future<Puzzlehash> getP2Puzzlehash({Set<Puzzlehash> puzzlehashesToFilterBy = const {}}) async {
    final result = await compute(
      _calculateCatP2PuzzleHashTask,
      _CalculateCatP2PuzzleHashArgument(this, puzzlehashesToFilterBy),
    );
    if (result == null) {
      throw InvalidCatException(
        message: 'No matching parent create coin conditions for cat coin $id',
      );
    }
    return Puzzlehash.fromHex(result);
  }

  /// see [getP2Puzzlehash] for documentation
  Puzzlehash getP2PuzzlehashSync({Set<Puzzlehash> puzzlehashesToFilterBy = const {}}) {
    final result = _calculateCatP2PuzzleHashTask(
      _CalculateCatP2PuzzleHashArgument(this, puzzlehashesToFilterBy),
    );
    if (result == null) {
      throw InvalidCatException(
        message: 'No matching parent create coin conditions for cat coin $id',
      );
    }
    return Puzzlehash.fromHex(result);
  }
}

String? _calculateCatP2PuzzleHashTask(_CalculateCatP2PuzzleHashArgument args) {
  final catCoin = args.coin;
  final puzzleHashesToCheck = args.puzzlehashesToFilterBy;
  final innerSolution = catCoin.parentCoinSpend.solution.toList()[0];
  final innerPuzzle = catCoin.parentCoinSpend.puzzleReveal.uncurry().arguments[2];

  final createCoinConditions = BaseWalletService.extractConditionsFromProgramList(
    innerPuzzle.run(innerSolution).program.toList(),
    CreateCoinCondition.isThisCondition,
    CreateCoinCondition.fromProgram,
  );

  // first, look for single matching amount
  final matchingAmountConditions =
      createCoinConditions.where((element) => element.amount == catCoin.amount);

  if (matchingAmountConditions.length == 1) {
    return matchingAmountConditions.single.destinationPuzzlehash.toHex();
  }

  final shouldCheckPuzzleHashes = puzzleHashesToCheck.isNotEmpty;

  for (final createCoinCondition in matchingAmountConditions) {
    final potentialP2PuzzleHash = createCoinCondition.destinationPuzzlehash;
    // optionally filter by client provided puzzle hashes
    if (shouldCheckPuzzleHashes && !puzzleHashesToCheck.contains(potentialP2PuzzleHash)) {
      continue;
    }
    final outerPuzzleHash = WalletKeychain.makeOuterPuzzleHashForCatProgram(
      potentialP2PuzzleHash,
      catCoin.assetId,
      catCoin.catProgram,
    );

    if (outerPuzzleHash == catCoin.puzzlehash) {
      return potentialP2PuzzleHash.toHex();
    }
  }
  return null;
}

class _CalculateCatP2PuzzleHashArgument {
  _CalculateCatP2PuzzleHashArgument(this.coin, this.puzzlehashesToFilterBy);
  final CatCoin coin;
  final Set<Puzzlehash> puzzlehashesToFilterBy;
}

extension GroupByAssetId on Iterable<CatCoin> {
  Map<Puzzlehash, List<CatCoin>> groupByAssetId() {
    final catMap = <Puzzlehash, List<CatCoin>>{};

    for (final catCoin in this) {
      catMap.update(
        catCoin.assetId,
        (value) => [...value, catCoin],
        ifAbsent: () => [catCoin],
      );
    }
    return catMap;
  }
}
