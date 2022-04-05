// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/src/clvm/program.dart';

final meltableGenesisByCoinIdProgram = Program.parse('(a (i 47 (q 2 (i (> 47 ()) (q 8) ()) 1) (q 2 (i (= 45 2) () (q 8)) 1)) 1)');
