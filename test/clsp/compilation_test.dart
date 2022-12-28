@Timeout(Duration(minutes: 2))

import 'dart:io';

import 'package:test/test.dart';

Future<void> main() async {
  final venvDir = Directory('chia-dev-tools/venv');
  if (!venvDir.existsSync()) {
    print('chia-dev-tools is not set up, so this test was skipped.');
    return;
  }

  Future<bool> checkCompilation(String pathToClsp, String pathToCompiledHex) async {
    final process =
        await Process.run('./test/clsp/compile_clsp.sh', [pathToClsp, pathToCompiledHex]);

    if (process.exitCode == 0) {
      return true;
    } else {
      return false;
    }
  }

  test('should correctly return false when hex does not match clsp compilation', () async {
    final check = await checkCompilation(
      'lib/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clsp',
      'lib/src/cat/puzzles/tails/meltable_genesis_by_coin_id/meltable_genesis_by_coin_id.clvm.hex',
    );

    expect(check, isFalse);
  });

  test('should check that hex of compiled cat.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/cat/puzzles/cat/cat.clsp',
      'lib/src/cat/puzzles/cat/cat.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled delegated_tail.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/cat/puzzles/tails/delegated_tail/delegated_tail.clsp',
      'lib/src/cat/puzzles/tails/delegated_tail/delegated_tail.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled everything_with_signature.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/cat/puzzles/tails/everything_with_signature/everything_with_signature.clsp',
      'lib/src/cat/puzzles/tails/everything_with_signature/everything_with_signature.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled genesis_by_coin_id.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clsp',
      'lib/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled meltable_genesis_by_coin_id.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/cat/puzzles/tails/meltable_genesis_by_coin_id/meltable_genesis_by_coin_id.clsp',
      'lib/src/cat/puzzles/tails/meltable_genesis_by_coin_id/meltable_genesis_by_coin_id.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled calculate_synthetic_public_key.clsp is correct',
      () async {
    final check = await checkCompilation(
      'lib/src/core/puzzles/calculate_synthetic_public_key/calculate_synthetic_public_key.clsp',
      'lib/src/core/puzzles/calculate_synthetic_public_key/calculate_synthetic_public_key.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled p2_delayed_or_preimage.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/exchange/btc/puzzles/p2_delayed_or_preimage/p2_delayed_or_preimage.clsp',
      'lib/src/exchange/btc/puzzles/p2_delayed_or_preimage/p2_delayed_or_preimage.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled pool_member_innerpuz.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/plot_nft/puzzles/pool_member_inner_puz/pool_member_innerpuz.clsp',
      'lib/src/plot_nft/puzzles/pool_member_inner_puz/pool_member_innerpuz.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled pool_waitingroom_innerpuz.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/plot_nft/puzzles/pool_waitingroom_innerpuz/pool_waitingroom_innerpuz.clsp',
      'lib/src/plot_nft/puzzles/pool_waitingroom_innerpuz/pool_waitingroom_innerpuz.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled p2_singleton_or_delayed_puzhash.clsp is correct',
      () async {
    final check = await checkCompilation(
      'lib/src/singleton/puzzles/p2_singleton_or_delayed_puzhash/p2_singleton_or_delayed_puzhash.clsp',
      'lib/src/singleton/puzzles/p2_singleton_or_delayed_puzhash/p2_singleton_or_delayed_puzhash.clsp.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled singleton_launcher.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/singleton/puzzles/singleton_launcher/singleton_launcher.clsp',
      'lib/src/singleton/puzzles/singleton_launcher/singleton_launcher.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled singleton_top_layer.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/singleton/puzzles/singleton_top_layer/singleton_top_layer.clsp',
      'lib/src/singleton/puzzles/singleton_top_layer/singleton_top_layer.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled singleton_top_layer_v1_1.clsp is correct', () async {
    final check = await checkCompilation(
      'lib/src/singleton/puzzles/singleton_top_layer_v1_1/singleton_top_layer_v1_1.clsp',
      'lib/src/singleton/puzzles/singleton_top_layer_v1_1/singleton_top_layer_v1_1.clvm.hex',
    );

    expect(check, isTrue);
  });

  test('should check that hex of compiled p2_delegated_puzzle_or_hidden_puzzle.clsp is correct',
      () async {
    final check = await checkCompilation(
      'lib/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clsp',
      'lib/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex',
    );

    expect(check, isTrue);
  });
}
