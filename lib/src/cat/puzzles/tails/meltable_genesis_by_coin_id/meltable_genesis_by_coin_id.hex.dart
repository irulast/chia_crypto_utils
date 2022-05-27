// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/src/clvm/program.dart';

final meltableGenesisByCoinIdProgram = Program.deserializeHex(
  'ff02ffff03ff2fffff01ff02ffff03ffff15ff2fff8080ffff01ff0880ff8080ff0180ffff01ff02ffff03ffff09ff2dff0280ff80ffff01ff088080ff018080ff0180',
);
