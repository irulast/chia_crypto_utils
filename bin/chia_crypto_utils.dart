import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bip39/bip39.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/command/plot_nft/create_new_wallet_with_plotnft.dart';

late final String logLevel;
late final String network;
late final String poolUrl;
late final String fullNodeUrl;
late final String certificateBytesPath;

void main(List<String> args) {
  final runner = CommandRunner<Future<void>>('ccu', 'Chia Crypto Utils Command Line Tools')
    ..addCommand(ParseCreatePlotNFTCommand());

  runner.argParser
    ..addOption('log-level', defaultsTo: 'none')
    ..addOption('network', defaultsTo: 'mainnet')
    ..addOption('pool-url', defaultsTo: 'https://xch-us-west.flexpool.io')
    ..addOption('full-node-url')
    ..addOption('certificate-bytes-path', defaultsTo: 'mozilla-ca/cacert.pem');

  final results = runner.argParser.parse(args);
  logLevel = results['log-level'] as String;
  network = results['network'] as String;
  poolUrl = results['pool-url'] as String;
  fullNodeUrl = results['full-node-url'] as String;
  certificateBytesPath = results['certificate-bytes-path'] as String;

  runner.run(args);
}

class ParseCreatePlotNFTCommand extends Command<Future<void>> {
  @override
  String get description => 'Creates a wallet with a new PlotNFT';

  @override
  String get name => 'Create-WalletWithPlotNFT';

  @override
  Future<void> run() async {
    // Configure environment based on user selections
    ChiaNetworkContextWrapper().registerNetworkContext(stringToNetwork(network));
    LoggingContext().setLogLevel(stringToLogLevel(logLevel));

    // construct the Chia full node interface
    final fullNode = ChiaFullNodeInterface.fromURL(
      fullNodeUrl,
    );

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
      5,
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
