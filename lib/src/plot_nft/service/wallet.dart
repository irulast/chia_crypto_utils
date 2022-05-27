import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/service/base_wallet.dart';
import 'package:chia_crypto_utils/src/singleton/puzzles/singleton_launcher/singleton_launcher.clvm.hex.dart';
import 'package:chia_crypto_utils/src/singleton/puzzles/singleton_top_layer/singleton_top_layer.clvm.hex.dart';
import 'package:chia_crypto_utils/src/singleton/service/singleton_service.dart';

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

    final escapingInnerPuzzle = createWaitingRoomInnerPuzzle(
      targetPuzzlehash: initialTargetState.targetPuzzlehash,
      relativeLockHeight: initialTargetState.relativeLockHeight,
      ownerPublicKey: initialTargetState.ownerPublicKey,
      launcherId: launcherCoin.id,
      delayTime: p2SingletonDelayTime,
      delayPuzzlehash: p2SingletonDelayedPuzzlehash,
    );
    final escapingInnerPuzzlehash = escapingInnerPuzzle.hash();

    final selfPoolingInnerPuzzle = createPoolingInnerPuzzle(
      targetPuzzlehash: initialTargetState.targetPuzzlehash,
      poolWaitingRoomInnerHash: escapingInnerPuzzlehash,
      ownerPublicKey: initialTargetState.ownerPublicKey,
      launcherId: launcherCoin.id,
      delayTime: p2SingletonDelayTime,
      delayPuzzlehash: p2SingletonDelayedPuzzlehash,
    );

    late Program puzzle;
    if (initialTargetState.poolSingletonState ==
        PoolSingletonState.selfPooling) {
      puzzle = escapingInnerPuzzle;
    } else if (initialTargetState.poolSingletonState ==
        PoolSingletonState.farmingToPool) {
      puzzle = selfPoolingInnerPuzzle;
    } else {
      throw ArgumentError(
        'Invalid initial state: ${initialTargetState.poolSingletonState}',
      );
    }
    final fullPoolingPuzzle =
        SingletonService.puzzleForSingleton(launcherCoin.id, puzzle);
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
    final p2SingletonPuzzlehash =
        launcherIdToP2Puzzlehash(launcherId, delayTime, delayPuzzlehash);
    return poolWaitingRoomInnerpuzProgram.curry([
      Program.fromBytes(targetPuzzlehash),
      Program.fromBytes(p2SingletonPuzzlehash),
      Program.fromBytes(ownerPublicKey.toBytes()),
      Program.fromBytes(poolRewardPrefix),
      Program.fromInt(delayTime),
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
      Program.fromBytes(targetPuzzlehash),
      Program.fromBytes(p2SingletonPuzzlehash),
      Program.fromBytes(ownerPublicKey.toBytes()),
      Program.fromBytes(poolRewardPrefix),
      Program.fromBytes(poolWaitingRoomInnerHash),
    ]);
  }

  Bytes get poolRewardPrefix =>
      Bytes.fromHex(blockchainNetwork.aggSigMeExtraData).sublist(0, 16) +
      Bytes(List.filled(16, 0));

  Puzzlehash launcherIdToP2Puzzlehash(
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

  static CoinPrototype makeLauncherCoin(Bytes genesisCoinId) => CoinPrototype(
        parentCoinInfo: genesisCoinId,
        puzzlehash: singletonLauncherProgram.hash(),
        amount: defaultLauncherCoinAmount,
      );

  static PlotNftExtraData? coinSpendToExtraData(CoinSpend coinSpend) {
    final fullSolution = coinSpend.solution;

    // check for launcher spend
    if (coinSpend.coin.puzzlehash == singletonLauncherProgram.hash()) {
      try {
        final extraDataProgram = fullSolution.rest().rest().first();
        return PlotNftExtraData.fromProgram(extraDataProgram);
      } catch (e) {
        return null;
      }
    }

    // logic for extracting extra data when plot nft has been updated will go here
    return null;
  }
}
