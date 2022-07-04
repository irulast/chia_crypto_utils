import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';
import 'package:chia_crypto_utils/src/plot_nft/models/exceptions/invalid_pool_singleton_exception.dart';

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
    final launcherParent = coins.singleWhere((coin) => coin.id == genesisCoinId);
    final genesisLauncherPuzzle = singletonLauncherProgram;
    final launcherCoin = makeLauncherCoin(launcherParent.id);

    final innerPuzzle = poolStateToInnerPuzzle(
      poolState: initialTargetState,
      launcherId: launcherCoin.id,
      delayPuzzlehash: p2SingletonDelayedPuzzlehash,
      delayTime: p2SingletonDelayTime,
      isInitialState: true,
    );

    final fullPoolingPuzzle = SingletonService.puzzleForSingleton(launcherCoin.id, innerPuzzle);
    final puzzlehash = fullPoolingPuzzle.hash();

    final plotNftExtraData = PlotNftExtraData(
      initialTargetState,
      p2SingletonDelayTime,
      p2SingletonDelayedPuzzlehash,
    );

    final announcementMessage = Program.list(
      [
        Program.fromBytes(puzzlehash),
        Program.fromInt(launcherCoin.amount),
        plotNftExtraData.toProgram()
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
      Program.fromBytes(puzzlehash),
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
          Program.fromBytes(poolState.toBytes()),
        ),
        Program.cons(Program.fromString('t'), Program.fromInt(delayTime)),
        Program.cons(
          Program.fromString('h'),
          Program.fromBytes(delayPuzzlehash),
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
    final p2SingletonPuzzlehash = launcherIdToP2Puzzlehash(launcherId, delayTime, delayPuzzlehash);
    return poolWaitingRoomInnerpuzProgram.curry([
      Program.fromBytes(targetPuzzlehash),
      Program.fromBytes(p2SingletonPuzzlehash),
      Program.fromBytes(ownerPublicKey.toBytes()),
      Program.fromBytes(poolRewardPrefix),
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
    final p2SingletonPuzzlehash = launcherIdToP2Puzzlehash(launcherId, delayTime, delayPuzzlehash);
    return poolMemberInnerpuzProgram.curry([
      Program.fromBytes(targetPuzzlehash),
      Program.fromBytes(p2SingletonPuzzlehash),
      Program.fromBytes(ownerPublicKey.toBytes()),
      Program.fromBytes(poolRewardPrefix),
      Program.fromBytes(poolWaitingRoomInnerHash),
    ]);
  }

  Bytes get poolRewardPrefix =>
      Bytes.fromHex(blockchainNetwork.aggSigMeExtraData).sublist(0, 16) + Bytes(List.filled(16, 0));

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

    final fullPuzzle = SingletonService.puzzleForSingleton(launcherId, innerPuzzle);

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
  }
}
