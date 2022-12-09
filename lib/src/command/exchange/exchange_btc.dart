import 'dart:io';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/btc_to_xch.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/exchange.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/xch_to_btc.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';

final exchangeService = BtcExchangeService();

class Amounts {
  const Amounts({
    required this.xch,
    required this.btc,
    required this.mojos,
    required this.satoshis,
  });

  final double xch;
  final double btc;
  final int mojos;
  final int satoshis;
}

Future<void> exchangeXchForBtc(ChiaFullNodeInterface fullNode) async {
  final xchToBtcService = XchToBtcService();

  // generate disposable private key and create signed public key for user
  final xchHolderPrivateKey = PrivateKey.generate();
  final xchHolderSignedPublicKey = exchangeService.createSignedPublicKey(xchHolderPrivateKey);

  print('\nSend the following line with your signed public key to your counter party.');
  print(xchHolderSignedPublicKey);
  await Future<void>.delayed(const Duration(seconds: 2));

  // get and validate counter party public key as pasted by user
  final btcHolderPublicKey = getFulfillerPublicKey(xchHolderSignedPublicKey);

  // look up current XCH and BTC prices and get amounts of each being exchanged in terms of
  // XCH, BTC, mojos, and satoshis
  // if amount is less than 1 satoshi, round up to 1
  final amounts = await getAmounts();

  // get clawback delay from user
  final clawbackDelayMinutes = await getClawbackDelay();
  final clawbackDelaySeconds = clawbackDelayMinutes * 60;

  // decode lightning payment request as pasted by user and get payment hash
  print(
    '\nCreate a lightning payment request for ${(amounts.satoshis > 1) ? ((amounts.satoshis > 1000) ? '${amounts.btc.toStringAsFixed(5)} BTC' : '${amounts.satoshis} satoshis') : '1 satoshi'}.',
  );
  print('Set the timeout to $clawbackDelayMinutes minutes.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nCopy and paste the lightning payment request here:');
  final sweepPaymentHash = getPaymentHash();

  // generate address for user to send coins to for exchange
  final chiaswapPuzzlehash = xchToBtcService.generateChiaswapPuzzlehash(
    requestorPrivateKey: xchHolderPrivateKey,
    clawbackDelaySeconds: clawbackDelaySeconds,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: btcHolderPublicKey,
  );

  final chiaswapAddress = chiaswapPuzzlehash.toAddressWithContext();

  print(
    '\nTransfer ${(amounts.mojos > 10000000) ? '${amounts.xch.toStringAsFixed(9)} XCH' : '${amounts.mojos} mojos'} for the exchange to the following holding address:',
  );
  print(chiaswapAddress.address);
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nPress any key when the funds have been sent.');
  stdin.readLineSync();

  // wait for user to send XCH
  var chiaswapCoins = <Coin>[];
  while (chiaswapCoins.totalValue < amounts.mojos) {
    print('Waiting for XCH...');
    await Future<void>.delayed(const Duration(seconds: 10));
    chiaswapCoins = await fullNode.getCoinsByPuzzleHashes(
      [chiaswapPuzzlehash],
    );
  }

  print('\nXCH received!');

  // get puzzlehash where user can receive XCH back
  print('\nEnter the address where the XCH will be returned in the event the exchange');
  print('is aborted or fails.');
  final clawbackPuzzlehash = getRequestorPuzzlehash();

  // create spend bundle for clawing back funds if counter party doesn't pay lightning invoice
  final clawbackSpendBundle = xchToBtcService.createClawbackSpendBundle(
    payments: [Payment(chiaswapCoins.totalValue, clawbackPuzzlehash)],
    coinsInput: chiaswapCoins,
    requestorPrivateKey: xchHolderPrivateKey,
    clawbackDelaySeconds: clawbackDelaySeconds,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: btcHolderPublicKey,
  );

  print('\nWait for your counter party to pay the lightning invoice.');
  print('Then share the disposable private key below with your counter party to');
  print('allow them to claim the XCH:');
  print(xchHolderPrivateKey.toHex());
  await Future<void>.delayed(const Duration(seconds: 3));
  print('\nPress any key to continue.');
  stdin.readLineSync();
  print('If the invoice is paid and you have shared your pivate key, you may');
  print('safely exit the program. The exchange is complete.');
  await Future<void>.delayed(const Duration(seconds: 3));
  print(
    '\nIf your counter party does not pay the invoice within $clawbackDelayMinutes minutes, you may',
  );
  print('claw back the XCH to your address.');
  await Future<void>.delayed(const Duration(seconds: 3));
  print('\nAlternatively, if both parties agree to abort the exchange, you may receive');
  print('the XCH back sooner if your counter party provides their private key.');
  await Future<void>.delayed(const Duration(seconds: 3));
  print('\nSelect an option below.\n');

  print('1. The lightning invoice has been paid. Quit program.');
  print('2. $clawbackDelayMinutes minutes have passed. Claw back funds.');
  print('3. Abort exchange with counter party private key.');

  String? choice;
  PrivateKey? btcHolderPrivateKey;

  // determine how to conclude exchange based on user input
  while (choice != '1' && choice != '2' && choice != '3') {
    stdout.write('> ');
    choice = stdin.readLineSync()!.trim();
    if (choice != '1' && choice != '2' && choice != '3') {
      print('\nNot a valid choice.');
    }
  }

  if (choice == '1') {
    exit(exitCode);
  } else if (choice == '2') {
    await confirmClawback(
      clawbackSpendBundle: clawbackSpendBundle,
      clawbackDelayMinutes: clawbackDelayMinutes,
      chiaswapCoins: chiaswapCoins,
      clawbackPuzzlehash: clawbackPuzzlehash,
      fullNode: fullNode,
    );
  } else if (choice == '3') {
    var input = '';

    print("\nIf you haven't already received it, ask your counter party to share their");
    print('private key and paste it below:');

    while (input != '2' && btcHolderPrivateKey == null) {
      stdout.write('> ');
      input = stdin.readLineSync()!.trim().toLowerCase();
      try {
        final privateKeyInput = PrivateKey.fromHex(input);

        if (privateKeyInput.getG1() == btcHolderPublicKey) {
          btcHolderPrivateKey = privateKeyInput;
          final clawbackSpendBundleWithPk = xchToBtcService.createClawbackSpendBundleWithPk(
            payments: [Payment(chiaswapCoins.totalValue, clawbackPuzzlehash)],
            coinsInput: chiaswapCoins,
            requestorPrivateKey: xchHolderPrivateKey,
            clawbackDelaySeconds: clawbackDelaySeconds,
            sweepPaymentHash: sweepPaymentHash,
            fulfillerPrivateKey: btcHolderPrivateKey,
          );

          print('\nPushing spend bundle to claw back XCH to your address...');
          await generateSpendBundleFile(clawbackSpendBundleWithPk);
          await fullNode.pushTransaction(clawbackSpendBundleWithPk);
          await verifyTransaction(chiaswapCoins, clawbackPuzzlehash, fullNode);
        }
      } catch (e) {
        print("\nCouldn't verify input as private key. Please try again or enter '2' to");
        print(
          'instead claw back funds without private key after $clawbackDelayMinutes minutes have passed.',
        );
      }

      if (input == '2') {
        await confirmClawback(
          clawbackSpendBundle: clawbackSpendBundle,
          clawbackDelayMinutes: clawbackDelayMinutes,
          chiaswapCoins: chiaswapCoins,
          clawbackPuzzlehash: clawbackPuzzlehash,
          fullNode: fullNode,
        );
      }
    }
  }
}

Future<void> exchangeBtcForXch(ChiaFullNodeInterface fullNode) async {
  final btcToXchService = BtcToXchService();

  // generate disposable private key and create signed public key for user
  final btcHolderPrivateKey = PrivateKey.generate();
  final btcHolderSignedPublicKey = exchangeService.createSignedPublicKey(btcHolderPrivateKey);

  print('\nSend the following line with your signed public key to your counter party.');
  print(btcHolderSignedPublicKey);
  await Future<void>.delayed(const Duration(seconds: 2));

  // validate counter party public key as pasted by user
  final xchHolderPublicKey = getFulfillerPublicKey(btcHolderSignedPublicKey);

  // look up current XCH and BTC prices and get amounts of each being exchanged in terms of
  // XCH, BTC, mojos, and satoshis
  final amounts = await getAmounts();

  // get clawback delay from user
  final clawbackDelayMinutes = await getClawbackDelay();
  final clawbackDelaySeconds = clawbackDelayMinutes * 60;

  print(
    '\nYour counter party will create a lightning payment request for ${(amounts.satoshis > 1) ? ((amounts.satoshis > 1000) ? '${amounts.btc.toStringAsFixed(5)} BTC' : '${amounts.satoshis} satoshis') : '1 satoshi'}.',
  );
  await Future<void>.delayed(const Duration(seconds: 2));

  // decode lightning payment request as pasted by user and get payment hash
  print('\nPaste the lightning payment request from your counter party here:');
  final sweepPaymentHash = getPaymentHash();

  // generate address that counter party will be sending XCH to
  final chiaswapPuzzlehash = btcToXchService.generateChiaswapPuzzlehash(
    requestorPrivateKey: btcHolderPrivateKey,
    clawbackDelaySeconds: clawbackDelaySeconds,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: xchHolderPublicKey,
  );

  final chiaswapAddress = chiaswapPuzzlehash.toAddressWithContext();

  // get puzzlehash where user will receive XCH from the exchange
  print('\nEnter the address where you would like the XCH delivered.');
  final sweepPuzzlehash = getRequestorPuzzlehash();
  print('\nYour counter party should be sending XCH for the exchange to a holding address.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nPress any key to continue once they have send the XCH.\n');
  stdin.readLineSync();

  // wait for counter party to send XCH to chiaswap address
  var chiaswapCoins = <Coin>[];
  while (chiaswapCoins.totalValue < amounts.mojos) {
    print('Waiting for counter party to send XCH...');
    await Future<void>.delayed(const Duration(seconds: 15));
    chiaswapCoins = await fullNode.getCoinsByPuzzleHashes(
      [chiaswapPuzzlehash],
    );
  }

  print('\nThe XCH from your counter party has been received at the holding address, which');
  print('you can verify here:');
  print('https://xchscan.com/address/${chiaswapAddress.address}');
  print('\nPay the lightning invoice after the payment has received sufficient');
  print('confirmations.');
  await Future<void>.delayed(const Duration(seconds: 3));
  print(
    '\nYou must pay and complete this exchange within $clawbackDelayMinutes minutes, or else the XCH',
  );
  print('will be returned to your counter party.');
  print('If you wish to abort the exchange, do not pay the lightning invoice.');
  await Future<void>.delayed(const Duration(seconds: 3));
  print("\nTo claim funds, you will use either your counter party's private key");
  print('or the preimage that is revealed after payment of the lightning invoice.');
  print("If you haven't already received it, ask your counter party to share their");
  print('private key.');
  await Future<void>.delayed(const Duration(seconds: 3));
  print('\nIf your counter party is nonresponsive, find your lightning invoice preimage');
  print('by navigating to transaction history in your lightning wallet, clicking');
  print('on the transaction, and viewing the payment details.');
  await Future<void>.delayed(const Duration(seconds: 3));
  print("\nPlease paste either your counter party's private key OR your preimage below.");
  print("If you instead want to abort the exchange, enter 'q' to for instructions");
  print('on how to abort and then quit.');

  PrivateKey? xchHolderPrivateKey;
  Bytes? sweepPreimage;
  SpendBundle? sweepSpendBundle;

  // determine how to conclude exchange based on user input
  while (xchHolderPrivateKey == null && sweepPreimage == null) {
    stdout.write('> ');
    final input = stdin.readLineSync()!.trim().toLowerCase();

    if (input.startsWith('q')) {
      print('\nPlease share your disposable private key below with your counter party to allow');
      print('them to cleanly reclaim their XCH:');
      print(btcHolderPrivateKey.toHex());
      await Future<void>.delayed(const Duration(seconds: 3));
      print('\nAfter you have done so, you may use Ctrl+C to exit the program.');
    } else {
      try {
        final inputAsPrivateKey = PrivateKey.fromHex(input);
        final inputAsPreimage = input.hexToBytes();

        if (inputAsPrivateKey.getG1() == xchHolderPublicKey) {
          xchHolderPrivateKey = inputAsPrivateKey;
          sweepSpendBundle = btcToXchService.createSweepSpendBundleWithPk(
            payments: [Payment(chiaswapCoins.totalValue, sweepPuzzlehash)],
            coinsInput: chiaswapCoins,
            requestorPrivateKey: btcHolderPrivateKey,
            clawbackDelaySeconds: clawbackDelaySeconds,
            sweepPaymentHash: sweepPaymentHash,
            fulfillerPrivateKey: xchHolderPrivateKey,
          );
        } else if (inputAsPreimage.sha256Hash() == sweepPaymentHash) {
          sweepPreimage = inputAsPreimage;

          sweepSpendBundle = btcToXchService.createSweepSpendBundle(
            payments: [Payment(chiaswapCoins.totalValue, sweepPuzzlehash)],
            coinsInput: chiaswapCoins,
            requestorPrivateKey: btcHolderPrivateKey,
            clawbackDelaySeconds: clawbackDelaySeconds,
            sweepPaymentHash: sweepPaymentHash,
            sweepPreimage: sweepPreimage,
            fulfillerPublicKey: xchHolderPublicKey,
          );
        } else {
          print("\nCouldn't verify input as either private key or preimage. Please try again.");
          print("If you tried inputting the your counter party's private key, try using");
          print('your preimage instead.');
        }
      } catch (e) {
        LoggingContext().error(e.toString());
      }
    }
  }

  print('\nPushing spend bundle to sweep XCH to your address...');
  await generateSpendBundleFile(sweepSpendBundle!);
  try {
    await fullNode.pushTransaction(sweepSpendBundle);
    await verifyTransaction(chiaswapCoins, sweepPuzzlehash, fullNode);
  } catch (e) {
    print('\nTRANSACTION FAILED. The spend bundle was rejected.');
    print('The clawback delay period may have already passed.');
  }
}

JacobianPoint getFulfillerPublicKey(String requestorSignedPublicKey) {
  print("\nEnter your counter party's signed public key:");

  while (true) {
    stdout.write('> ');
    try {
      final signedPublicKey = stdin.readLineSync()!.trim().toLowerCase();
      if (signedPublicKey == requestorSignedPublicKey) {
        print("\nThat's your signed public key. Ask your counter party for theirs.");
      } else {
        final publicKey = exchangeService.parseSignedPublicKey(signedPublicKey!);
        return publicKey;
      }
    } catch (e) {
      print('\nCould not verify signed public key. Please try again.');
    }
  }
}

Future<Amounts> getAmounts() async {
  final response = await XchScan().getChiaPrice();
  final btcPerXch = response.priceBtc;
  final xchPerBtc = 1 / btcPerXch;
  final usdPerXch = response.priceUsd;
  final usdPerBtc = usdPerXch / btcPerXch;

  print('\nThese are the current prices of XCH and BTC:');
  print('1 XCH = $btcPerXch BTC or $usdPerXch USD');
  print('1 BTC = ${xchPerBtc.toStringAsFixed(8)} XCH or ${usdPerBtc.toStringAsFixed(2)} USD');
  await Future<void>.delayed(const Duration(seconds: 2));

  print('\nIndicate whether you want to input the amount to exchange in XCH or mojos:');
  print('1. XCH');
  print('2. mojos');

  double? xchAmount;
  int? xchAmountMojos;
  String? choice;

  while (choice != '1' && choice != '2') {
    stdout.write('> ');
    choice = stdin.readLineSync()!.trim();

    if (choice != '1' && choice != '2') {
      print('\nNot a valid choice.');
    }
  }

  if (choice == '1') {
    print('\nHow much XCH is being exchanged?');
    while (xchAmount == null) {
      stdout.write('> ');
      try {
        final xchAmountString = stdin.readLineSync()!.trim();
        xchAmount = double.parse(xchAmountString);
        xchAmountMojos = (xchAmount * 1e12).toInt();
      } catch (e) {
        print('\nPlease enter the amount of XCH being exchanged:');
      }
    }
  } else if (choice == '2') {
    print('\nHow many mojos are being exchanged?');
    while (xchAmountMojos == null) {
      stdout.write('> ');
      try {
        final xchAmountMojosString = stdin.readLineSync()!.trim();
        xchAmountMojos = int.parse(xchAmountMojosString);
        xchAmount = xchAmountMojos / 1e12;
      } catch (e) {
        print('\nPlease enter the amount of mojos being exchanged:');
      }
    }
  }

  final btcAmount = xchAmount! * btcPerXch;
  final btcAmountSatoshis = (btcAmount * 1e8).toInt();

  final amounts = Amounts(
    xch: xchAmount,
    btc: btcAmount,
    mojos: xchAmountMojos!,
    satoshis: btcAmountSatoshis,
  );

  return amounts;
}

Future<int> getClawbackDelay() async {
  print('\nYou and your counter party must agree on how much time you want to allow for the');
  print('exchange before it expires. It should be at least ten minutes');
  await Future<void>.delayed(const Duration(seconds: 3));
  print('\nWARNING: if you and your counter party input different times, the exchange will fail.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nIndicate your chosen expiry time in minutes or hit enter to default to 60 minutes.');
  while (true) {
    stdout.write('> ');
    final input = stdin.readLineSync()!.trim();
    if (input == '') {
      return 60;
    } else {
      try {
        final minutes = int.parse(input);
        if (minutes < 10) {
          print('\nMust be at least 10 minutes.');
        } else {
          return minutes;
        }
      } catch (e) {
        print('\nPlease enter a number.');
      }
    }
  }
}

Bytes getPaymentHash() {
  while (true) {
    stdout.write('> ');
    try {
      final paymentRequest = stdin.readLineSync()!.trim().toLowerCase();
      final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);
      final sweepPaymentHash = decodedPaymentRequest.tags.paymentHash;
      return sweepPaymentHash;
    } catch (e) {
      print("\nCouldn't validate the lightning payment request. Please try again:");
    }
  }
}

Puzzlehash getRequestorPuzzlehash() {
  while (true) {
    stdout.write('> ');
    try {
      final userAddress = stdin.readLineSync()!.trim().toLowerCase();
      final userPuzzlehash = Address(userAddress).toPuzzlehash();
      return userPuzzlehash;
    } catch (e) {
      print("\nCouldn't verify your address. Please try again:");
    }
  }
}

Future<void> generateSpendBundleFile(SpendBundle spendBundle) async {
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nGenerating file with spend bundle JSON in the current directory...');
  print('This is a last resort for you to use ONLY IF there is some problem with the');
  print('program closing before the transaction complete.');
  print('\nIn this case, you can use a command in the same format as shown here:');
  print('https://docs.chia.net/full-node-rpc/#push_tx');
  final spendBundleHexFile = File('spend_bundle_hex.txt').openWrite()..write(spendBundle.toJson());
  await spendBundleHexFile.flush();
  await spendBundleHexFile.close();
}

Future<void> confirmClawback({
  required SpendBundle clawbackSpendBundle,
  required int clawbackDelayMinutes,
  required List<Coin> chiaswapCoins,
  required Puzzlehash clawbackPuzzlehash,
  required ChiaFullNodeInterface fullNode,
}) async {
  print("\nIf $clawbackDelayMinutes minutes haven't passed, the spend bundle will be rejected.");
  print('Proceed? Y/N');

  var confirmation = '';
  while (!confirmation.startsWith('y')) {
    stdout.write('> ');
    confirmation = stdin.readLineSync()!.trim().toLowerCase();
    if (confirmation.toLowerCase().startsWith('y')) {
      print('\nPushing spend bundle to claw back XCH to your address...');

      await generateSpendBundleFile(clawbackSpendBundle);
      try {
        await fullNode.pushTransaction(clawbackSpendBundle);
        await verifyTransaction(chiaswapCoins, clawbackPuzzlehash, fullNode);
      } catch (e) {
        print('\nTRANSACTION FAILED. The spend bundle was rejected. If the clawback delay period');
        print("hasn't passed yet, keep waiting and manually push the transaction using the");
        print('generated file. If it has, your counter party may have already claimed funds.');
      }
    } else if (confirmation.startsWith('n')) {
      print(
        '\nOnce $clawbackDelayMinutes minutes have passed, you may reclaim the XCH either by responding',
      );
      print("with 'Y' here or by manually pushing the spend bundle using the");
      print('generated hex file.');
      await Future<void>.delayed(const Duration(seconds: 3));
      print(
        '\nHave $clawbackDelayMinutes minutes passed? If so, push spend bundle to claw back funds?',
      );
    } else {
      print('\nNot a valid choice.');
    }
  }
}

Future<void> verifyTransaction(
  List<Coin> chiaswapCoins,
  Puzzlehash requestorPuzzlehash,
  ChiaFullNodeInterface fullNode,
) async {
  final chiaswapCoinIds = chiaswapCoins.map((coin) => coin.id).toList();
  final removalIds = <Bytes>[];

  print('\nChecking mempool for coin spend...');

  while (chiaswapCoinIds.every(removalIds.contains)) {
    final mempoolItemsResponse = await fullNode.getAllMempoolItems();
    mempoolItemsResponse.mempoolItemMap.forEach((key, mempoolItem) {
      removalIds.addAll(mempoolItem.removals.map((removal) => removal.id));
    });
    await Future<void>.delayed(const Duration(seconds: 3));
  }

  print('\nYour transaction was validated and is now in the mempool.\n');

  var recipientParentIds = <Bytes>[];
  while (!chiaswapCoinIds.any((id) => recipientParentIds.contains(id))) {
    print('Waiting for transaction to complete...');
    await Future<void>.delayed(const Duration(seconds: 10));
    final recipientCoins = await fullNode.getCoinsByPuzzleHashes(
      [requestorPuzzlehash],
    );
    recipientParentIds = recipientCoins.map((coin) => coin.parentCoinInfo).toList();
  }

  print('\nSuccess! The transaction has been completed.');
}
