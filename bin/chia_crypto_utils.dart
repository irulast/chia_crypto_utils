import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:bip39/bip39.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/command/exchange/cross_chain_offer_exchange.dart';
import 'package:chia_crypto_utils/src/command/exchange/exchange_btc.dart';
import 'package:chia_crypto_utils/src/command/plot_nft/create_new_wallet_with_plotnft.dart';

late final ChiaFullNodeInterface fullNode;

Future<void> main(List<String> args) async {
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
    ..argParser.addOption('cert-path', defaultsTo: '')
    ..argParser.addOption('key-path', defaultsTo: '')
    ..addCommand(CreateWalletWithPlotNFTCommand())
    ..addCommand(RegisterPlotNFTCommand())
    ..addCommand(GetFarmingStatusCommand())
    ..addCommand(GetCoinRecords())
    ..addCommand(TransferPlotNFTCommand())
    ..addCommand(ExchangeBtcCommand())
    ..addCommand(CrossChainOfferExchangeCommand());

  final results = runner.argParser.parse(args);

  parseHelp(results, runner);

  if (results['full-node-url'] == null) {
    print('\nOption full-node-url is mandatory.');
    printUsage(runner);
    exit(126);
  }

  // Configure environment based on user selections
  LoggingContext().setLogLevel(stringToLogLevel(results['log-level'] as String));
  ChiaNetworkContextWrapper().registerNetworkContext(stringToNetwork(results['network'] as String));

  // construct the Chia full node interface
  var fullNodeUrl = results['full-node-url'] as String;
  if (fullNodeUrl.endsWith('/')) fullNodeUrl = fullNodeUrl.substring(0, fullNodeUrl.length - 1);

  final certBytesPath = results['cert-path'] as String;
  final keyBytesPath = results['key-path'] as String;

  if ((certBytesPath.isEmpty && keyBytesPath.isNotEmpty) ||
      (certBytesPath.isNotEmpty && keyBytesPath.isEmpty)) {
    print('\nTo use options cert-path and key-path both parameters must be provided.');
  } else if (certBytesPath.isNotEmpty && keyBytesPath.isNotEmpty) {
    try {
      fullNode = ChiaFullNodeInterface.fromURL(
        fullNodeUrl,
        certBytes: Bytes(File(certBytesPath).readAsBytesSync()),
        keyBytes: Bytes(File(keyBytesPath).readAsBytesSync()),
      );
    } catch (e) {
      print('\nThere is a problem with the full node information you provided. Please try again.');
      print('\nThe full node should be in the form https://<SERVER_NAME>.\n');
      print('\nex: When using a locally synced full node you can specify https://localhost:8555');
      exit(126);
    }
  } else {
    fullNode = ChiaFullNodeInterface.fromURL(fullNodeUrl);
  }

  try {
    await fullNode.getBlockchainState();
  } catch (e) {
    print("\nCouldn't verify full node running at URL you provided. Please try again.");
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
      ..addOption('pool-url', defaultsTo: '')
      ..addOption('faucet-request-url', defaultsTo: '')
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

    final poolUrl = argResults!['pool-url'] as String;

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

    PoolService? poolService;
    if (poolUrl.isNotEmpty) {
      poolService = _getPoolServiceImpl(
        poolUrl,
        argResults!['certificate-bytes-path'] as String,
      );
    }

    try {
      final plotNFTDetails = await createNewWalletWithPlotNFT(
        keychainSecret: keychainSecret,
        keychain: keychain,
        fullNode: fullNode,
        poolService: poolService,
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

class RegisterPlotNFTCommand extends Command<Future<void>> {
  RegisterPlotNFTCommand() {
    argParser
      ..addOption('pool-url', defaultsTo: 'https://xch-us-west.flexpool.io')
      ..addOption('mnemonic', defaultsTo: '')
      ..addOption('launcher-id')
      ..addOption('payout-address', defaultsTo: '')
      ..addOption(
        'certificate-bytes-path',
        defaultsTo: 'mozilla-ca/cacert.pem',
      );
  }

  @override
  String get description => 'Registers a plotNFT with a pool.';

  @override
  String get name => 'Register-PlotNFT';

  @override
  Future<void> run() async {
    final poolUrl = argResults!['pool-url'] as String;
    final launcherIdString = argResults!['launcher-id'] as String;
    var payoutAddressString = argResults!['payout-address'] as String;

    var mnemonicPhrase = argResults!['mnemonic'] as String;

    try {
      await PoolInterface.fromURL(poolUrl).getPoolInfo();
    } catch (e) {
      throw ArgumentError('Invalid pool-url.');
    }

    if (mnemonicPhrase.isEmpty) {
      print('\nPlease enter the mnemonic with the plot NFT you would like to register:');
      stdout.write('> ');
      mnemonicPhrase = stdin.readLineSync()!;
    }

    final mnemonic = mnemonicPhrase.split(' ');

    if (mnemonic.length != 12 && mnemonic.length != 24) {
      throw ArgumentError(
        '\nInvalid current mnemonic phrase. Must contain either 12 or 24 seed words',
      );
    }

    final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
    final keychain = WalletKeychain.fromCoreSecret(keychainSecret);

    Puzzlehash? payoutPuzzlehash;
    if (payoutAddressString.isEmpty) {
      payoutPuzzlehash = keychain.puzzlehashes[1];
      print('Payout Address: ${payoutPuzzlehash.toAddressWithContext().address}');
    } else {
      Address? payoutAddress;
      while (payoutAddress == null) {
        try {
          payoutAddress = Address(payoutAddressString);
        } catch (e) {
          print('\nPlease enter a valid address for the new owner pool payout address:');
          stdout.write('> ');
          payoutAddressString = stdin.readLineSync()!;
        }
      }
      payoutPuzzlehash = payoutAddress.toPuzzlehash();
    }

    final farmerPublicKeyHex = masterSkToFarmerSk(keychainSecret.masterPrivateKey).getG1().toHex();
    print('Farmer public key: $farmerPublicKeyHex');

    final plotNft = await fullNode.getPlotNftByLauncherId(launcherIdString.hexToBytes());

    if (plotNft == null) {
      throw ArgumentError('Invalid launcher-id');
    }

    final ownerPublicKey = plotNft.poolState.ownerPublicKey;

    keychain.addSingletonWalletVectorForSingletonOwnerPublicKey(
      ownerPublicKey,
      keychainSecret.masterPrivateKey,
    );

    final singletonWalletVector = keychain.getSingletonWalletVector(ownerPublicKey);

    final poolService = _getPoolServiceImpl(
      poolUrl,
      argResults!['certificate-bytes-path'] as String,
    );

    final addFarmerResponse = await poolService.registerAsFarmerWithPool(
      plotNft: plotNft,
      singletonWalletVector: singletonWalletVector!,
      payoutPuzzlehash: payoutPuzzlehash,
    );
    print('Pool welcome message: ${addFarmerResponse.welcomeMessage}');

    GetFarmerResponse? farmerInfo;
    var attempts = 0;
    while (farmerInfo == null && attempts < 6) {
      print('waiting for farmer information to become available...');
      try {
        attempts = attempts + 1;
        await Future<void>.delayed(const Duration(seconds: 15));
        farmerInfo = await poolService.getFarmerInfo(
          authenticationPrivateKey: singletonWalletVector.poolingAuthenticationPrivateKey,
          launcherId: plotNft.launcherId,
        );
      } on PoolResponseException catch (e) {
        if (e.poolErrorResponse.responseCode != PoolErrorState.farmerNotKnown) {
          rethrow;
        }
        if (attempts == 5) {
          print(e.poolErrorResponse.message);
        }
      }
    }

    if (farmerInfo != null) {
      print(farmerInfo);
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

class TransferPlotNFTCommand extends Command<Future<void>> {
  TransferPlotNFTCommand() {
    argParser
      ..addOption('current-mnemonic', defaultsTo: '')
      ..addOption('new-owner-mnemonic', defaultsTo: '')
      ..addOption('new-owner-payout-address', defaultsTo: '')
      ..addOption('pool-url', defaultsTo: 'https://xch-us-west.flexpool.io')
      ..addOption(
        'certificate-bytes-path',
        defaultsTo: 'mozilla-ca/cacert.pem',
      )
      ..addOption('faucet-request-url', defaultsTo: '')
      ..addOption('faucet-request-payload', defaultsTo: '');
  }

  @override
  String get description =>
      'Transfers ownership of plotNFT in selfPooling or leavingPool state and registers it with pool.';

  @override
  String get name => 'Transfer-PlotNFT';

  @override
  Future<void> run() async {
    var currentMnemonicPhrase = argResults!['current-mnemonic'] as String;
    var newOwnerMnemonicPhrase = argResults!['new-owner-mnemonic'] as String;
    var newOwnerPayoutAddressString = argResults!['new-owner-payout-address'] as String;
    final poolUrl = argResults!['pool-url'] as String;
    final faucetRequestURL = argResults!['faucet-request-url'] as String;
    final faucetRequestPayload = argResults!['faucet-request-payload'] as String;

    final plotNftWalletService = PlotNftWalletService();

    try {
      await PoolInterface.fromURL(poolUrl).getPoolInfo();
    } catch (e) {
      throw ArgumentError('Invalid pool-url.');
    }

    if (currentMnemonicPhrase.isEmpty) {
      print('\nPlease enter the mnemonic with the plot NFT you would like to transfer:');
      stdout.write('> ');
      currentMnemonicPhrase = stdin.readLineSync()!;
    }

    final currentMnemonic = currentMnemonicPhrase.split(' ');

    if (currentMnemonic.length != 12 && currentMnemonic.length != 24) {
      throw ArgumentError(
        '\nInvalid current mnemonic phrase. Must contain either 12 or 24 seed words.',
      );
    }

    if (newOwnerMnemonicPhrase.isEmpty) {
      print('\nPlease enter the mnemonic you would like to transfer the plot NFT to:');
      stdout.write('> ');
      newOwnerMnemonicPhrase = stdin.readLineSync()!;
    }

    final newOwnerMnemonic = newOwnerMnemonicPhrase.split(' ');

    if (newOwnerMnemonic.length != 12 && newOwnerMnemonic.length != 24) {
      throw ArgumentError(
        '\nInvalid new owner mnemonic phrase. Must contain either 12 or 24 seed words.',
      );
    }

    final currentKeychainSecret = KeychainCoreSecret.fromMnemonic(currentMnemonic);
    final currentKeychain = WalletKeychain.fromCoreSecret(currentKeychainSecret);

    final newOwnerKeychainSecret = KeychainCoreSecret.fromMnemonic(newOwnerMnemonic);
    final newOwnerKeychain = WalletKeychain.fromCoreSecret(currentKeychainSecret);
    final newOwnerSingletonWalletVector =
        newOwnerKeychain.getNextSingletonWalletVector(newOwnerKeychainSecret.masterPrivateKey);
    final newOwnerPublicKey = newOwnerSingletonWalletVector.singletonOwnerPublicKey;

    Puzzlehash? newOwnerPayoutPuzzlehash;
    if (newOwnerPayoutAddressString.isEmpty) {
      newOwnerPayoutPuzzlehash = newOwnerKeychain.puzzlehashes[1];
      print('\nPayout Address: ${newOwnerPayoutPuzzlehash.toAddressWithContext().address}\n');
    } else {
      Address? newOwnerPayoutAddress;
      while (newOwnerPayoutAddress == null) {
        try {
          newOwnerPayoutAddress = Address(newOwnerPayoutAddressString);
        } catch (e) {
          print('\nPlease enter a valid address for the new owner pool payout address:');
          stdout.write('> ');
          newOwnerPayoutAddressString = stdin.readLineSync()!;
        }
      }
      newOwnerPayoutPuzzlehash = newOwnerPayoutAddress.toPuzzlehash();
    }

    final plotNfts = await fullNode.scroungeForPlotNfts(currentKeychain.puzzlehashes);

    if (plotNfts.isEmpty) {
      throw ArgumentError('There are no plot NFTs on the current mnemonic.');
    }

    PlotNft? plotNft;

    if (plotNfts.length > 1) {
      print('\nPlease choose which plot NFT to send from the below list of launcher IDs.');
      for (var i = 0; i < plotNfts.length; i++) {
        print('${i + 1}. ${plotNfts[i].launcherId}');
      }

      while (plotNft == null) {
        stdout.write('> ');
        final choice = stdin.readLineSync()!.trim();
        try {
          final plotNftIndex = int.parse(choice) - 1;
          if (plotNfts.asMap().containsKey(plotNftIndex)) {
            if (plotNfts[plotNftIndex].poolState.poolSingletonState ==
                PoolSingletonState.farmingToPool) {
              print('The plot NFT to be transferred cannot start in state farmingToPool.');
              print('Please select a different plot NFT.');
            } else {
              plotNft = plotNfts[plotNftIndex];
            }
          } else {
            print('Not a valid choice.');
          }
        } catch (e) {
          print('Please enter the number of the launcher ID of the plot NFT you');
          print('would like to transfer.');
        }
      }
    } else {
      plotNft = plotNfts.single;
      if (plotNft.poolState.poolSingletonState == PoolSingletonState.farmingToPool) {
        throw ArgumentError('The plot NFT to be transferred cannot start in state farmingToPool.');
      }
    }

    print('Starting Pool State: ${plotNft.poolState}\n');

    final currentOwnerPublicKey = plotNft.poolState.ownerPublicKey;

    currentKeychain.addSingletonWalletVectorForSingletonOwnerPublicKey(
      currentOwnerPublicKey,
      currentKeychainSecret.masterPrivateKey,
    );

    final coinAddress = Address.fromPuzzlehash(
      currentKeychain.puzzlehashes.first,
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
    do {
      coins = await fullNode.getCoinsByPuzzleHashes(
        currentKeychain.puzzlehashes,
      );
      if (coins.isEmpty) {
        print('waiting for coins');
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    } while (coins.isEmpty);

    final plotNftTransferSpendBundle = await plotNftWalletService.createTransferPlotNftSpendBundle(
      coins: coins,
      targetOwnerPublicKey: newOwnerPublicKey,
      plotNft: plotNft,
      keychain: currentKeychain,
      newPoolSingletonState: PoolSingletonState.farmingToPool,
      changePuzzleHash: currentKeychain.puzzlehashes.first,
      poolUrl: poolUrl,
    );

    await fullNode.pushTransaction(plotNftTransferSpendBundle);

    List<Coin>? coinsByMemo;
    do {
      coinsByMemo = await fullNode.getCoinsByMemo(newOwnerSingletonWalletVector.plotNftHint);
      if (coinsByMemo.isEmpty) {
        print('waiting for plot NFT transfer to complete');
        await Future<void>.delayed(const Duration(seconds: 10));
      }
    } while (coinsByMemo.isEmpty);

    final plotNftTreasureMapCoin = coinsByMemo.single;

    final transferredPlotNft =
        await fullNode.getPlotNftByLauncherId(plotNftTreasureMapCoin.puzzlehash);

    final launcherId = transferredPlotNft!.launcherId;

    print('\nEnding Pool State: ${transferredPlotNft.poolState}\n');

    final poolInfo = await PoolInterface.fromURL(poolUrl).getPoolInfo();

    final poolService = _getPoolServiceImpl(
      poolUrl,
      argResults!['certificate-bytes-path'] as String,
    );

    AddFarmerResponse? addFarmerResponse;
    var registrationAttempts = 0;
    while (addFarmerResponse == null && registrationAttempts < 6) {
      await Future<void>.delayed(const Duration(minutes: 1));
      print('registering plot NFT with ${poolInfo.name}');
      try {
        registrationAttempts++;
        addFarmerResponse = await poolService.registerAsFarmerWithPool(
          plotNft: transferredPlotNft,
          singletonWalletVector: newOwnerSingletonWalletVector,
          payoutPuzzlehash: newOwnerPayoutPuzzlehash,
        );
        print('\nPool welcome message: ${addFarmerResponse.welcomeMessage}');
      } catch (e) {
        if (registrationAttempts == 5) {
          print('\nThere was a problem registering your plot NFT.');
          print('Try again later with the Register-PlotNft command.');
          exit(1);
        }
      }
    }

    GetFarmerResponse? farmerInfo;
    var attempts = 0;
    while (farmerInfo == null && attempts < 6) {
      print('waiting for farmer information to become available');
      try {
        attempts++;
        await Future<void>.delayed(const Duration(seconds: 15));
        farmerInfo = await poolService.getFarmerInfo(
          authenticationPrivateKey: newOwnerSingletonWalletVector.poolingAuthenticationPrivateKey,
          launcherId: launcherId,
        );
      } on PoolResponseException catch (e) {
        if (e.poolErrorResponse.responseCode != PoolErrorState.farmerNotKnown) {
          rethrow;
        }
        if (attempts == 5) {
          print(e.poolErrorResponse.message);
          exit(1);
        }
      }
    }

    if (farmerInfo != null) {
      print(
        '\nauthentication_public_key: ${farmerInfo.authenticationPublicKey.toHex()}',
      );
      print('launcher_id: $launcherId');
      print('owner_public_key: ${newOwnerPublicKey.toHex()}');
      print('p2_singleton_puzzle_hash: ${plotNft.contractPuzzlehash}');
      print('payout_instructions: ${farmerInfo.payoutInstructions}');
      print('pool_url: $poolUrl');
      print('target_puzzle_hash: ${poolInfo.targetPuzzlehash}');
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
