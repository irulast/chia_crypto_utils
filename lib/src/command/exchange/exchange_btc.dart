import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

final exchangeService = BtcExchangeService();
final xchToBtcService = XchToBtcService();
final btcToXchService = BtcToXchService();
File? logFile;
final logList = <String>[];

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

Future<File> getLogFile() async {
  // find any log files of previous exchange sessions
  final currentDirFiles = await Directory.current.list().toList();
  final logFileEntities = currentDirFiles
      .where((file) => File(file.path).uri.pathSegments.last.startsWith('exchange-log'))
      .toList();

  // if there aren't any, generate a new log file
  if (logFileEntities.isEmpty) {
    final logFilePath = 'exchange-log-${DateTime.now().toString().replaceAll(' ', '-')}.txt';
    File(logFilePath).createSync(recursive: true);
    return File(logFilePath);
  }

  // if there are, let user choose between initiating a new exchange or resuming a previous one
  final logFiles = <File>[];
  print('\nInitiate new exchange or resume previous exchange?');
  print('0. New exchange');
  for (var i = 0; i < logFileEntities.length; i++) {
    final file = File(logFileEntities[i].path);
    logFiles.add(file);
    print('${i + 1}. ${file.uri.pathSegments.last.replaceAll('.txt', '')}');
  }

  while (true) {
    stdout.write('> ');
    final choice = stdin.readLineSync()!.trim();
    if (choice == '0') {
      final logFilePath = 'exchange-log-${DateTime.now().toString().replaceAll(' ', '-')}.txt';
      File(logFilePath).createSync(recursive: true);
      return File(logFilePath);
    } else if (logFiles.asMap().containsKey(int.parse(choice) - 1)) {
      print('\nResuming previous exchange...');
      final logFile = logFiles[int.parse(choice) - 1];

      // convert selected log file to a list of variables
      logList.addAll(logFile.readAsStringSync().split('\n').toList());

      return logFiles[int.parse(choice) - 1];
    } else {
      print('Not a valid choice.');
    }
  }
}

Future<void> chooseExchangePath(ChiaFullNodeInterface fullNode) async {
  logFile = await getLogFile();

  if (logList.isNotEmpty) {
    if (logList[0] == '1') {
      await exchangeXchForBtc(fullNode);
    } else if (logList[0] == '2') {
      await exchangeBtcForXch(fullNode);
    }
  } else {
    print('\nDo you have XCH that you want to exchange for BTC, or do you have BTC that');
    print('you want to exchange for XCH? Please note that you and your counter party must');
    print('select reciprocal paths.');
    print('\n1. Exchange XCH for BTC');
    print('2. Exchange BTC for XCH');

    String? choice;

    while (choice != '1' && choice != '2') {
      stdout.write('> ');
      choice = stdin.readLineSync()!.trim();

      if (choice == '1') {
        await updateLogFile(choice);
        await exchangeXchForBtc(fullNode);
      } else if (choice == '2') {
        await updateLogFile(choice);
        await exchangeBtcForXch(fullNode);
      } else {
        print('\nNot a valid choice.');
      }
    }
  }
}

Future<void> exchangeXchForBtc(ChiaFullNodeInterface fullNode) async {
  // get disposable private key for user
  PrivateKey? xchHolderPrivateKey;
  if (logList.length > 1) {
    xchHolderPrivateKey = PrivateKey.fromHex(logList[1]);
  } else {
    xchHolderPrivateKey = await generateRequestorDisposableKeys();
  }

  // get BTC holder public key
  JacobianPoint? btcHolderPublicKey;
  if (logList.length > 2) {
    btcHolderPublicKey = JacobianPoint.fromHexG1(logList[2]);
  } else {
    btcHolderPublicKey = await getFulfillerPublicKey(xchHolderPrivateKey);
  }

  // get amounts being exchanged in terms of XCH, BTC, mojos, and satoshis
  Amounts? amounts;
  if (logList.length > 3) {
    final amountList = logList[3].split(',');
    amounts = Amounts(
      xch: double.parse(amountList[0]),
      btc: double.parse(amountList[1]),
      mojos: int.parse(amountList[2]),
      satoshis: int.parse(amountList[3]),
    );
  } else {
    amounts = await getAmounts();
  }

  // get clawback delay
  int? clawbackDelayMinutes;
  if (logList.length > 4) {
    clawbackDelayMinutes = int.parse(logList[4]);
  } else {
    clawbackDelayMinutes = await getClawbackDelay();
    await updateLogFile(clawbackDelayMinutes.toString());
  }
  final clawbackDelaySeconds = clawbackDelayMinutes * 60;

  // get lightning payment hash
  Bytes? sweepPaymentHash;
  if (logList.length > 5) {
    sweepPaymentHash = logList[5].hexToBytes();
  } else {
    print(
      '\nCreate a lightning payment request for ${(amounts.satoshis > 1) ? ((amounts.satoshis > 1000) ? '${amounts.btc.toStringAsFixed(5)} BTC' : '${amounts.satoshis} satoshis') : '1 satoshi'} with a timeout of $clawbackDelayMinutes minutes',
    );
    print('and send it to your counter party.');
    await Future<void>.delayed(const Duration(seconds: 2));
    print('\nPaste the lightning payment request here as well:');
    sweepPaymentHash = await getPaymentHash();
  }

  // get escrow puzzlehash
  Puzzlehash? escrowPuzzlehash;
  if (logList.length > 6) {
    escrowPuzzlehash = Puzzlehash.fromHex(logList[6]);
  } else {
    escrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: xchHolderPrivateKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      fulfillerPublicKey: btcHolderPublicKey,
    );
    await updateLogFile(escrowPuzzlehash.toHex());
  }
  final escrowAddress = escrowPuzzlehash.toAddressWithContext();

  // get puzzlehash where XCH holder will receive funds back in clawback case
  Puzzlehash? clawbackPuzzlehash;
  if (logList.length > 7) {
    clawbackPuzzlehash = Puzzlehash.fromHex(logList[7]);
  } else {
    print('\nEnter the address where the XCH will be returned in the event the exchange');
    print('is aborted or fails.');
    clawbackPuzzlehash = getRequestorPuzzlehash();
    await updateLogFile(clawbackPuzzlehash.toHex());
  }

  // get coins XCH holder has sent to escrow puzzlehash
  var escrowCoins = await fullNode.getCoinsByPuzzleHashes([escrowPuzzlehash]);
  if (escrowCoins.isEmpty) {
    print(
      '\nTransfer ${(amounts.mojos > 10000000) ? '${amounts.xch.toStringAsFixed(9)} XCH' : '${amounts.mojos} mojos or ${amounts.xch} XCH'} to the following escrow address:',
    );
    print(escrowAddress.address);
    await Future<void>.delayed(const Duration(seconds: 2));
    print('\nPress any key when the funds have been sent.');
    stdin.readLineSync();

    escrowCoins = await verifyTransferToEscrowPuzzlehash(
      amounts: amounts,
      escrowPuzzlehash: escrowPuzzlehash,
      fullNode: fullNode,
    );
  } else {
    print('\nYour XCH has arrived at the escrow address!');
  }

  // create spend bundle for clawing back funds if counter party doesn't pay lightning payment request
  final clawbackSpendBundle = xchToBtcService.createClawbackSpendBundle(
    payments: [Payment(escrowCoins.totalValue, clawbackPuzzlehash)],
    coinsInput: escrowCoins,
    requestorPrivateKey: xchHolderPrivateKey,
    clawbackDelaySeconds: clawbackDelaySeconds,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: btcHolderPublicKey,
  );

  print('\nWait for your counter party to pay the lightning payment request, then share');
  print('with them the disposable private key below to allow them to claim the XCH:');
  print(xchHolderPrivateKey.toHex());
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nPress any key to continue.');
  stdin.readLineSync();
  print('If the payment request is paid and you have shared your private key, you may');
  print('safely exit the program. The exchange is complete.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print(
    '\nIf your counter party does not pay the payment request within $clawbackDelayMinutes minutes,',
  );
  print('you may claw back the XCH to your address.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nAlternatively, if both parties agree to abort the exchange, you may receive');
  print('the XCH back sooner if your counter party provides their private key.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nSelect an option below.');
  print('1. The lightning payment request has been paid. Quit program.');
  print('2. $clawbackDelayMinutes minutes have passed. Claw back funds.');
  print('3. Exchange has been aborted or failed. Use counter party private key to');
  print('receive funds back early.');

  // determine how to conclude exchange based on user input
  stdout.write('> ');
  var choice = stdin.readLineSync()!.trim();

  while (choice != '1' && choice != '2' && choice != '3') {
    stdout.write('> ');
    choice = stdin.readLineSync()!.trim();
    print('\nNot a valid choice.');
  }

  PrivateKey? btcHolderPrivateKey;
  SpendBundle? clawbackSpendBundleWithPk;

  if (choice == '1') {
    exit(exitCode);
  } else if (choice == '2') {
    await confirmClawback(
      clawbackSpendBundle: clawbackSpendBundle,
      clawbackDelayMinutes: clawbackDelayMinutes,
      escrowCoins: escrowCoins,
      clawbackPuzzlehash: clawbackPuzzlehash,
      fullNode: fullNode,
    );
  } else if (choice == '3') {
    print("\nIf you haven't already received it, ask your counter party to share their");
    print('private key and paste it below.');

    var input = '';
    while (input != '2' && btcHolderPrivateKey == null) {
      stdout.write('> ');
      input = stdin.readLineSync()!.trim().toLowerCase();
      try {
        final privateKeyInput = PrivateKey.fromHex(input);

        if (privateKeyInput.getG1() == btcHolderPublicKey) {
          btcHolderPrivateKey = privateKeyInput;
          clawbackSpendBundleWithPk = xchToBtcService.createClawbackSpendBundleWithPk(
            payments: [Payment(escrowCoins.totalValue, clawbackPuzzlehash)],
            coinsInput: escrowCoins,
            requestorPrivateKey: xchHolderPrivateKey,
            clawbackDelaySeconds: clawbackDelaySeconds,
            sweepPaymentHash: sweepPaymentHash,
            fulfillerPrivateKey: btcHolderPrivateKey,
          );
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
          escrowCoins: escrowCoins,
          clawbackPuzzlehash: clawbackPuzzlehash,
          fullNode: fullNode,
        );
      }

      if (btcHolderPrivateKey != null) {
        print('\nPushing spend bundle to claw back XCH to your address...');
        await generateSpendBundleFile(clawbackSpendBundleWithPk!);
        await fullNode.pushTransaction(clawbackSpendBundleWithPk);
        await verifyTransaction(escrowCoins, clawbackPuzzlehash, fullNode);
      }
    }
  }
}

Future<void> exchangeBtcForXch(ChiaFullNodeInterface fullNode) async {
  // get disposable private key for user
  PrivateKey? btcHolderPrivateKey;
  if (logList.length > 1) {
    btcHolderPrivateKey = PrivateKey.fromHex(logList[1]);
  } else {
    btcHolderPrivateKey = await generateRequestorDisposableKeys();
  }

  // get XCH holder public key
  JacobianPoint? xchHolderPublicKey;
  if (logList.length > 2) {
    xchHolderPublicKey = JacobianPoint.fromHexG1(logList[2]);
  } else {
    xchHolderPublicKey = await getFulfillerPublicKey(btcHolderPrivateKey);
  }

  // get amounts being exchanged in terms of XCH, BTC, mojos, and satoshis
  Amounts? amounts;
  if (logList.length > 3) {
    final amountList = logList[3].split(',');
    amounts = Amounts(
      xch: double.parse(amountList[0]),
      btc: double.parse(amountList[1]),
      mojos: int.parse(amountList[2]),
      satoshis: int.parse(amountList[3]),
    );
  } else {
    amounts = await getAmounts();
  }

  // get clawback delay
  int? clawbackDelayMinutes;
  if (logList.length > 4) {
    clawbackDelayMinutes = int.parse(logList[4]);
  } else {
    clawbackDelayMinutes = await getClawbackDelay();
    await updateLogFile(clawbackDelayMinutes.toString());
  }
  final clawbackDelaySeconds = clawbackDelayMinutes * 60;

  // get lightning payment hash
  Bytes? sweepPaymentHash;
  if (logList.length > 5) {
    sweepPaymentHash = logList[5].hexToBytes();
  } else {
    print(
      '\nYour counter party will create a lightning payment request for ${(amounts.satoshis > 1) ? ((amounts.satoshis > 1000) ? '${amounts.btc.toStringAsFixed(5)} BTC' : '${amounts.satoshis} satoshis') : '1 satoshi'} with',
    );
    print('a timeout of $clawbackDelayMinutes minutes.');
    await Future<void>.delayed(const Duration(seconds: 2));
    print('\nPaste the lightning payment request from your counter party here:');
    sweepPaymentHash = await getPaymentHash();
  }

  // get escrow puzzlehash
  Puzzlehash? escrowPuzzlehash;
  if (logList.length > 6) {
    escrowPuzzlehash = Puzzlehash.fromHex(logList[6]);
  } else {
    escrowPuzzlehash = BtcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: btcHolderPrivateKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      fulfillerPublicKey: xchHolderPublicKey,
    );
    await updateLogFile(escrowPuzzlehash.toHex());
  }
  final escrowAddress = escrowPuzzlehash.toAddressWithContext();

  // get puzzlehash where BTC holder will receive XCH
  Puzzlehash? sweepPuzzlehash;
  if (logList.length > 7) {
    sweepPuzzlehash = Puzzlehash.fromHex(logList[7]);
  } else {
    print('\nEnter the address where you would like the XCH delivered.');
    sweepPuzzlehash = getRequestorPuzzlehash();
    await updateLogFile(sweepPuzzlehash.toHex());
  }

  // get coins XCH holder has sent to escrow puzzlehash
  var escrowCoins = await fullNode.getCoinsByPuzzleHashes([escrowPuzzlehash]);
  if (escrowCoins.isEmpty) {
    print(
      '\nYour counter party should be sending ${(amounts.mojos > 10000000) ? '${amounts.xch.toStringAsFixed(9)} XCH' : '${amounts.mojos} mojos or ${amounts.xch} XCH'} to an escrow',
    );
    print('address, where it will be temporarily held for you until the next step.');
    await Future<void>.delayed(const Duration(seconds: 1));
    print('\nPress any key to continue once your counter party lets you know that they have');
    print('sent the XCH.');
    stdin.readLineSync();

    escrowCoins = await verifyTransferToEscrowPuzzlehash(
      amounts: amounts,
      escrowPuzzlehash: escrowPuzzlehash,
      fullNode: fullNode,
      btcHolderPrivateKey: btcHolderPrivateKey,
    );
  } else {
    print('\nXCH from your counter party has arrived at the escrow address!');
  }

  print('\nYou can verify this here: https://xchscan.com/address/${escrowAddress.address}');
  print('\nPay the lightning payment request after the payment has received sufficient');
  print('confirmations.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print(
    '\nYou must pay and complete this exchange within $clawbackDelayMinutes minutes, or else the XCH will',
  );
  print('be returned to your counter party. If you wish to abort the exchange, do not');
  print('pay the lightning payment request.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print("\nTo claim funds, you will use either your counter party's private key or the");
  print('preimage that is revealed after payment of the lightning payment request.');
  print('If you have not already received it, ask your counter party to share their');
  print('disposable private key.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nIf your counter party is nonresponsive, find your lightning payment request');
  print('preimage by navigating to transaction history in your lightning wallet,');
  print('clicking on the transaction, and viewing the payment details.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print("\nPlease paste either your counter party's private key OR your preimage below.");
  print("If you instead want to abort the exchange, enter 'q' for instructions on how");
  print('on how to cleanly abort with your private key and then quit.');

  PrivateKey? xchHolderPrivateKey;
  Bytes? sweepPreimage;
  SpendBundle? sweepSpendBundle;
  var input = '';

  // determine how to conclude exchange based on user input
  while (xchHolderPrivateKey == null && sweepPreimage == null && !input.startsWith('q')) {
    stdout.write('> ');
    input = stdin.readLineSync()!.trim().toLowerCase();

    try {
      final inputAsPrivateKey = PrivateKey.fromHex(input);
      final inputAsPreimage = input.hexToBytes();

      if (inputAsPrivateKey.getG1() == xchHolderPublicKey) {
        xchHolderPrivateKey = inputAsPrivateKey;
        sweepSpendBundle = btcToXchService.createSweepSpendBundleWithPk(
          payments: [Payment(escrowCoins.totalValue, sweepPuzzlehash)],
          coinsInput: escrowCoins,
          requestorPrivateKey: btcHolderPrivateKey,
          clawbackDelaySeconds: clawbackDelaySeconds,
          sweepPaymentHash: sweepPaymentHash,
          fulfillerPrivateKey: xchHolderPrivateKey,
        );
      } else if (inputAsPreimage.sha256Hash() == sweepPaymentHash) {
        sweepPreimage = inputAsPreimage;

        sweepSpendBundle = btcToXchService.createSweepSpendBundle(
          payments: [Payment(escrowCoins.totalValue, sweepPuzzlehash)],
          coinsInput: escrowCoins,
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

  if (input.startsWith('q')) {
    print('\nPlease share your disposable private key below with your counter party to');
    print('allow them to cleanly reclaim their XCH from the escrow address:');
    print(btcHolderPrivateKey.toHex());
    await Future<void>.delayed(const Duration(seconds: 2));
    print('\nAfter you have done so, press any key to quit.');
    stdin.readLineSync();
    exit(exitCode);
  }

  print('\nPushing spend bundle to sweep XCH to your address...');
  await generateSpendBundleFile(sweepSpendBundle!);
  try {
    await fullNode.pushTransaction(sweepSpendBundle);
    await verifyTransaction(escrowCoins, sweepPuzzlehash, fullNode);
  } catch (e) {
    print('\nTRANSACTION FAILED. The spend bundle was rejected. You may have responded');
    print('after the agreed upon expiration time.');
  }
}

Future<void> updateLogFile(String input) async {
  if (logFile!.readAsStringSync().isEmpty) {
    await logFile!.writeAsString(input, mode: FileMode.append);
  } else {
    await logFile!.writeAsString('\n$input', mode: FileMode.append);
  }
}

Future<PrivateKey> generateRequestorDisposableKeys() async {
  // generate disposable private key and create signed public key for user
  final requestorPrivateKey = PrivateKey.generate();
  final requestorPublicKey = exchangeService.createSignedPublicKey(requestorPrivateKey);
  await updateLogFile(requestorPrivateKey.toHex());

  print('\nSend the following line with your signed public key to your counter party.');
  print(requestorPublicKey);
  await Future<void>.delayed(const Duration(seconds: 2));

  return requestorPrivateKey;
}

Future<JacobianPoint> getFulfillerPublicKey(PrivateKey requestorPrivateKey) async {
  // get and validate counter party public key as pasted by user
  print("\nPaste your counter party's signed public key below.");
  while (true) {
    stdout.write('> ');
    try {
      final fulfillerPublicKey =
          exchangeService.parseSignedPublicKey(stdin.readLineSync()!.trim().toLowerCase());
      if (fulfillerPublicKey == requestorPrivateKey.getG1()) {
        print("\nThat's your signed public key. Ask your counter party for theirs.");
      } else {
        await updateLogFile(fulfillerPublicKey.toHex());
        return fulfillerPublicKey;
      }
    } catch (e) {
      print('\nCould not verify signed public key. Please try again.');
    }
  }
}

Future<Amounts> getAmounts() async {
  // look up current XCH and BTC prices
  XchScanResponse? response;
  while (response == null) {
    response = await XchScan().getChiaPrice();
  }
  final btcPerXch = response.priceBtc;
  final xchPerBtc = 1 / btcPerXch;
  final usdPerXch = response.priceUsd;
  final usdPerBtc = usdPerXch / btcPerXch;

  print('\nThese are the current prices of XCH and BTC:');
  print('1 XCH = $btcPerXch BTC or ${usdPerXch.toStringAsFixed(2)} USD');
  print('1 BTC = ${xchPerBtc.toStringAsFixed(8)} XCH or ${usdPerBtc.toStringAsFixed(2)} USD');
  await Future<void>.delayed(const Duration(seconds: 1));

  // get amount being exchanged in terms of XCH or mojos, then calculate amount in other denomination
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
    print('\nHow much XCH is being exchanged? Please note that if you and your counter');
    print('party input different amounts, the exchange will fail.');
    while (xchAmount == null || xchAmount == 0) {
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
    print('\nHow many mojos are being exchanged? Please note that if you and your counter');
    print('party input different amounts, the exchange will fail.');
    while (xchAmountMojos == null || xchAmountMojos == 0) {
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

  // calculate amount being exchanged in terms of BTC and satoshis
  // if satoshi amount is 0, round up to 1
  final btcAmount = xchAmount! * btcPerXch;
  var btcAmountSatoshis = (btcAmount * 1e8).toInt();
  if (btcAmountSatoshis == 0) btcAmountSatoshis = 1;

  await updateLogFile('$xchAmount,$btcAmount,$xchAmountMojos,$btcAmountSatoshis');

  final amounts = Amounts(
    xch: xchAmount,
    btc: btcAmount,
    mojos: xchAmountMojos!,
    satoshis: btcAmountSatoshis,
  );

  return amounts;
}

Future<int> getClawbackDelay() async {
  // get clawback delay from user
  print('\nYou and your counter party must agree on how much time you want to allow for');
  print('the exchange before it expires. It should be at least 10 minutes. Please note');
  print('that if you and your counter party input different expiration times, the');
  print('exchange will fail.');
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nIndicate your chosen expiration time in minutes or hit enter to default to 60.');
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

Future<Bytes> getPaymentHash() async {
  // decode lightning payment request as pasted by user and get payment hash
  while (true) {
    stdout.write('> ');
    try {
      final paymentRequest = stdin.readLineSync()!.trim().toLowerCase();
      final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);
      final sweepPaymentHash = decodedPaymentRequest.tags.paymentHash;
      await updateLogFile(sweepPaymentHash!.toHex());
      return sweepPaymentHash;
    } catch (e) {
      print("\nCouldn't validate the lightning payment request. Please try again:");
    }
  }
}

Puzzlehash getRequestorPuzzlehash() {
  // get puzzlehash where user would like to receive XCH at
  while (true) {
    stdout.write('> ');
    try {
      final requestorAddress = stdin.readLineSync()!.trim().toLowerCase();
      final requestorPuzzlehash = Address(requestorAddress).toPuzzlehash();
      return requestorPuzzlehash;
    } catch (e) {
      print("\nCouldn't verify your address. Please try again:");
    }
  }
}

Future<void> generateSpendBundleFile(SpendBundle spendBundle) async {
  // generate json of spend bundle so user can manually push it if program fails
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\nGenerating file with spend bundle JSON in the current directory...');
  final spendBundleHexFile = File('spend-bundle-hex.txt').openWrite()..write(spendBundle.toJson());
  await spendBundleHexFile.flush();
  await spendBundleHexFile.close();
  print('This is a last resort for you to use ONLY IF the program closes prematurely');
  print('or if you need to reattempt pushing the spend bundle. In this case, you can');
  print('use a command in the same format as shown here:');
  print('https://docs.chia.net/full-node-rpc/#push_tx');
}

Future<void> confirmClawback({
  required SpendBundle clawbackSpendBundle,
  required int clawbackDelayMinutes,
  required List<Coin> escrowCoins,
  required Puzzlehash clawbackPuzzlehash,
  required ChiaFullNodeInterface fullNode,
}) async {
  // push clawback spend bundle after receiving confirmation from user

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
        await verifyTransaction(escrowCoins, clawbackPuzzlehash, fullNode);
      } catch (e) {
        print('\nTRANSACTION FAILED. The spend bundle was rejected. If the clawback delay');
        print("period hasn't passed yet, keep waiting and manually push the transaction");
        print('using the generated file. If it has, your counter party may have already');
        print('claimed funds from the escrow address.');
      }
    } else if (confirmation.startsWith('n')) {
      print(
        '\nOnce $clawbackDelayMinutes minutes have passed, you may reclaim the XCH either by responding',
      );
      print("with 'Y' here or by manually pushing the spend bundle using the");
      print('generated hex file.');
      await Future<void>.delayed(const Duration(seconds: 2));
      print(
        '\nHave $clawbackDelayMinutes minutes passed? If so, push spend bundle to claw back funds?',
      );
    } else {
      print('\nNot a valid choice.');
    }
  }
}

Future<List<Coin>> verifyTransferToEscrowPuzzlehash({
  required Amounts amounts,
  required Puzzlehash escrowPuzzlehash,
  required ChiaFullNodeInterface fullNode,
  PrivateKey? btcHolderPrivateKey,
}) async {
  // wait for XCH to arrive at the escrow address
  final additionPuzzlehashes = <Puzzlehash>[];
  var transactionValidated = false;
  var escrowCoins = <Coin>[];
  var i = 0;

  while (escrowCoins.totalValue < amounts.mojos) {
    if (transactionValidated == false) {
      print('Waiting for transfer to escrow address...');
    } else {
      print('Waiting for transaction to complete...');
    }
    await Future<void>.delayed(const Duration(seconds: 10));

    // if transaction hasn't been validated yet, keep checking mempool
    if (transactionValidated == false) {
      final mempoolItemsResponse = await fullNode.getAllMempoolItems();
      mempoolItemsResponse.mempoolItemMap.forEach((key, item) {
        additionPuzzlehashes.addAll(item.additions.map((addition) => addition.puzzlehash));
      });

      if (additionPuzzlehashes.contains(escrowPuzzlehash)) {
        print('\nThe transaction has been validated and is now in the mempool.\n');
        transactionValidated = true;
      }

      i++;

      if (i == 30) {
        i = 0;
        if (btcHolderPrivateKey != null) {
          // if BTC holder is still waiting, something might have gone wrong with transaction
          // give information to the user to allow them to cleanly abort the exchange
          print('\nStill waiting for a transaction sending XCH to the escrow address.');
          print('Ask your countery party whether their transaction is validated or complete');
          print("If it isn't, press any key to continue waiting.");
          await Future<void>.delayed(const Duration(seconds: 2));
          print('\nIf the transaction looks complete on their end, something might have gone');
          print("wrong. It's possible that one of the two parties inputted an incorrect value");
          print("or that your selected amounts to exchange or expiration times didn't match.");
          await Future<void>.delayed(const Duration(seconds: 2));
          print('\nIf this might be the case, please share your disposable private key below with');
          print('your counter party to abort the exchange and allow them to cleanly reclaim');
          print('their XCH from the escrow address:');
          print(btcHolderPrivateKey.toHex());
          await Future<void>.delayed(const Duration(seconds: 1));
          print('\nPress any key to keep waiting or exit the program using Ctrl+C and reattempt');
          print('the exchange by running the command again.');
          stdin.readLineSync();
        } else {
          // if XCH holder is still waiting, they might not have sent the correct amount to the
          // correct address
          print('\nStill waiting for a transaction sending XCH to the escrow address to be');
          print(
            'validated. Please double check that you sent ${(amounts.mojos > 10000000) ? '${amounts.xch.toStringAsFixed(9)} XCH' : '${amounts.mojos} mojos or ${amounts.xch} XCH'} to the',
          );
          print('following address:');
          print(escrowPuzzlehash.toAddressWithContext().address);
          print('\nPress any key to continue waiting after you have done so.');
          stdin.readLineSync();
        }
      }
    }

    escrowCoins = await fullNode.getCoinsByPuzzleHashes(
      [escrowPuzzlehash],
    );
  }

  print('\nThe escrow address has received sufficient XCH!');

  return escrowCoins;
}

Future<void> verifyTransaction(
  List<Coin> escrowCoins,
  Puzzlehash requestorPuzzlehash,
  ChiaFullNodeInterface fullNode,
) async {
  print('');

  // check mempool
  final escrowCoinIds = escrowCoins.map((coin) => coin.id).toList();
  final removalIds = <Bytes>[];

  while (!escrowCoinIds.every(removalIds.contains)) {
    print('Checking mempool for transaction...');
    await Future<void>.delayed(const Duration(seconds: 5));

    removalIds.clear();

    final mempoolItemsResponse = await fullNode.getAllMempoolItems();
    mempoolItemsResponse.mempoolItemMap.forEach((key, value) {
      removalIds.addAll(value.removals.map((removal) => removal.id));
    });
  }

  print('\nYour transaction was validated and is now in the mempool.\n');

  // verify receipt of XCH
  var recipientParentIds = <Bytes>[];
  while (!escrowCoinIds.any((id) => recipientParentIds.contains(id))) {
    print('Waiting for transaction to complete...');
    await Future<void>.delayed(const Duration(seconds: 10));

    final recipientCoins = await fullNode.getCoinsByPuzzleHashes(
      [requestorPuzzlehash],
    );

    recipientParentIds = recipientCoins.map((coin) => coin.parentCoinInfo).toList();
  }

  print('\nSuccess! The transaction is complete.');
}
