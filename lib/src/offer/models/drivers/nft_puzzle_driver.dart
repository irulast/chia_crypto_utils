import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_nft.dart';

class NftPuzzleDriver implements PuzzleDriver {
  @override
  Puzzlehash? getAssetId(Program fullPuzzle) {
    final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(fullPuzzle);
    if (uncurriedNft == null) {
      return null;
    }
    return Puzzlehash(uncurriedNft.launcherId);
  }

  @override
  Program getNewFullPuzzleForP2Puzzle(
    Program currentFullPuzzle,
    Program innerPuzzle,
  ) {
    final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(currentFullPuzzle);

    return NftWalletService.createFullPuzzle(
      singletonId: uncurriedNft!.launcherId,
      metadata: uncurriedNft.metadata,
      metadataUpdaterPuzzlehash: uncurriedNft.metadataUpdaterHash,
      innerPuzzle: innerPuzzle,
    );
  }

  // @override
  // Program? getInnerPuzzle(Program fullPuzzle) {
  //   final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(fullPuzzle);
  //   if (uncurriedNft == null) {
  //     return null;
  //   }
  //   return uncurriedNft.innerPuzzle;
  // }

  @override
  bool doesMatch(Program fullPuzzle) {
    final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(fullPuzzle);
    return uncurriedNft != null && !uncurriedNft.doesSupportDid;
  }

  @override
  SpendType get type => SpendType.nft;

  @override
  OfferedCoin makeOfferedCoinFromParentSpend(CoinPrototype coin, CoinSpend parentSpend) {
    return OfferedNft.fromOfferBundleParentSpend(coin, parentSpend);
  }

  @override
  Program getP2Solution(CoinSpend coinSpend) {
    final stateLayerInnerSolution = coinSpend.solution.rest().rest().first().first();

    return stateLayerInnerSolution;
  }

  @override
  Program getP2Puzzle(CoinSpend coinSpend) {
    final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(coinSpend.puzzleReveal);
    return uncurriedNft!.p2Puzzle;
  }

  @override
  bool doesMatchUncurried(ModAndArguments fullPuzzle, Program _) {
    final uncurriedNft = UncurriedNftPuzzle.fromUnCurriedProgram(fullPuzzle);
    return uncurriedNft != null && !uncurriedNft.doesSupportDid;
  }

  @override
  CoinPrototype getChildCoinForP2Payment(CoinSpend coinSpend, Payment p2Payment) {
    return getSingletonChildFromCoinSpend(coinSpend);
  }
}

class DidNftPuzzleDriver implements PuzzleDriver {
  @override
  Puzzlehash? getAssetId(Program fullPuzzle) {
    final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(fullPuzzle);
    if (uncurriedNft == null) {
      return null;
    }
    return Puzzlehash(uncurriedNft.launcherId);
  }

  @override
  Program getNewFullPuzzleForP2Puzzle(
    Program currentFullPuzzle,
    Program p2Puzzle,
  ) {
    final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(currentFullPuzzle);

    return NftWalletService.createFullPuzzle(
      singletonId: uncurriedNft!.launcherId,
      metadata: uncurriedNft.metadata,
      metadataUpdaterPuzzlehash: uncurriedNft.metadataUpdaterHash,
      innerPuzzle: NftWalletService.constructOwnershipLayer(
        currentOwnerDid: uncurriedNft.ownershipLayerInfo!.currentDid,
        transferProgram: uncurriedNft.ownershipLayerInfo!.transferProgram,
        innerPuzzle: p2Puzzle,
      ),
    );
  }

  // @override
  // Program? getInnerPuzzle(Program fullPuzzle) {
  //   final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(fullPuzzle);
  //   if (uncurriedNft == null) {
  //     return null;
  //   }
  //   return uncurriedNft.innerPuzzle;
  // }

  @override
  bool doesMatch(Program fullPuzzle) {
    final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(fullPuzzle);
    return uncurriedNft != null && uncurriedNft.doesSupportDid;
  }

  @override
  SpendType get type => SpendType.nft;

  @override
  OfferedCoin makeOfferedCoinFromParentSpend(CoinPrototype coin, CoinSpend parentSpend) {
    return OfferedNft.fromOfferBundleParentSpend(coin, parentSpend);
  }

  @override
  Program getP2Solution(CoinSpend coinSpend) {
    final stateLayerInnerSolution = coinSpend.solution.rest().rest().first().first();

    return stateLayerInnerSolution.first();
  }

  @override
  Program getP2Puzzle(CoinSpend coinSpend) {
    final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(coinSpend.puzzleReveal);
    return uncurriedNft!.p2Puzzle;
  }

  @override
  bool doesMatchUncurried(ModAndArguments fullPuzzle, Program _) {
    final uncurriedNft = UncurriedNftPuzzle.fromUnCurriedProgram(fullPuzzle);
    return uncurriedNft != null && uncurriedNft.doesSupportDid;
  }

  @override
  CoinPrototype getChildCoinForP2Payment(CoinSpend coinSpend, Payment p2Payment) {
    return getSingletonChildFromCoinSpend(coinSpend);
  }
}
