@Timeout(Duration(minutes: 1))

import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final venvDir = Directory('chia-dev-tools/venv');
  if (!venvDir.existsSync()) {
    print('chia-dev-tools is not set up, so test was skipped.');
    return;
  }

  Future<bool> checkCompilation(String pathToClsp, String pathToCompiledHex) async {
    await Process.run('chmod', ['+x', 'test/clsp/compile_clsp.sh']);

    final process =
        await Process.run('./test/clsp/compile_clsp.sh', [pathToClsp, pathToCompiledHex]);

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

  test('should correctly return false when hex to check does not match compilation of clsp file',
      () async {
    final check = await checkCompilation(
      'lib/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clsp',
      'lib/src/cat/puzzles/tails/meltable_genesis_by_coin_id/meltable_genesis_by_coin_id.clvm.hex',
    );

    expect(check, isFalse);
  });
}
