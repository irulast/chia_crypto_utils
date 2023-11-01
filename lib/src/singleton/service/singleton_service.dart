// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/singleton/puzzles/singleton_top_layer/singleton_top_layer_debugging.clvm.hex.dart';

class SingletonService extends BaseWalletService {
  static Program puzzleForSingleton(
    Bytes launcherId,
    Program innerPuzzle,
  ) =>
      singletonTopLayerProgram.curry([
        Program.cons(
          Program.fromAtom(singletonTopLayerProgram.hash()),
          Program.cons(
            Program.fromAtom(launcherId),
            Program.fromAtom(singletonLauncherProgram.hash()),
          ),
        ),
        innerPuzzle,
      ]);

  static Program makeSingletonStructureProgram(Bytes coinId) => Program.cons(
        Program.fromAtom(singletonTopLayerV1Program.hash()),
        Program.cons(
          Program.fromAtom(coinId),
          Program.fromAtom(singletonLauncherProgram.hash()),
        ),
      );

  static Program makeSingletonLauncherSolution(
    int amount,
    Puzzlehash puzzlehash,
  ) =>
      Program.list([
        Program.fromAtom(puzzlehash),
        Program.fromInt(amount),
        Program.fromAtom(List.filled(128, 0)),
      ]);

  static Program createP2SingletonPuzzle({
    required Bytes singletonModHash,
    required Bytes launcherId,
    required int secondsDelay,
    required Puzzlehash delayedPuzzlehash,
  }) {
    return p2SingletonOrDelayedPuzhashProgram.curry([
      Program.fromAtom(singletonModHash),
      Program.fromAtom(launcherId),
      Program.fromAtom(singletonLauncherProgram.hash()),
      Program.fromInt(secondsDelay),
      Program.fromAtom(delayedPuzzlehash),
    ]);
  }

  static Future<Program> createP2SingletonPuzzleAsync({
    required Bytes singletonModHash,
    required Bytes launcherId,
    required int secondsDelay,
    required Puzzlehash delayedPuzzlehash,
  }) {
    return p2SingletonOrDelayedPuzhashProgram.curryAsync([
      Program.fromAtom(singletonModHash),
      Program.fromAtom(launcherId),
      Program.fromAtom(singletonLauncherProgram.hash()),
      Program.fromInt(secondsDelay),
      Program.fromAtom(delayedPuzzlehash),
    ]);
  }

  static CoinPrototype getMostRecentSingletonCoinFromCoinSpend(CoinSpend coinSpend) {
    final additions = coinSpend.additions;
    // cribbed from https://github.com/Chia-Network/chia-blockchain/blob/4230af1a59768f6a4f9578408f810d7d2114c343/chia/pools/pool_puzzles.py#L284
    return additions.singleWhere((coin) => coin.amount.isOdd);
  }
}
