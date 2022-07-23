import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:bip39/bip39.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/command/plot_nft/create_new_wallet_with_plotnft.dart';
import 'package:chia_crypto_utils/src/command/plot_nft/get_farming_status.dart';

late final ChiaFullNodeInterface fullNode;

void main(List<String> args) {
  final runner = CommandRunner<Future<void>>(
    'ccu',
    'Chia Crypto Utils Command Line Tools',
  )
    ..argParser.addOption(
      'log-level',
      defaultsTo: 'none',
      allowed: ['none', 'low', 'high'],
    )
    ..argParser.addOption('network', defaultsTo: 'mainnet')
    ..argParser.addOption('full-node-url')
    ..addCommand(CreateWalletWithPlotNFTCommand())
    ..addCommand(GetFarmingStatusCommand())
    ..addCommand(GetCoinRecords());

  final results = runner.argParser.parse(args);

  parseHelp(results, runner);

  if (results['full-node-url'] == null) {
    print('Option full-node-url is mandatory.');
    printUsage(runner);
    exit(126);
  }

  // Configure environment based on user selections
  LoggingContext().setLogLevel(stringToLogLevel(results['log-level'] as String));
  ChiaNetworkContextWrapper().registerNetworkContext(stringToNetwork(results['network'] as String));
  // construct the Chia full node interface
  fullNode = ChiaFullNodeInterface.fromURL(
    results['full-node-url'] as String,
  );

  runner.run(args);
}

class GetCoinRecords extends Command<Future<void>> {
  GetCoinRecords() {
    argParser
      ..addOption(
        'puzzlehash',
        defaultsTo: '',
      )
      ..addOption(
        'address',
        defaultsTo: '',
      )
      ..addOption(
        'includeSpentCoins',
        defaultsTo: 'false',
      );
  }

  @override
  String get description => 'Gets coin records for a given address or puzzlehash';

  @override
  String get name => 'Get-CoinRecords';

  @override
  Future<void> run() async {
    final puzzlehashArg = argResults?['puzzlehash'] as String;
    final addressArg = argResults?['address'] as String;
    final includeSpentCoinsArg = argResults?['includeSpentCoins'] as String;

    if (puzzlehashArg.isEmpty && addressArg.isEmpty) {
      throw ArgumentError('Must supply either a puzzlehash or address');
    }

    if (puzzlehashArg.isNotEmpty && addressArg.isNotEmpty) {
      throw ArgumentError('Must not supply both puzzlehash and address');
    }

    final includeSpentCoins = includeSpentCoinsArg == 'true';

    Puzzlehash puzzlehash;
    try {
      puzzlehash = addressArg.isNotEmpty
          ? Address(addressArg).toPuzzlehash()
          : Puzzlehash.fromHex(puzzlehashArg);
    } catch (e) {
      throw ArgumentError('Invalid address or puzzlehash');
    }

    var coins = <Coin>[];
    while (coins.isEmpty) {
      print('waiting for coins...');
      await Future<void>.delayed(const Duration(seconds: 3));
      coins = await fullNode.getCoinsByPuzzleHashes(
        [puzzlehash],
        includeSpentCoins: includeSpentCoins,
      );

      if (coins.isNotEmpty) {
        print('Found ${coins.length} coins!');
        for (final coin in coins) {
          print(coin.toFullJson());
        }
      }
    }
  }
}

class CreateWalletWithPlotNFTCommand extends Command<Future<void>> {
  CreateWalletWithPlotNFTCommand() {
    argParser
      ..addOption('pool-url', defaultsTo: 'https://xch-us-west.flexpool.io')
      ..addOption(
        'certificate-bytes-path',
        defaultsTo: 'mozilla-ca/cacert.pem',
      );
  }

  @override
  String get description => 'Creates a wallet with a new PlotNFT';

  @override
  String get name => 'Create-WalletWithPlotNFT';

  @override
  Future<void> run() async {
    final poolService = _getPoolServiceImpl(
      argResults!['pool-url'] as String,
      argResults!['certificate-bytes-path'] as String,
    );
    final mnemonicPhrase = generateMnemonic(strength: 256);
    final mnemonic = mnemonicPhrase.split(' ');
    print('Mnemonic Phrase: $mnemonicPhrase');

    final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
    final keychain = WalletKeychain.fromCoreSecret(
      keychainSecret,
    );

    final farmerPublicKeyHex = masterSkToFarmerSk(keychainSecret.masterPrivateKey).getG1().toHex();
    print('Farmer public key: $farmerPublicKeyHex');

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
      coins = await fullNode.getCoinsByPuzzleHashes(
        keychain.puzzlehashes,
        includeSpentCoins: true,
      );

      if (coins.isNotEmpty) {
        print(coins);
      }
    }

    try {
      await createNewWalletWithPlotNFT(
        keychainSecret,
        keychain,
        poolService,
        fullNode,
      );
    } catch (e) {
      LoggingContext().error(e.toString());
    }
  }
}

class GetFarmingStatusCommand extends Command<Future<void>> {
  GetFarmingStatusCommand() {
    argParser.addOption(
      'certificate-bytes-path',
      defaultsTo: 'mozilla-ca/cacert.pem',
    );
  }

  @override
  String get description => 'Gets the farming status of a mnemonic';

  @override
  String get name => 'Get-FarmingStatus';

  @override
  Future<void> run() async {
    final mnemonicPhrase = stdin.readLineSync();
    if (mnemonicPhrase == null) {
      throw ArgumentError('Must supply a mnemonic phrase to check');
    }

    final mnemonic = mnemonicPhrase.split(' ');

    if (mnemonic.length != 12 && mnemonic.length != 24) {
      throw ArgumentError(
        'Invalid mnemonic phrase. Must contain either 12 or 24 seed words',
      );
    }

    final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
    final keychain = WalletKeychain.fromCoreSecret(
      keychainSecret,
    );

    final plotNfts = await fullNode.scroungeForPlotNfts(keychain.puzzlehashes);
    for (final plotNft in plotNfts) {
      LoggingContext().info(plotNft.toString());
      
      final poolService = _getPoolServiceImpl(
        plotNft.poolState.poolUrl!,
        argResults!['certificate-bytes-path'] as String,
      );

      try {
        final farmingStatus =await getFarmingStatus(
          plotNft,
          keychainSecret,
          keychain,
          poolService,
          fullNode,
        );

        print(farmingStatus);
      } catch (e) {
        LoggingContext().error(e.toString());
      }
    }
  }
}

void printUsage(CommandRunner runner) {
  print(runner.argParser.usage);
  print('\nAvailable commands:');
  for (final command in runner.commands.keys) {
    print('    $command');
  }
}

void parseHelp(ArgResults results, CommandRunner runner) {
  if (results.command == null || results.wasParsed('help') || results.command?.name == 'help') {
    if (results.arguments.isEmpty || results.command == null) {
      print('No command was provided.');
    }
    printUsage(runner);
    exit(0);
  }
}

PoolService _getPoolServiceImpl(String poolUrl, String certificateBytesPath) {
  // clone this for certificate chain: https://github.com/Chia-Network/mozilla-ca.git
  final poolInterface = PoolInterface.fromURL(
    poolUrl,
    certificateBytesPath: certificateBytesPath,
  );

  return PoolServiceImpl(poolInterface, fullNode);
}
