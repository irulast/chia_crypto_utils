@Timeout(Duration(minutes: 1))

import 'dart:io';

import 'package:test/test.dart';

Future<void> main() async {
  Future<bool> checkCompilation(String pathToClsp, String pathToCompiledHex) async {
    final process = await Process.run(
      'osascript',
      [
        '-e',
        'do shell script "./test/clsp/compile_clsp.sh $pathToClsp $pathToCompiledHex" with administrator privileges',
      ],
    );

    if (process.exitCode == 0) {
      return true;
    } else {
      return false;
    }
  }

  test('should check that compiled hex of genesis_by_coin_id.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clsp',
      'lib/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that compiled hex of genesis_by_coin_id.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clsp',
      'lib/src/cat/puzzles/tails/meltable_genesis_by_coin_id/meltable_genesis_by_coin_id.clvm.hex',
    );

    expect(check, isFalse);
  });
}
