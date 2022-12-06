import 'dart:io';
import 'package:bip39/bip39.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/exceptions/bad_signature_on_public_key.dart';
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
  print('Send the line below to your counter party. It contains your signed public key.');
  print(xchHolderSignedPublicKey);

  // validate counter party public key as pasted by user
  final btcHolderPublicKey = getCounterPartyPublicKey();

  // look up current XCH and BTC prices and get amounts of each being exchanged
  final amounts = await getAmounts();
  final xchAmountMojos = (amounts[0] * 1e12).toInt();

  // decode lightning payment request as pasted by user and get payment hash
  print('');
  print('Create a lightning payment request for ${amounts[1]}');
  print('There must be a timeout of at least ten minutes');
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
  print('Transfer enough funds for the exchange to the following address: ');
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
  print('Enter the address where the XCH will be returned if there is change.');
  print('or in the event the exchange is aborted or fails.');
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
  print('Once it is paid, share the private key below to allow your counter party to');
  print('claim the XCH');
  print(xchHolderPrivateKey.toHex());
  print('');
  print('If they never pay the invoice, use the spend bundle below to claw back funds');
  print('after 24 hours:');
  print('');
  print('Warning: if you answer before 24 hours have passed, the spend bundle will');
  print('be rejected.');

  await confirmSpendBundle(clawbackSpendBundle, fullNode);
}

Future<void> exchangeBtcForXch(ChiaFullNodeInterface fullNode) async {
  final btcToXchService = BtcToXchService();

  // generate disposable mnemonic, derive public key, and create signed public key for user
  final mnemonic = generateMnemonic(strength: 256);
  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic.split(' '));

  final btcHolderPrivateKey = masterSkToWalletSkUnhardened(keychainSecret.masterPrivateKey, 500);
  final btcHolderSignedPublicKey = exchangeService.createSignedPublicKey(btcHolderPrivateKey);

  print('');
  print('Send the line below to your counter party. It contains your signed public key.');
  print(btcHolderSignedPublicKey);

  // validate counter party public key as pasted by user
  final xchHolderPublicKey = getCounterPartyPublicKey();

  // look up current XCH and BTC prices and calculate amounts of each being exchanged
  final amounts = await getAmounts();
  final xchAmountMojos = (amounts[0] * 1e12).toInt();

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
    'After the payment has received enough confirmations, pay the lightning invoice.',
  );

  print('');
  print("To claim funds, you will use either your counter party's private key");
  print('or the preimage that is revealed after payment of the lightning invoice.');
  print("If you haven't already received it, ask your counter party to share");
  print('their private key.');
  print(
    'If your counter party is nonresponsive, look up your lightning invoice preimage receipt.',
  );
  print('');
  print("Select whether you are using your counter party's private key or the preimage");
  print('to claim your XCH');

  print('');
  print('1. Private key');
  print('2. Preimage');
  print('3. Quit');

  String? choice;

  while (choice != '1' && choice != '2' && choice != '3') {
    stdout.write('> ');
    choice = stdin.readLineSync();

    // generate spend bundle for user to sweep funds with counter party's private key
    if (choice == '1') {
      print("Please enter your counter party's private key:");

      PrivateKey? xchHolderPrivateKey;

      while (xchHolderPrivateKey == null) {
        try {
          stdout.write('> ');
          final privateKeyInput = stdin.readLineSync();
          final xchHolderPrivateKey = PrivateKey.fromHex(privateKeyInput!);

          assert(
            xchHolderPrivateKey.getG1() == xchHolderPublicKey,
            'Could not verify counter party private key. Please try again.',
          );

          final sweepSpendBundle = btcToXchService.createSweepSpendBundleWithPk(
            payments: [Payment(chiaswapCoins.totalValue, sweepPuzzlehash)],
            coinsInput: chiaswapCoins,
            requestorPrivateKey: btcHolderPrivateKey,
            sweepPaymentHash: sweepPaymentHash,
            fulfillerPrivateKey: xchHolderPrivateKey,
          );

          print('');
          await confirmSpendBundle(sweepSpendBundle, fullNode);
        } catch (e) {
          LoggingContext().error(e.toString());
        }
      }

      // generate spend bundle for user to sweep funds with preimage
    } else if (choice == '2') {
      print('Please enter the preimage:');

      Bytes? sweepPreimage;

      while (sweepPreimage == null) {
        try {
          stdout.write('> ');
          final preimageInput = stdin.readLineSync();
          final sweepPreimage = preimageInput.toString().hexToBytes();

          assert(
            sweepPreimage.sha256Hash() == sweepPaymentHash,
            'Could not verify preimage. Please try again.',
          );

          final sweepSpendBundle = btcToXchService.createSweepSpendBundle(
            payments: [Payment(chiaswapCoins.totalValue, sweepPuzzlehash)],
            coinsInput: chiaswapCoins,
            requestorPrivateKey: btcHolderPrivateKey,
            sweepPaymentHash: sweepPaymentHash,
            sweepPreimage: sweepPreimage,
            fulfillerPublicKey: xchHolderPublicKey,
          );

          print('');
          await confirmSpendBundle(sweepSpendBundle, fullNode);
        } catch (e) {
          LoggingContext().error(e.toString());
        }
      }
    } else if (choice == '3') {
      exit(exitCode);
    } else {
      print('Not a valid choice.');
    }
  }
}

JacobianPoint getCounterPartyPublicKey() {
  print('');
  print("Enter your counter party's signed public key");

  while (true) {
    stdout.write('> ');
    try {
      final btcHolderSignedPublicKey = stdin.readLineSync();
      final publicKey = exchangeService.parseSignedPublicKey(btcHolderSignedPublicKey!);
      return publicKey;
    } catch (e) {
      print('');
      print('Could not verify signed public key. Please try again.');
    }
  }
}

Future<List<double>> getAmounts() async {
  final response = await XchScan().getChiaPrice();
  final btcPerXch = response.priceBtc;
  final xchPerBtc = 1 / btcPerXch;
  final usdPerXch = response.priceUsd;
  final usdPerBtc = usdPerXch / btcPerXch;

  print('');
  print('These are the current prices:');
  print('1 XCH = $btcPerXch BTC or $usdPerXch USD');
  print('1 BTC = $xchPerBtc XCH or $usdPerBtc USD');

  double? xchAmount;

  print('');
  print('How much XCH is being traded?');

  while (xchAmount == null) {
    stdout.write('> ');
    try {
      final xchAmountString = stdin.readLineSync();
      xchAmount = double.parse(xchAmountString!);
    } catch (e) {
      print('Please enter the amount of XCH being traded:');
      print('');
    }
  }

  final btcAmount = xchAmount * btcPerXch;

  return [xchAmount, btcAmount];
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
      print("Couldn't verify your address. Please truy again:");
    }
  }
}

Future<void> confirmSpendBundle(SpendBundle spendBundle, ChiaFullNodeInterface fullNode) async {
  var confirmation = '';

  print('Generating file with spend bundle hex in the current directory...');
  print('You can use this to push the spend bundle manually in case the program closes.');
  final spendBundleHexFile = File('spendBundleHex.txt').openWrite()..write(spendBundle.toHex());
  await spendBundleHexFile.flush();
  await spendBundleHexFile.close();

  print('Push spend bundle to claim funds? (Y/N)');
  while (confirmation.toLowerCase() != 'y') {
    stdout.write('> ');
    final input = stdin.readLineSync();
    confirmation = input!;
  }
  try {
    await fullNode.pushTransaction(spendBundle);
  } catch (e) {
    LoggingContext().error(e.toString());
  }
}
