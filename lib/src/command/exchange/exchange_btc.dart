import 'dart:io';
import 'package:bip39/bip39.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/btc_to_xch.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/exchange.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/xch_to_btc.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';

final exchangeService = BtcExchangeService();

Future<void> exchangeXchForBtc(ChiaFullNodeInterface fullNode) async {
  final xchToBtcService = XchToBtcService();

  // generate disposable mnemonic, derive public key, and create signed public key for user
  final mnemonic = generateMnemonic(strength: 256);

  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic.split(' '));

  final xchHolderPrivateKey = masterSkToWalletSkUnhardened(keychainSecret.masterPrivateKey, 500);
  final xchHolderSignedPublicKey = exchangeService.createSignedPublicKey(xchHolderPrivateKey);

  print('');
  print('Send the following line with your signed public key to your counter party.');
  print(xchHolderSignedPublicKey);

  // get and validate counter party public key as pasted by user
  final btcHolderPublicKey = getCounterPartyPublicKey(xchHolderSignedPublicKey);

  // look up current XCH and BTC prices and get amounts of each being exchanged
  // convert to mojos or satoshis if small enough
  // if amount is less than 1 satoshi, round up to 1
  final amountMap = await getAmounts();
  final xchAmount = amountMap['xch'] as double;
  final btcAmount = amountMap['btc'] as double;
  final xchAmountMojos = amountMap['mojos'] as int;
  final btcAmountSatoshis = amountMap['satoshis'] as int;

  // decode lightning payment request as pasted by user and get payment hash
  print('');
  print(
    'Create a lightning payment request for ${(btcAmountSatoshis > 1) ? ((btcAmountSatoshis > 1000) ? '${btcAmount.toStringAsFixed(5)} BTC' : '$btcAmountSatoshis satoshis') : '1 satoshi'}.',
  );
  print('The timeout must be set to at least ten minutes.');
  print('');
  print('Copy and paste the lightning payment request here:');
  final sweepPaymentHash = getPaymentHash();

  // generate address for user to send coins to for exchange
  final chiaswapPuzzlehash = xchToBtcService.generateChiaswapPuzzlehash(
    requestorPrivateKey: xchHolderPrivateKey,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: btcHolderPublicKey,
  );

  final chiaswapAddress = chiaswapPuzzlehash.toAddressWithContext();

  print('');
  print(
    'Transfer ${(xchAmountMojos > 10000000) ? '${xchAmount.toStringAsFixed(9)} XCH' : '$xchAmountMojos mojos'} for the exchange to the following address:',
  );
  print(chiaswapAddress.address);
  print('');
  print('Press any key when the funds have been sent.');
  stdin.readLineSync();

  // wait for user to send XCH
  var chiaswapCoins = <Coin>[];
  while (chiaswapCoins.totalValue < xchAmountMojos) {
    print('waiting for XCH...');
    await Future<void>.delayed(const Duration(seconds: 10));
    chiaswapCoins = await fullNode.getCoinsByPuzzleHashes(
      [chiaswapPuzzlehash],
    );
  }

  print('');
  print('XCH received!');

  // get puzzlehash where user can receive XCH back
  print('');
  print('Enter the address where the XCH will be returned in the event the exchange');
  print('is aborted or fails.');
  final clawbackPuzzlehash = getUserPuzzlehash();

  // create spend bundle for clawing back funds if counter party doesn't pay lightning invoice
  final clawbackSpendBundle = xchToBtcService.createClawbackSpendBundle(
    payments: [Payment(chiaswapCoins.totalValue, clawbackPuzzlehash)],
    coinsInput: chiaswapCoins,
    requestorPrivateKey: xchHolderPrivateKey,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: btcHolderPublicKey,
  );

  print('');
  print('Wait for your counter party to pay the lightning invoice.');
  print('Then share the disposable private key below with your counter party to');
  print('allow them to claim the XCH');
  print(xchHolderPrivateKey.toHex());
  print('');
  print('If the invoice is paid and you have shared your pivate key, you may');
  print('safely exit the program. The exchange is complete.');
  print('');
  print('If your counter party does not pay the invoice within 24 hours, you may');
  print('claw back the XCH to your address.');
  print('');
  print('Alternatively, if both parties agree to abort the exchange, you may receive');
  print('the XCH back sooner if your counter party provides their private key.');
  print('');
  print('Select an option below.');
  print('');

  print('1. The lightning invoice has been paid. Quit program.');
  print('2. 24 hours have passed. Claw back funds.');
  print('3. Abort exchange with counter party private key.');

  String? choice;
  PrivateKey? btcHolderPrivateKey;

  // determine how to conclude exchange based on user input
  while (choice != '1' && choice != '2' && choice != '3') {
    stdout.write('> ');
    choice = stdin.readLineSync();

    if (choice == '1') {
      exit(exitCode);
    } else if (choice == '2') {
      await confirmClawback(clawbackSpendBundle, chiaswapCoins, clawbackPuzzlehash, fullNode);
    } else if (choice == '3') {
      var userInput = '';

      print('');
      print("If you haven't already received it, ask your counter party to share their");
      print('private key and paste it below:');

      while (userInput != '2' && btcHolderPrivateKey == null) {
        stdout.write('> ');
        userInput = stdin.readLineSync()!;
        try {
          final privateKeyInput = PrivateKey.fromHex(userInput);

          if (privateKeyInput.getG1() == btcHolderPublicKey) {
            btcHolderPrivateKey = privateKeyInput;
            final clawbackSpendBundleWithPk = xchToBtcService.createClawbackSpendBundleWithPk(
              payments: [Payment(chiaswapCoins.totalValue, clawbackPuzzlehash)],
              coinsInput: chiaswapCoins,
              requestorPrivateKey: xchHolderPrivateKey,
              sweepPaymentHash: sweepPaymentHash,
              fulfillerPrivateKey: btcHolderPrivateKey,
            );

            print('');
            print('Pushing spend bundle to claw back XCH to your address...');
            print('');
            await generateSpendBundleFile(clawbackSpendBundleWithPk);
            await fullNode.pushTransaction(clawbackSpendBundleWithPk);
            print('');
            await verifyTransaction(chiaswapCoins, clawbackPuzzlehash, fullNode);
          }
        } catch (e) {
          print("Couldn't verify input as private key. Please try again or enter '2' to");
          print('instead claw back funds without private key after 24 hours have passed.');
        }

        if (userInput.toLowerCase().startsWith('2')) {
          await confirmClawback(clawbackSpendBundle, chiaswapCoins, clawbackPuzzlehash, fullNode);
        }
      }
    } else {
      print('');
      print('Not a valid choice.');
    }
  }
}

Future<void> exchangeBtcForXch(ChiaFullNodeInterface fullNode) async {
  final btcToXchService = BtcToXchService();

  // generate disposable mnemonic, derive public key, and create signed public key for user
  final mnemonic = generateMnemonic(strength: 256);
  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic.split(' '));

  final btcHolderPrivateKey = masterSkToWalletSkUnhardened(keychainSecret.masterPrivateKey, 500);
  final btcHolderSignedPublicKey = exchangeService.createSignedPublicKey(btcHolderPrivateKey);

  print('');
  print('Send the following line with your signed public key to your counter party.');
  print(btcHolderSignedPublicKey);

  // validate counter party public key as pasted by user
  final xchHolderPublicKey = getCounterPartyPublicKey(btcHolderSignedPublicKey);

  // look up current XCH and BTC prices and calculate amounts of each being exchanged
  final amountMap = await getAmounts();
  final btcAmount = amountMap['btc'] as double;
  final xchAmountMojos = amountMap['mojos'] as int;
  final btcAmountSatoshis = amountMap['satoshis'] as int;

  print('');
  print(
    'Your counter party will create a lightning payment request for ${(btcAmountSatoshis > 1) ? ((btcAmountSatoshis > 1000) ? '${btcAmount.toStringAsFixed(5)} BTC' : '$btcAmountSatoshis satoshis') : '1 satoshi'}.',
  );

  // decode lightning payment request as pasted by user and get payment hash
  print('');
  print('Paste the lightning payment request from your counter party here:');
  final sweepPaymentHash = getPaymentHash();

  // generate address that counter party will be sending XCH to
  final chiaswapPuzzlehash = btcToXchService.generateChiaswapPuzzlehash(
    requestorPrivateKey: btcHolderPrivateKey,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: xchHolderPublicKey,
  );

  final chiaswapAddress = chiaswapPuzzlehash.toAddressWithContext();

  // get puzzlehash where user will receive XCH from the exchange
  print('');
  print('Enter the address where you would like the XCH delivered.');
  final sweepPuzzlehash = getUserPuzzlehash();
  print('');

  // wait for counter party to send XCH to chiaswap address
  var chiaswapCoins = <Coin>[];
  while (chiaswapCoins.totalValue < xchAmountMojos) {
    print('waiting for counter party to send XCH...');
    await Future<void>.delayed(const Duration(seconds: 10));
    chiaswapCoins = await fullNode.getCoinsByPuzzleHashes(
      [chiaswapPuzzlehash],
    );
  }

  print('');
  print('The XCH from your counter party has been received, which you can verify here:');
  print('https://xchscan.com/address/${chiaswapAddress.address}');
  print('');
  print(
    'Pay the lightning invoice after the payment has received sufficient',
  );
  print('confirmations.');
  print('You must pay and complete this exchange within 24 hours, or else the XCH');
  print('will be returned to your counter party.');
  print('If you wish to abort the exchange, do not pay the lightning invoice.');

  print('');
  print("To claim funds, you will use either your counter party's private key");
  print('or the preimage that is revealed after payment of the lightning invoice.');
  print("If you haven't already received it, ask your counter party to share their");
  print('private key.');
  print('');
  print(
    'If your counter party is nonresponsive, find your lightning invoice preimage',
  );
  print('by navigating to transaction history in your lightning wallet, clicking');
  print('on the transaction, and viewing the payment details.');
  print('');
  print("Please paste either your counter party's private key OR your preimage below.");
  print("If you instead want to abort the exchange, enter 'q' to for instructions");
  print('on how to abort and then quit.');

  PrivateKey? xchHolderPrivateKey;
  Bytes? sweepPreimage;
  SpendBundle? sweepSpendBundle;

  // determine how to conclude exchange based on user input
  while (xchHolderPrivateKey == null && sweepPreimage == null) {
    stdout.write('> ');
    final userInput = stdin.readLineSync();

    if (userInput!.toLowerCase().startsWith('q')) {
      print('');
      print('You have aborted the exchange. Please share your disposable private key below');
      print('with your counter party to allow them to cleanly reclaim their XCH:');
      print(btcHolderPrivateKey.toHex());
      print('');
      print('You may use Ctrl+C to exit the program when you are done.');
    } else {
      try {
        final inputAsPrivateKey = PrivateKey.fromHex(userInput);
        final inputAsPreimage = userInput.hexToBytes();

        if (inputAsPrivateKey.getG1() == xchHolderPublicKey) {
          xchHolderPrivateKey = inputAsPrivateKey;
          sweepSpendBundle = btcToXchService.createSweepSpendBundleWithPk(
            payments: [Payment(chiaswapCoins.totalValue, sweepPuzzlehash)],
            coinsInput: chiaswapCoins,
            requestorPrivateKey: btcHolderPrivateKey,
            sweepPaymentHash: sweepPaymentHash,
            fulfillerPrivateKey: xchHolderPrivateKey,
          );
        } else if (inputAsPreimage.sha256Hash() == sweepPaymentHash) {
          sweepPreimage = inputAsPreimage;

          sweepSpendBundle = btcToXchService.createSweepSpendBundle(
            payments: [Payment(chiaswapCoins.totalValue, sweepPuzzlehash)],
            coinsInput: chiaswapCoins,
            requestorPrivateKey: btcHolderPrivateKey,
            sweepPaymentHash: sweepPaymentHash,
            sweepPreimage: sweepPreimage,
            fulfillerPublicKey: xchHolderPublicKey,
          );
        } else {
          print('');
          print("Couldn't verify input as either private key or preimage. Please try again.");
          print("If you tried inputting the your counter party's private key, try using");
          print('your preimage instead.');
        }
      } catch (e) {
        LoggingContext().error(e.toString());
      }
    }
  }

  print('');
  print('Pushing spend bundle to sweep XCH to your address...');
  print('');
  await generateSpendBundleFile(sweepSpendBundle!);
  try {
    await fullNode.pushTransaction(sweepSpendBundle);
    print('');
    await verifyTransaction(chiaswapCoins, sweepPuzzlehash, fullNode);
  } catch (e) {
    print('');
    print("The transaction couldn't be completed. You may have responded too late.");
  }
}

JacobianPoint getCounterPartyPublicKey(String userSignedPublicKey) {
  print('');
  print("Enter your counter party's signed public key");

  while (true) {
    stdout.write('> ');
    try {
      final signedPublicKey = stdin.readLineSync();
      if (signedPublicKey == userSignedPublicKey) {
        print('');
        print("That's your signed public key. Ask your counter party for theirs.");
      } else {
        final publicKey = exchangeService.parseSignedPublicKey(signedPublicKey!);
        return publicKey;
      }
    } catch (e) {
      print('');
      print('Could not verify signed public key. Please try again.');
    }
  }
}

Future<Map<String, dynamic>> getAmounts() async {
  final response = await XchScan().getChiaPrice();
  final btcPerXch = response.priceBtc;
  final xchPerBtc = 1 / btcPerXch;
  final usdPerXch = response.priceUsd;
  final usdPerBtc = usdPerXch / btcPerXch;

  print('');
  print('These are the current prices:');
  print('1 XCH = $btcPerXch BTC or $usdPerXch USD');
  print('1 BTC = ${xchPerBtc.toStringAsFixed(8)} XCH or ${usdPerBtc.toStringAsFixed(2)} USD');

  double? xchAmount;
  int? xchAmountMojos;

  print('');
  print('Indicate whether you want to input the amount to exchange in XCH or mojos:');
  print('1. XCH');
  print('2. mojos');

  String? choice;

  while (choice != '1' && choice != '2') {
    stdout.write('> ');
    choice = stdin.readLineSync();

    if (choice == '1') {
      print('');
      print('How much XCH is being exchanged?');
      while (xchAmount == null) {
        stdout.write('> ');
        try {
          final xchAmountString = stdin.readLineSync();
          xchAmount = double.parse(xchAmountString!);
          xchAmountMojos = (xchAmount * 1e12).toInt();
        } catch (e) {
          print('');
          print('Please enter the amount of XCH being exchanged:');
        }
      }
    } else if (choice == '2') {
      print('');
      print('How many mojos are being exchanged?');
      while (xchAmountMojos == null) {
        stdout.write('> ');
        try {
          final xchAmountMojosString = stdin.readLineSync();
          xchAmountMojos = int.parse(xchAmountMojosString!);
          xchAmount = xchAmountMojos / 1e12;
        } catch (e) {
          print('');
          print('Please enter the amount of mojos being exchanged:');
        }
      }
    } else {
      print('');
      print('Not a valid choice.');
    }
  }

  final btcAmount = xchAmount! * btcPerXch;
  final btcAmountSatoshis = (btcAmount * 1e8).toInt();

  final amountMap = {
    'xch': xchAmount,
    'mojos': xchAmountMojos,
    'btc': btcAmount,
    'satoshis': btcAmountSatoshis,
  };

  return amountMap;
}

Bytes getPaymentHash() {
  while (true) {
    stdout.write('> ');
    try {
      final paymentRequest = stdin.readLineSync();
      final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest!);
      final sweepPaymentHash = decodedPaymentRequest.tags.paymentHash;
      return sweepPaymentHash;
    } catch (e) {
      print("Couldn't validate the lightning payment request. Please try again:");
    }
  }
}

Puzzlehash getUserPuzzlehash() {
  while (true) {
    stdout.write('> ');
    try {
      final userAddress = stdin.readLineSync();
      final userPuzzlehash = Address(userAddress!).toPuzzlehash();
      return userPuzzlehash;
    } catch (e) {
      print('');
      print("Couldn't verify your address. Please try again:");
    }
  }
}

Future<void> generateSpendBundleFile(SpendBundle spendBundle) async {
  print('Also generating file with spend bundle JSON in the current directory...');
  print('You can use this to push the spend bundle in case the program closes before');
  print('completing the transaction.');
  print('Use a curl command in the same format as shown here:');
  print('https://docs.chia.net/full-node-rpc/#push_tx');
  final spendBundleHexFile = File('spend_bundle_hex.txt').openWrite()..write(spendBundle.toJson());
  await spendBundleHexFile.flush();
  await spendBundleHexFile.close();
}

Future<void> confirmClawback(
  SpendBundle clawbackSpendBundle,
  List<Coin> chiaswapCoins,
  Puzzlehash recipientPuzzlehash,
  ChiaFullNodeInterface fullNode,
) async {
  print('');
  print("If 24 hours haven't passed, the spend bundle will be rejected.");
  print('Proceed? Y/N');

  var confirmation = '';
  while (!confirmation.toLowerCase().startsWith('y')) {
    stdout.write('> ');
    final input = stdin.readLineSync();
    confirmation = input!;
    if (confirmation.toLowerCase().startsWith('y')) {
      print('');
      print('Pushing spend bundle to claw back XCH to your address...');

      print('');
      await generateSpendBundleFile(clawbackSpendBundle);
      try {
        await fullNode.pushTransaction(clawbackSpendBundle);
        print('');
        await verifyTransaction(chiaswapCoins, recipientPuzzlehash, fullNode);
      } catch (e) {
        print('');
        print("The transaction couldn't be completed. If 24 hours haven't passed yet,");
        print('keep waiting and manually push the transaction using the generated file.');
      }
    } else if (confirmation.toLowerCase().startsWith('n')) {
      print('Once 24 hours have passed, you may reclaim the XCH either by responding');
      print("with 'Y' here or by manually pushing the spend bundle using the");
      print('generated hex file.');
      print('');
      print('Have 24 hours passed? If so, push spend bundle to claw back funds?');
    } else {
      print('');
      print('Not a valid choice.');
    }
  }
}

Future<void> verifyTransaction(
  List<Coin> chiaswapCoins,
  Puzzlehash recipientPuzzlehash,
  ChiaFullNodeInterface fullNode,
) async {
  final chiaswapCoinIds = chiaswapCoins.map((coin) => coin.id);

  var recipientParentIds = <Bytes>[];
  while (!chiaswapCoinIds.any((id) => recipientParentIds.contains(id))) {
    print('waiting for transaction to complete...');
    await Future<void>.delayed(const Duration(seconds: 10));
    final recipientCoins = await fullNode.getCoinsByPuzzleHashes(
      [recipientPuzzlehash],
    );
    recipientParentIds = recipientCoins.map((coin) => coin.parentCoinInfo).toList();
  }

  if (chiaswapCoinIds.any((id) => recipientParentIds.contains(id))) {
    print('');
    print('Success! The transaction has been completed.');
  }
}
