// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/service/base_wallet.dart';
import 'package:chia_utils/src/singleton/puzzles/singleton_launcher/singleton_launcher.clvm.hex.dart';
import 'package:chia_utils/src/singleton/puzzles/singleton_top_layer_v1_1/singleton_top_layer_v1_1.clvm.hex.dart';

class SingletonService extends BaseWalletService {
  static Program makeSingletonStructureProgram(Bytes coinId) => Program.cons(
        Program.fromBytes(singletonTopLayerV1Program.hash()),
        Program.cons(
          Program.fromBytes(coinId),
          Program.fromBytes(singletonLauncherProgram.hash()),
        ),
      );

  static Program makeSingletonLauncherSolution(int amount, Puzzlehash puzzlehash) => Program.list([
        Program.fromBytes(puzzlehash),
        Program.fromInt(amount),
        Program.fromBytes(List.filled(128, 0)),
      ]);
}
