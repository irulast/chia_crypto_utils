import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bip39/bip39.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/command/plot_nft/create_new_wallet_with_plotnft.dart';

late final ChiaFullNodeInterface fullNode;

void main(List<String> args) {
  final runner = CommandRunner<Future<void>>('ccu', 'Chia Crypto Utils Command Line Tools')
    ..addCommand(CreateWalletWithPlotNFTCommand());
  // Add global options
  runner.argParser
    ..addOption('log-level', defaultsTo: 'none')
    ..addOption('network', defaultsTo: 'mainnet')
    ..addOption('full-node-url');

  final results = runner.argParser.parse(args);

  if (results.wasParsed('help') || results.command == null) {
    if (results.arguments.isEmpty || results.command == null) {
      print('No commands were provided.');
    }
    print(runner.argParser.usage);
    exit(0);
  }

  if (results['full-node-url'] == null) {
    print('Option full-node-url is mandatory.');
    print(runner.argParser.usage);
    exit(126);
  }

  // Do global setup
  // Configure environment based on user selections
  ChiaNetworkContextWrapper().registerNetworkContext(stringToNetwork(results['network'] as String));
  LoggingContext().setLogLevel(stringToLogLevel(results['log-level'] as String));
  // construct the Chia full node interface
  fullNode = ChiaFullNodeInterface.fromURL(
    results['full-node-url'] as String,
  );

  runner.run(args);
}

class CreateWalletWithPlotNFTCommand extends Command<Future<void>> {
  CreateWalletWithPlotNFTCommand() {
    argParser
      ..addOption('pool-url', defaultsTo: 'https://xch-us-west.flexpool.io')
      ..addOption('certificate-bytes-path', defaultsTo: 'mozilla-ca/cacert.pem');
  }

  @override
  String get description => 'Creates a wallet with a new PlotNFT';

  @override
  String get name => 'Create-WalletWithPlotNFT';

  @override
  Future<void> run() async {
    final poolUrl = argResults!['pool-url'] as String;
    final certificateBytesPath = argResults!['certificate-bytes-path'] as String;
    // clone this for certificate chain: https://github.com/Chia-Network/mozilla-ca.git
    final poolInterface = PoolInterface.fromURLAndCertificate(
      poolUrl,
      certificateBytesPath,
    );
    final poolService = PoolService(poolInterface, fullNode);

    final mnemonicPhrase = generateMnemonic(strength: 256);
    final mnemonic = mnemonicPhrase.split(' ');
    print('Mnemonic Phrase: $mnemonic');

    final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
    final keychain = WalletKeychain.fromCoreSecret(
      keychainSecret,
    );

    final coinAddress = Address.fromPuzzlehash(
      keychain.puzzlehashes[0],
      ChiaNetworkContextWrapper().blockchainNetwork.addressPrefix,
    );

    print(
      'Please send at least 1 mojo and enough extra XCH to cover the fee to create the PlotNFT to: $coinAddress\n',
    );
    print('Press any key when coin has been sent');
    stdin.readLineSync();

    var coins = <Coin>[];
    while (coins.isEmpty) {
      print('waiting for coin...');
      await Future<void>.delayed(const Duration(seconds: 3));
      coins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes, includeSpentCoins: true);

      if (coins.isNotEmpty) {
        print(coins);
      }
    }

    await createNewWalletWithPlotNFT(
      keychainSecret,
      keychain,
      poolService,
      fullNode,
    );
  }
}
