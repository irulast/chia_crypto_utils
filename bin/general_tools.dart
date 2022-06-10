import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/command/standard/create_cold_wallet.dart';
import './chia_crypto_utils.dart';

late final ChiaFullNodeInterface fullNode;

void main(List<String> args) {
  final runner = CommandRunner<Future<void>>(
    'ccu-general',
    'Chia Crypto Utils General Command Line Tools',
  )
    ..addCommand(CreateColdWalletCommand())
    ..argParser.addOption(
      'log-level',
      defaultsTo: 'none',
      allowed: ['none', 'low', 'high'],
    );

  final results = runner.argParser.parse(args);

  parseHelp(results, runner);

  LoggingContext().setLogLevel(
    stringToLogLevel(results['log-level'] as String),
  );

  runner.run(args);
}

class CreateColdWalletCommand extends Command<Future<void>> {
  @override
  String get description => 'Generate an offline cold wallet';

  @override
  String get name => 'Create-ColdWallet';

  @override
  Future<void> run() async {
    await createColdWallet();
  }
}
