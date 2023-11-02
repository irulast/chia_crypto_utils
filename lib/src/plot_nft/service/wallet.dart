import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/plot_nft/models/exceptions/invalid_pool_singleton_exception.dart';
import 'package:chia_crypto_utils/src/singleton/puzzles/singleton_output_inner_puzzle/singleton_output_inner_puzzle.clvm.hex.dart';

class PlotNftWalletService extends BaseWalletService {
  final standardWalletService = StandardWalletService();

  static const int defaultLauncherCoinAmount = 1;
  static const int defaultDelayTime = 604800;

  SpendBundle createPoolNftSpendBundle({
    required Bytes genesisCoinId,
    required List<CoinPrototype> coins,
    int fee = 0,
    required PoolState initialTargetState,
    int p2SingletonDelayTime = defaultDelayTime,
    required Puzzlehash p2SingletonDelayedPuzzlehash,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
  }) {
    final launcherParent =
        coins.singleWhere((coin) => coin.id == genesisCoinId);
    final genesisLauncherPuzzle = singletonLauncherProgram;
    final launcherCoin = makeLauncherCoin(launcherParent.id);

    final innerPuzzle = poolStateToInnerPuzzle(
      poolState: initialTargetState,
      launcherId: launcherCoin.id,
      delayPuzzlehash: p2SingletonDelayedPuzzlehash,
      delayTime: p2SingletonDelayTime,
      isInitialState: true,
    );

    final fullPoolingPuzzle =
        SingletonService.puzzleForSingleton(launcherCoin.id, innerPuzzle);
    final puzzlehash = fullPoolingPuzzle.hash();

    final plotNftExtraData = PlotNftExtraData(
      initialTargetState,
      p2SingletonDelayTime,
      p2SingletonDelayedPuzzlehash,
    );

    final announcementMessage = Program.list(
      [
        Program.fromAtom(puzzlehash),
        Program.fromInt(launcherCoin.amount),
        plotNftExtraData.toProgram(),
      ],
    ).hash();
    final assertCoinAnnouncement =
        AssertCoinAnnouncementCondition(launcherCoin.id, announcementMessage);

    final createLauncherSpendBundle = standardWalletService.createSpendBundle(
      payments: [Payment(launcherCoin.amount, genesisLauncherPuzzle.hash())],
      coinsInput: coins,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      originId: launcherParent.id,
      fee: fee,
      coinAnnouncementsToAssert: [assertCoinAnnouncement],
    );

    final genesisLauncherSolution = Program.list([
      Program.fromAtom(puzzlehash),
      Program.fromInt(launcherCoin.amount),
      plotNftExtraData.toProgram(),
    ]);

    final launcherCoinSpend = CoinSpend(
      coin: launcherCoin,
      puzzleReveal: genesisLauncherPuzzle,
      solution: genesisLauncherSolution,
    );

    final launcherSpendBundle = SpendBundle(coinSpends: [launcherCoinSpend]);

    return createLauncherSpendBundle + launcherSpendBundle;
  }

  Future<SpendBundle> createPlotNftMutationSpendBundle({
    required PlotNft plotNft,
    List<CoinPrototype> coinsForFee = const [],
    Puzzlehash? changePuzzleHash,
    int fee = 0,
    required PoolState targetState,
    required WalletKeychain keychain,
  }) async {
    final currentState = plotNft.poolState;
    final launcherId = plotNft.launcherId;
    final currentSingleton = plotNft.singletonCoin;
    final delayPuzzlehash = plotNft.delayPuzzlehash;
    final delayTime = plotNft.delayTime;

    final currentInnerPuzzle = poolStateToInnerPuzzle(
      poolState: currentState,
      launcherId: launcherId,
      delayPuzzlehash: delayPuzzlehash,
      delayTime: delayTime,
    );

    final newInnerPuzzle = poolStateToInnerPuzzle(
      poolState: targetState,
      launcherId: launcherId,
      delayPuzzlehash: delayPuzzlehash,
      delayTime: delayTime,
    );

    if (currentInnerPuzzle == newInnerPuzzle) {
      throw Exception();
    }

    final uncurriedInnerPuzzle = currentInnerPuzzle.uncurry();
    final uncurriedInnerPuzzleProgram = uncurriedInnerPuzzle.mod;

    Program? innerSolution;
    if (uncurriedInnerPuzzleProgram == poolMemberInnerpuzProgram) {
      innerSolution = Program.list([
        Program.list(
          [
            Program.cons(
              Program.fromString('p'),
              Program.fromAtom(targetState.toBytes()),
            )
          ],
        ),
        Program.nil
      ]);
    } else if (uncurriedInnerPuzzleProgram == poolWaitingRoomInnerpuzProgram) {
      innerSolution = Program.list([
        Program.fromInt(1),
        Program.list(
          [
            Program.cons(
              Program.fromString('p'),
              Program.fromAtom(targetState.toBytes()),
            )
          ],
        ),
        Program.fromAtom(newInnerPuzzle.hash().toBytes())
      ]);
    } else {
      throw ArgumentError();
    }

    final fullPuzzle =
        SingletonService.puzzleForSingleton(launcherId, currentInnerPuzzle);

    final fullSolution = Program.list([
      plotNft.lineageProof.toProgram(),
      Program.fromInt(currentSingleton.amount),
      innerSolution,
    ]);

    final travelSpend = CoinSpend(
      coin: currentSingleton,
      puzzleReveal: fullPuzzle,
      solution: fullSolution,
    );

    final travelSpendBundle = SpendBundle(coinSpends: [travelSpend]);

    final ownerPublicKey = currentState.ownerPublicKey;
    final singletonWalletVector =
        keychain.getSingletonWalletVector(ownerPublicKey);
    final privateKey = singletonWalletVector!.singletonOwnerPrivateKey;

    final signedSpendBundle = travelSpendBundle.signPerCoinSpend(
      (coinSpend) => standardWalletService.makeSignature(
        privateKey,
        coinSpend,
        useSyntheticOffset: false,
      ),
    );

    if (fee > 0) {
      final feeSpendBundle = standardWalletService.createSpendBundle(
        fee: fee,
        payments: [],
        coinsInput: coinsForFee,
        keychain: keychain,
        changePuzzlehash: changePuzzleHash,
      );
      return signedSpendBundle + feeSpendBundle;
    }

    return signedSpendBundle;
  }

  Future<SpendBundle> createTransferPlotNftSpendBundle({
    required List<CoinPrototype> coins,
    required JacobianPoint targetOwnerPublicKey,
    required PlotNft plotNft,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzleHash,
    PoolSingletonState? newPoolSingletonState,
    String? poolUrl,
    int fee = 0,
  }) async {
    PoolState? targetState;
    if (poolUrl != null) {
      final poolInfo = await PoolInterface.fromURL(poolUrl).getPoolInfo();
      targetState = PoolState(
        poolSingletonState: PoolSingletonState.farmingToPool,
        targetPuzzlehash: poolInfo.targetPuzzlehash,
        ownerPublicKey: targetOwnerPublicKey,
        relativeLockHeight: poolInfo.relativeLockHeight,
        poolUrl: poolUrl,
      );
    } else {
      targetState = PoolState(
        poolSingletonState:
            newPoolSingletonState ?? plotNft.poolState.poolSingletonState,
        targetPuzzlehash: plotNft.poolState.targetPuzzlehash,
        ownerPublicKey: targetOwnerPublicKey,
        relativeLockHeight: plotNft.poolState.relativeLockHeight,
      );
    }

    final mutationSpendBundle = await createPlotNftMutationSpendBundle(
      keychain: keychain,
      plotNft: plotNft,
      targetState: targetState,
    );

    final hint = SingletonWalletVector.makePlotNftHint(targetOwnerPublicKey);

    final treasureMapSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          1,
          Puzzlehash(plotNft.launcherId),
          memos: <Bytes>[hint],
        )
      ],
      coinsInput: coins,
      keychain: keychain,
      fee: fee,
      changePuzzlehash: changePuzzleHash,
    );

    return mutationSpendBundle + treasureMapSpendBundle;
  }

  Future<SpendBundle> createPlotNftTransferSpendBundle({
    required PlotNft plotNft,
    List<CoinPrototype> coinsForFee = const [],
    required List<CoinPrototype> coinsForTreasureMapCoin,
    Puzzlehash? changePuzzleHash,
    int fee = 0,
    required PoolState targetState,
    required Puzzlehash receiverPuzzlehash,
    required WalletKeychain keychain,
  }) async {
    final currentState = plotNft.poolState;
    if (![PoolSingletonState.leavingPool, PoolSingletonState.selfPooling]
        .contains(currentState.poolSingletonState)) {
      throw Exception(
        'Plot nft must be leaving pool or self pooling to transfer it',
      );
    }
    final launcherId = plotNft.launcherId;
    final currentSingleton = plotNft.singletonCoin;
    final delayPuzzlehash = plotNft.delayPuzzlehash;
    final delayTime = plotNft.delayTime;

    final currentInnerPuzzle = poolStateToInnerPuzzle(
      poolState: currentState,
      launcherId: launcherId,
      delayPuzzlehash: delayPuzzlehash,
      delayTime: delayTime,
    );

    final newWaitingRoomInnerPuzzle = poolStateToInnerPuzzle(
      poolState: targetState,
      launcherId: launcherId,
      delayPuzzlehash: delayPuzzlehash,
      delayTime: delayTime,
    );

    if (currentInnerPuzzle == newWaitingRoomInnerPuzzle) {
      throw Exception();
    }

    final uncurriedInnerPuzzle = currentInnerPuzzle.uncurry();
    final uncurriedInnerPuzzleProgram = uncurriedInnerPuzzle.mod;

    if (uncurriedInnerPuzzleProgram != poolWaitingRoomInnerpuzProgram) {
      throw Exception('wrong inner puzzle');
    }

    final toP2ConditionsInnerSolution = Program.list([
      Program.fromInt(1),
      Program.list(
        [
          Program.cons(
            Program.fromString('p'),
            Program.fromAtom(targetState.toBytes()),
          )
        ],
      ),
      Program.fromAtom(singletonOutputInnerPuzzleProgram.hash().toBytes())
    ]);

    final startingFullPuzzle =
        SingletonService.puzzleForSingleton(launcherId, currentInnerPuzzle);

    final toP2ConditionsFullSolution = Program.list([
      plotNft.lineageProof.toProgram(),
      Program.fromInt(currentSingleton.amount),
      toP2ConditionsInnerSolution,
    ]);

    final toP2ConditionsSpend = CoinSpend(
      coin: currentSingleton,
      puzzleReveal: startingFullPuzzle,
      solution: toP2ConditionsFullSolution,
    );

    final toP2ConditionsSpendBundle =
        SpendBundle(coinSpends: [toP2ConditionsSpend]);
    final intermediaryCoin = toP2ConditionsSpendBundle.additions.single;
    // print('intermediary coin amount: ');
    // print(intermediaryCoin.amount);
    final innerInnerSolution = Program.list([
      Program.list(
        [
          CreateCoinCondition(
            newWaitingRoomInnerPuzzle.hash(),
            intermediaryCoin.amount,
            memos: [receiverPuzzlehash],
          ).toProgram(),
          CreateCoinCondition(
            Puzzlehash(launcherId),
            2,
            memos: [receiverPuzzlehash],
          ).toProgram(),
        ],
      )
    ]);

    // print(
    //   returnConditionsProgram
    //       .run(
    //         innerInnerSolution,
    //       )
    //       .program,
    // );

    final innerP2Solution = Program.list([
      LineageProof(
        parentCoinInfo: plotNft.singletonCoin.parentCoinInfo,
        innerPuzzlehash: currentInnerPuzzle.hash(),
        amount: intermediaryCoin.amount,
      ).toProgram(),
      Program.fromInt(currentSingleton.amount),
      innerInnerSolution,
    ]);
    // final p2FullPuzzle =
    //     SingletonService.puzzleForSingleton(launcherId, singletonOutputInnerPuzzleProgram);
    // print('expected full puzzle hash: ${p2FullPuzzle.hash()}');
    // print('expected inner puzzle hash: ${returnConditionsProgram.hash()}');
    final p2SpendBundle = SpendBundle(
      coinSpends: [
        CoinSpend(
          coin: intermediaryCoin,
          puzzleReveal: SingletonService.puzzleForSingleton(
            launcherId,
            singletonOutputInnerPuzzleProgram,
          ),
          solution: innerP2Solution,
        )
      ],
    );

    final ownerPublicKey = currentState.ownerPublicKey;
    final singletonWalletVector =
        keychain.getSingletonWalletVector(ownerPublicKey);
    final privateKey = singletonWalletVector!.singletonOwnerPrivateKey;

    final signedSpendBundle = toP2ConditionsSpendBundle.signPerCoinSpend(
      (coinSpend) => standardWalletService.makeSignature(
        privateKey,
        coinSpend,
        useSyntheticOffset: false,
      ),
    );

    final standardSupportsSpendBundle = makeStandardTransferSupportSpendBundle(
      keychain: keychain,
      coins: coinsForTreasureMapCoin,
      changePuzzlehash: changePuzzleHash,
    );

    final transferSpendBundle =
        signedSpendBundle + p2SpendBundle + standardSupportsSpendBundle;

    if (fee > 0) {
      final feeSpendBundle = standardWalletService.createSpendBundle(
        fee: fee,
        payments: [],
        coinsInput: coinsForFee,
        keychain: keychain,
        changePuzzlehash: changePuzzleHash,
      );
      return transferSpendBundle + feeSpendBundle;
    }

    return transferSpendBundle;
  }

  SpendBundle makeStandardTransferSupportSpendBundle({
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    required List<CoinPrototype> coins,
  }) {
    final changeAmount = coins.totalValue - 2;
    if (changeAmount < 0) {
      throw Exception(
        'not enough coin value to cover transfer support standard spend bundle',
      );
    }
    if (changeAmount > 0 && changePuzzlehash == null) {
      throw Exception(
        'change puzzle hash is required when there are left over coins',
      );
    }
    return standardWalletService.createSpendBundle(
      payments: [
        if (changeAmount > 0) Payment(changeAmount, changePuzzlehash!)
      ],
      coinsInput: coins,
      keychain: keychain,
      allowLeftOver: true,
      changePuzzlehash: changePuzzlehash,
    );
  }

  Program poolStateToInnerPuzzle({
    required PoolState poolState,
    required Bytes launcherId,
    required Puzzlehash delayPuzzlehash,
    required int delayTime,
    bool isInitialState = false,
  }) {
    final escapingInnerPuzzle = createWaitingRoomInnerPuzzle(
      targetPuzzlehash: poolState.targetPuzzlehash,
      relativeLockHeight: poolState.relativeLockHeight,
      ownerPublicKey: poolState.ownerPublicKey,
      launcherId: launcherId,
      delayTime: delayTime,
      delayPuzzlehash: delayPuzzlehash,
    );
    final escapingInnerPuzzlehash = escapingInnerPuzzle.hash();

    final poolingInnerPuzzle = createPoolingInnerPuzzle(
      targetPuzzlehash: poolState.targetPuzzlehash,
      poolWaitingRoomInnerHash: escapingInnerPuzzlehash,
      ownerPublicKey: poolState.ownerPublicKey,
      launcherId: launcherId,
      delayTime: delayTime,
      delayPuzzlehash: delayPuzzlehash,
    );

    switch (poolState.poolSingletonState) {
      case PoolSingletonState.selfPooling:
        return escapingInnerPuzzle;

      case PoolSingletonState.farmingToPool:
        return poolingInnerPuzzle;

      case PoolSingletonState.leavingPool:
        if (isInitialState) {
          throw ArgumentError(
            'Invalid initial state: ${poolState.poolSingletonState}',
          );
        }
        return escapingInnerPuzzle;
    }
  }

  Program makePoolExtraData(
    PoolState poolState,
    int delayTime,
    Puzzlehash delayPuzzlehash,
  ) =>
      Program.list([
        Program.cons(
          Program.fromString('p'),
          Program.fromAtom(poolState.toBytes()),
        ),
        Program.cons(Program.fromString('t'), Program.fromInt(delayTime)),
        Program.cons(
          Program.fromString('h'),
          Program.fromAtom(delayPuzzlehash),
        ),
      ]);

  Program createWaitingRoomInnerPuzzle({
    required Puzzlehash targetPuzzlehash,
    required int relativeLockHeight,
    required JacobianPoint ownerPublicKey,
    required Bytes launcherId,
    required int delayTime,
    required Puzzlehash delayPuzzlehash,
  }) {
    final p2SingletonPuzzlehash =
        launcherIdToP2Puzzlehash(launcherId, delayTime, delayPuzzlehash);
    return poolWaitingRoomInnerpuzProgram.curry([
      Program.fromAtom(targetPuzzlehash),
      Program.fromAtom(p2SingletonPuzzlehash),
      Program.fromAtom(ownerPublicKey.toBytes()),
      Program.fromAtom(poolRewardPrefix),
      Program.fromInt(relativeLockHeight),
    ]);
  }

  Program createPoolingInnerPuzzle({
    required Puzzlehash targetPuzzlehash,
    required Puzzlehash poolWaitingRoomInnerHash,
    required JacobianPoint ownerPublicKey,
    required Bytes launcherId,
    required int delayTime,
    required Puzzlehash delayPuzzlehash,
  }) {
    final p2SingletonPuzzlehash =
        launcherIdToP2Puzzlehash(launcherId, delayTime, delayPuzzlehash);
    return poolMemberInnerpuzProgram.curry([
      Program.fromAtom(targetPuzzlehash),
      Program.fromAtom(p2SingletonPuzzlehash),
      Program.fromAtom(ownerPublicKey.toBytes()),
      Program.fromAtom(poolRewardPrefix),
      Program.fromAtom(poolWaitingRoomInnerHash),
    ]);
  }

  Bytes get poolRewardPrefix =>
      Bytes.fromHex(blockchainNetwork.aggSigMeExtraData).sublist(0, 16) +
      Bytes(List.filled(16, 0));

  static Puzzlehash launcherIdToP2Puzzlehash(
    Bytes launcherId,
    int secondsDelay,
    Puzzlehash delayedPuzzlehash,
  ) {
    return SingletonService.createP2SingletonPuzzle(
      singletonModHash: singletonTopLayerProgram.hash(),
      launcherId: launcherId,
      secondsDelay: secondsDelay,
      delayedPuzzlehash: delayedPuzzlehash,
    ).hash();
  }

  static Future<Puzzlehash> launcherIdToP2PuzzlehashAsync(
    Bytes launcherId,
    int secondsDelay,
    Puzzlehash delayedPuzzlehash,
  ) async {
    return SingletonService.createP2SingletonPuzzleAsync(
      singletonModHash: singletonTopLayerProgram.hash(),
      launcherId: launcherId,
      secondsDelay: secondsDelay,
      delayedPuzzlehash: delayedPuzzlehash,
    ).then((value) => value.hash());
  }

  void validateSingletonPuzzlehash({
    required Puzzlehash singletonPuzzlehash,
    required Bytes launcherId,
    required PoolState poolState,
    required Puzzlehash delayPuzzlehash,
    required int delayTime,
  }) {
    final innerPuzzle = poolStateToInnerPuzzle(
      poolState: poolState,
      launcherId: launcherId,
      delayPuzzlehash: delayPuzzlehash,
      delayTime: delayTime,
    );

    final fullPuzzle =
        SingletonService.puzzleForSingleton(launcherId, innerPuzzle);

    if (fullPuzzle.hash() != singletonPuzzlehash) {
      throw InvalidPoolSingletonException();
    }
  }

  static CoinPrototype makeLauncherCoin(Bytes genesisCoinId) => CoinPrototype(
        parentCoinInfo: genesisCoinId,
        puzzlehash: singletonLauncherProgram.hash(),
        amount: defaultLauncherCoinAmount,
      );

  static PlotNftExtraData launcherCoinSpendToExtraData(CoinSpend coinSpend) {
    final fullSolution = coinSpend.solution;

    if (coinSpend.coin.puzzlehash != singletonLauncherProgram.hash()) {
      throw ArgumentError('Provided coin spend is not launcher coin spend');
    }
    final extraDataProgram = fullSolution.rest().rest().first();
    return PlotNftExtraData.fromProgram(extraDataProgram);
  }

  static PoolState? coinSpendToPoolState(CoinSpend coinSpend) {
    try {
      final fullSolution = coinSpend.solution;

      // check for launcher spend
      if (coinSpend.coin.puzzlehash == singletonLauncherProgram.hash()) {
        try {
          final extraDataProgram = fullSolution.rest().rest().first();
          return PoolState.fromExtraDataProgram(extraDataProgram);
        } catch (e) {
          return null;
        }
      }
      final innerSolution = fullSolution.rest().rest().first();
      final numberOfArguments = innerSolution.toList().length;

      switch (numberOfArguments) {
        case 2:
          // pool member
          if (innerSolution.rest().first().toInt() != 0) {
            return null;
          }

          final extraDataProgram = innerSolution.first();
          if (extraDataProgram.isAtom) {
            // absorbing
            return null;
          }

          return PoolState.fromExtraDataProgram(extraDataProgram);

        case 3:
          // pool waiting room
          if (innerSolution.first().toInt() == 0) {
            return null;
          }

          final extraDataProgram = innerSolution.rest().first();
          return PoolState.fromExtraDataProgram(extraDataProgram);
        default:
          throw Exception('unexpected number of program arguments');
      }
    } on Exception {
      return null;
    }
  }
}
