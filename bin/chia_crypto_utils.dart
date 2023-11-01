import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:bip39/bip39.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';

import 'package:chia_crypto_utils/src/command/core/nuke_keychain.dart';
import 'package:chia_crypto_utils/src/command/exchange/cross_chain_offer_exchange.dart';
import 'package:chia_crypto_utils/src/command/exchange/exchange_btc.dart';
import 'package:chia_crypto_utils/src/command/plot_nft/create_new_wallet_with_plotnft.dart';
import 'package:chia_crypto_utils/src/core/resources/bip_39_words.dart';

late final ChiaFullNodeInterface fullNode;

Future<void> main(List<String> args) async {
  final runner = CommandRunner<Future<void>>(
    'ccu',
    'Chia Crypto Utils Command Line Tools',
  )
    ..argParser.addOption(
      'log-level',
      defaultsTo: 'low',
      allowed: ['none', 'low', 'high'],
    )
    ..argParser.addOption('network', defaultsTo: 'mainnet')
    ..argParser.addOption('full-node-url')
    ..argParser.addOption('cert-path', defaultsTo: '')
    ..argParser.addOption('key-path', defaultsTo: '')
    ..addCommand(CreateWalletWithPlotNFTCommand())
    ..addCommand(GetFarmingStatusCommand())
    ..addCommand(GetCoinRecords())
    ..addCommand(ExchangeBtcCommand())
    ..addCommand(CrossChainOfferExchangeCommand())
    ..addCommand(BurnDid())
    ..addCommand(NukeKeychain())
    ..addCommand(InspectDid())
    ..addCommand(TransferDidCommand());

  final results = runner.argParser.parse(args);

  parseHelp(results, runner);

  if (results['full-node-url'] == null) {
    print('\nOption full-node-url is mandatory.');
    printUsage(runner);
    exit(126);
  }

  // Configure environment based on user selections
  LoggingContext().setLogLevel(LogLevel.fromString(results['log-level'] as String));
  LoggingContext().setLogger((text) {
    stderr.write('$text\n');
  });

  ChiaNetworkContextWrapper().registerNetworkContext(
    stringToNetwork(results['network'] as String),
  );

  // construct the Chia full node interface
  var fullNodeUrl = results['full-node-url'] as String;
  if (fullNodeUrl.endsWith('/')) fullNodeUrl = fullNodeUrl.substring(0, fullNodeUrl.length - 1);

  final certBytesPath = results['cert-path'] as String;
  final keyBytesPath = results['key-path'] as String;

  if ((certBytesPath.isEmpty && keyBytesPath.isNotEmpty) ||
      (certBytesPath.isNotEmpty && keyBytesPath.isEmpty)) {
    LoggingContext()
        .info('\nTo use options cert-path and key-path both parameters must be provided.');
  } else if (certBytesPath.isNotEmpty && keyBytesPath.isNotEmpty) {
    try {
      fullNode = ChiaFullNodeInterface.fromURL(
        fullNodeUrl,
        certBytes: Bytes(File(certBytesPath).readAsBytesSync()),
        keyBytes: Bytes(File(keyBytesPath).readAsBytesSync()),
      );
    } catch (e) {
      LoggingContext().error(
        '\nThere is a problem with the full node information you provided. Please try again.',
      );
      LoggingContext().error('\nThe full node should be in the form https://<SERVER_NAME>.\n');
      LoggingContext().error(
        '\nex: When using a locally synced full node you can specify https://localhost:8555',
      );
      exit(126);
    }
  } else {
    fullNode = ChiaFullNodeInterface.fromURL(fullNodeUrl);
  }

  try {
    await fullNode.getBlockchainState();
  } catch (e) {
    LoggingContext()
        .error("\nCouldn't verify full node running at URL you provided. Please try again.");
    exit(126);
  }

  unawaited(runner.run(args));
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
      ..addOption('faucet-request-url')
      ..addOption('faucet-request-payload', defaultsTo: '')
      ..addOption('output-config', defaultsTo: '')
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
    final faucetRequestURL = argResults!['faucet-request-url'] as String;
    final faucetRequestPayload = argResults!['faucet-request-payload'] as String;

    final outputConfigFile = argResults!['output-config'] as String;

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

    if (faucetRequestURL.isNotEmpty && faucetRequestPayload.isNotEmpty) {
      final theFaucetRequestPayload =
          faucetRequestPayload.replaceAll(RegExp('SEND_TO_ADDRESS'), coinAddress.address);

      final result = await Process.run('curl', [
        '-s',
        '-d',
        theFaucetRequestPayload,
        '-H',
        'Content-Type: application/json',
        '-X',
        'POST',
        faucetRequestURL,
      ]);

      stdout.write(result.stdout);
      stderr.write(result.stderr);
    } else {
      print(
        'Please send at least 1 mojo and enough extra XCH to cover the fee to create the PlotNFT to: ${coinAddress.address}\n',
      );
      print('Press any key when coin has been sent');
      stdin.readLineSync();
    }

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
      final plotNFTDetails = await createNewWalletWithPlotNFT(
        keychainSecret,
        keychain,
        poolService,
        fullNode,
      );

      if (outputConfigFile.isNotEmpty) {
        await File(outputConfigFile).writeAsString(
          '''
{
    "mnemonic": "$mnemonicPhrase",
    "first_address": "${coinAddress.address}",
    "contract_address": "${plotNFTDetails.contractAddress.address}",
    "payout_address": "${plotNFTDetails.payoutAddress.address}",
    "launcher_id": "${plotNFTDetails.launcherId.toHex()}",
    "worker_name": "Evergreen_v1"
}
''',
        );
      }
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
        final farmingStatus = await getFarmingStatus(
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

class ExchangeBtcCommand extends Command<Future<void>> {
  ExchangeBtcCommand();

  @override
  String get description => 'Initiates an atomic swap between XCH and BTC';

  @override
  String get name => 'Exchange-Btc';

  @override
  Future<void> run() async {
    await chooseExchangePath(fullNode);
  }
}

class CrossChainOfferExchangeCommand extends Command<Future<void>> {
  CrossChainOfferExchangeCommand();

  @override
  String get description => 'Initiates a cross chain offer exchange between XCH and BTC';

  @override
  String get name => 'Make-CrossChainOfferExchange';

  @override
  Future<void> run() async {
    print('\nAre you making a new cross chain offer, accepting an existing one, or');
    print('continuing an ongoing exchange?');
    print('\n1. Making cross chain offer');
    print('2. Accepting cross chain offer');
    print('3. Continuing ongoing exchange');

    String? choice;

    while (choice != '1' && choice != '2' && choice != '3') {
      stdout.write('> ');
      choice = stdin.readLineSync()!.trim();

      if (choice == '1') {
        await makeCrossChainOffer(fullNode);
      } else if (choice == '2') {
        await acceptCrossChainOffer(fullNode);
      } else if (choice == '3') {
        await resumeCrossChainOfferExchange(fullNode);
      } else {
        print('\nNot a valid choice.');
      }
    }
  }
}

class NukeKeychain extends Command<Future<void>> {
  NukeKeychain() {
    argParser
      ..addOption('mnemonic')
      ..addOption('wallet-size', defaultsTo: '50')
      ..addOption('burn-bundle-size', defaultsTo: '25')
      ..addOption('fee-per-coin', defaultsTo: '100');
  }

  @override
  String get description => 'Send all coins on keychain to burn address';

  @override
  String get name => 'NukeKeychain';

  @override
  Future<void> run() async {
    final mnemonic = argResults!['mnemonic'] as String;
    final walletSize = parseArgument(argResults!['wallet-size'], int.parse)!;
    final burnBundleSize = parseArgument(argResults!['burn-bundle-size'], int.parse)!;
    final feePerCoin = parseArgument(argResults!['fee-per-coin'], int.parse)!;

    final keychain = WalletKeychain.fromCoreSecret(
      KeychainCoreSecret.fromMnemonicString(mnemonic),
      walletSize: walletSize,
    );
    final enhancedFullNode = EnhancedChiaFullNodeInterface.fromUrl(fullNode.fullNode.baseURL);
    await nukeKeychain(
      keychain: keychain,
      fullNode: enhancedFullNode,
      blockchainUtils: BlockchainUtils(enhancedFullNode, logger: print),
      feePerCoin: feePerCoin,
      burnBundleSize: burnBundleSize,
    );
  }
}

class BurnDid extends Command<Future<void>> {
  BurnDid() {
    argParser
      ..addOption('mnemonic')
      ..addOption('did')
      ..addOption('wallet-size', defaultsTo: '50')
      ..addOption('fee', defaultsTo: '100');
  }

  @override
  String get description => 'Send DID to burn address';

  @override
  String get name => 'BurnDid';

  @override
  Future<void> run() async {
    final mnemonic = argResults!['mnemonic'] as String;
    final did = parseArgument(argResults!['did'], DidInfo.parseDidFromEitherFormat)!;
    final walletSize = parseArgument(argResults!['wallet-size'], int.parse)!;
    final fee = parseArgument(argResults!['fee'], int.parse)!;
    final keychain = WalletKeychain.fromCoreSecret(
      KeychainCoreSecret.fromMnemonicString(mnemonic),
      walletSize: walletSize,
    );
    final enhancedFullNode = EnhancedChiaFullNodeInterface.fromUrl(fullNode.fullNode.baseURL);

    final didWalletService = DIDWalletService();
    print('searching for DID');
    final didInfos = await enhancedFullNode.getDidRecordsByHints(keychain.puzzlehashes);
    final matchingDids = didInfos.where((element) => element.did == did);
    if (matchingDids.isEmpty) {
      print("couldn't find did by keychain hints");
      exit(1);
    }
    final standardCoins = await enhancedFullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

    final coinsForFee = selectCoinsForAmount(standardCoins, fee);

    final spendBundle = didWalletService.createSpendBundle(
      didInfo: matchingDids.single.toDidInfoOrThrow(keychain),
      keychain: keychain,
    );
    final feeSpendBundle = StandardWalletService().createFeeSpendBundle(
      fee: fee,
      standardCoins: coinsForFee,
      keychain: keychain,
      changePuzzlehash: keychain.puzzlehashes.last,
    );

    final combinedSpendBundle = spendBundle + feeSpendBundle;

    await enhancedFullNode.pushTransaction(combinedSpendBundle);
    print('pushed DID burn spend bundle');
    await BlockchainUtils(enhancedFullNode, logger: print).waitForSpendBundle(combinedSpendBundle);
    exit(0);
  }
}

class InspectDid extends Command<Future<void>> {
  InspectDid() {
    argParser
      ..addOption('mnemonic')
      ..addOption('did')
      ..addOption('search-by', defaultsTo: 'hints')
      ..addOption('wallet-size', defaultsTo: '50');
  }

  @override
  String get description => 'Inspect did and parse did private key';

  @override
  String get name => 'InspectDid';

  @override
  Future<void> run() async {
    final mnemonic = argResults!['mnemonic'] as String;
    final searchTypeName = argResults!['search-by'] as String;

    final did = parseArgument(argResults!['did'], DidInfo.parseDidFromEitherFormat)!;

    final walletSize = parseArgument(argResults!['wallet-size'], int.parse)!;

    final keychain = WalletKeychain.fromCoreSecret(
      KeychainCoreSecret.fromMnemonicString(mnemonic),
      walletSize: walletSize,
    );

    final searchType = DidSearchType.fromName(searchTypeName);
    final enhancedFullNode = EnhancedChiaFullNodeInterface.fromUrl(fullNode.fullNode.baseURL);
    print('searching for did');
    final didInfo = (await () async {
      switch (searchType) {
        case DidSearchType.hints:
          final didInfos = await enhancedFullNode.getDidRecordsByHints(keychain.puzzlehashes);
          final matchingDids = didInfos.where((element) => element.did == did);
          if (matchingDids.isEmpty) {
            return null;
          }
          return matchingDids.single;

        case DidSearchType.crawl:
          return fullNode.getDidRecordForDid(did);
      }
    }())
        ?.toDidInfo(keychain);

    if (didInfo == null) {
      print('No did info found searching by ${searchType.name}');
      exit(1);
    }

    print('did: $did');
    print('p2_puzzle_hash: ${didInfo.p2Puzzle.hash()}');

    final privateKey = keychain.getWalletVectorOrThrow(didInfo.p2Puzzle.hash()).childPrivateKey;

    print('did_private_key: ${privateKey.toHex()}');
  }
}

class TransferDidCommand extends Command<Future<void>> {
  TransferDidCommand() {
    argParser
      ..addOption(
        'certificate-bytes-path',
        defaultsTo: 'mozilla-ca/cacert.pem',
      )
      ..addOption('mnemonic', defaultsTo: '')
      ..addOption('wallet-size', defaultsTo: '50')
      ..addOption('current-did-address', defaultsTo: '')
      ..addOption('fee', defaultsTo: '50');
  }

  @override
  String get description => 'Transfers DID';

  @override
  String get name => 'Transfer-DID';

  @override
  Future<void> run() async {
    final walletSize = parseArgument(argResults!['wallet-size'], int.parse)!;
    final fee = parseArgument(argResults!['fee'], int.parse)!;
    final currentDidAddress = parseArgument(
      argResults!['current-did-address'],
      (e) => Address(e).toPuzzlehash().toAddressWithContext(),
    );

    var mnemonic = parseArgument(argResults!['mnemonic'], parseValidMnemonic);

    if (mnemonic == null) {
      print('\nEnter your mneomnic');
      mnemonic = getUserMnemonic();
    }
    final secret = KeychainCoreSecret.fromMnemonic(mnemonic);
    print('\nkeychain fingerprint: ${secret.fingerprint}');
    final keychain = WalletKeychain.fromCoreSecret(secret, walletSize: walletSize);
    final coins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);
    final dids = currentDidAddress != null
        ? await fullNode.getDidRecordsFromHint(currentDidAddress.toPuzzlehash())
        : await fullNode.getDidRecordsFromHints(keychain.puzzlehashes);

    final coinsForFee = () {
      try {
        return selectCoinsForAmount(
          coins,
          fee,
          minMojos: 20,
        );
      } on InsufficientBalanceException catch (e) {
        print('Insufficient balance to cover fee of $fee mojos: ${e.currentBalance} mojos');
        return null;
      }
    }();
    if (coinsForFee == null) {
      exit(exitCode);
    }

    if (dids.isEmpty) {
      print('\nNo DIDs found. Make sure you entered your mnemonic correctly.');
      exit(exitCode);
    }

    print('\nPlease select which DID to transfer:');
    for (var i = 0; i < dids.length; i++) {
      print('${i + 1}. ${dids[i].did}');
    }

    DidRecord? didToTransfer;
    while (didToTransfer == null) {
      stdout.write('> ');

      try {
        final input = stdin.readLineSync()!.trim();
        final choice = int.parse(input) - 1;

        if (choice <= dids.length) {
          didToTransfer = dids[choice];
        } else {
          print('Not a valid choice.');
        }
      } catch (e) {
        print('Not a valid choice.');
      }
    }

    print('\nEnter the destination address:');
    final destinationPuzzlehash = getUserPuzzlehash();

    final spendableDid = didToTransfer.toDidInfo(keychain);

    if (spendableDid == null) {
      print('Could not match inner puzzle for ${didToTransfer.did} with this keychain');
      exit(exitCode);
    }

    final spendBundle = DIDWalletService().createTransferSpendBundle(
      didInfo: spendableDid,
      newP2Puzzlehash: destinationPuzzlehash,
      keychain: keychain,
      changePuzzlehash: keychain.puzzlehashes.random,
      fee: fee,
      coinsForFee: coinsForFee,
    );

    await fullNode.pushAndWaitForSpendBundle(spendBundle);
    print('DID transfer complete!');
    exit(0);
  }
}

void printUsage(CommandRunner<dynamic> runner) {
  print(runner.argParser.usage);
  print('\nAvailable commands:');
  for (final command in runner.commands.keys) {
    print('    $command');
  }
}

void parseHelp(ArgResults results, CommandRunner<dynamic> runner) {
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

T? parseArgument<T>(dynamic argument, T Function(String) parser) {
  final stringArgument = argument as String?;
  if (stringArgument == null || stringArgument.isEmpty) return null;
  return parser(stringArgument);
}

List<String> getUserMnemonic() {
  final mnemonicPhrase = stdin.readLineSync();
  if (mnemonicPhrase == null) {
    exitWithMessage('Must supply a mnemonic phrase');
  }
  return parseValidMnemonic(mnemonicPhrase);
}

List<String> parseValidMnemonic(String mnemonicString) {
  final mnemonic = mnemonicString.split(' ');

  if (mnemonic.length != 12 && mnemonic.length != 24) {
    exitWithMessage(
      'Invalid mnemonic phrase. Must contain either 12 or 24 seed words',
    );
  }
  final invalidWords = <String>[];
  for (final word in mnemonic) {
    if (!bip39Words.contains(word)) {
      invalidWords.add(word);
    }
  }

  if (invalidWords.isNotEmpty) {
    exitWithMessage('Invalid bip 39 words in mnemonic: $invalidWords');
  }
  return mnemonic;
}

Never exitWithMessage(String message) {
  print('\n$message\n');
  exit(0);
}

Puzzlehash getUserPuzzlehash() {
  // get puzzlehash where user would like to receive XCH at
  while (true) {
    stdout.write('> ');
    try {
      final requestorAddress = stdin.readLineSync()!.trim().toLowerCase();
      final requestorPuzzlehash = Address(requestorAddress).toPuzzlehash();
      return requestorPuzzlehash;
    } catch (e) {
      print('\nInvalid address. Please try again:');
    }
  }
}

enum DidSearchType {
  hints,
  crawl;

  factory DidSearchType.fromName(String name) {
    final lowerCaseName = name.toLowerCase();
    for (final searchType in values) {
      if (searchType.name == lowerCaseName) {
        return searchType;
      }
    }
    throw Exception('Invalid did search type: $name');
  }
}
