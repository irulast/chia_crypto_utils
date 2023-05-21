import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/command/exchange/exchange_btc.dart';

late final ChiaFullNodeInterface fullNode;
late final File logFile;
final xchToBtcService = XchToBtcService();
final btcToXchService = BtcToXchService();
final crossChainOfferService = CrossChainOfferFileService();
final standardWalletService = StandardWalletService();
final exchangeOfferWalletService = ExchangeOfferWalletService();
final exchangeOfferService = ExchangeOfferService(fullNode);

const fee = 50;

Future<void> makeCrossChainOffer(ChiaFullNodeInterface fullNodeFromUrl) async {
  fullNode = fullNodeFromUrl;

  final keychainCoreSecret = KeychainCoreSecret.generate();
  final keychain = WalletKeychain.fromCoreSecret(keychainCoreSecret);
  final masterPrivateKey = keychainCoreSecret.masterPrivateKey;
  final derivationIndex = ExchangeOfferService.randomDerivationIndexForExchange();

  final walletVector = await WalletVector.fromPrivateKeyAsync(masterPrivateKey, derivationIndex);

  final requestorPrivateKey = walletVector.childPrivateKey;
  final requestorPublicKey = requestorPrivateKey.getG1();

  final messagePuzzlehash = walletVector.puzzlehash;
  final messageAddress = messagePuzzlehash.toAddressWithContext();
  final requestorPuzzlehash = keychain.puzzlehashes.first;

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

  print('\nAre you offering XCH in exchange for BTC or BTC in exchange for XCH?');
  print('1. XCH in exchange for BTC');
  print('2. BTC in exchange for XCH');

  String? choice;
  ExchangeType? exchangeType;
  ExchangeAmountType? offeredAmountType;
  ExchangeAmountType? requestedAmountType;
  String? offeredDenomination;
  String? requestedDenomination;

  while (choice != '1' && choice != '2') {
    stdout.write('> ');
    choice = stdin.readLineSync()!.trim();

    if (choice == '1') {
      exchangeType = ExchangeType.xchToBtc;
      offeredAmountType = ExchangeAmountType.XCH;
      requestedAmountType = ExchangeAmountType.BTC;
      offeredDenomination = 'mojos';
      requestedDenomination = 'satoshis';
    } else if (choice == '2') {
      exchangeType = ExchangeType.btcToXch;
      offeredAmountType = ExchangeAmountType.BTC;
      requestedAmountType = ExchangeAmountType.XCH;
      offeredDenomination = 'satoshis';
      requestedDenomination = 'mojos';
    } else {
      print('\nNot a valid choice.');
    }
  }

  print(
    '\nHow much ${offeredAmountType!.name} are you offering in terms of $offeredDenomination?',
  );
  int? offeredAmountValue;
  while (offeredAmountValue == null) {
    stdout.write('> ');
    try {
      offeredAmountValue = int.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter how many $offeredDenomination being exchanged:');
    }
  }

  print(
    '\nHow much ${requestedAmountType!.name} are you requesting in exchange in terms of $requestedDenomination?',
  );
  int? requestedAmountValue;
  while (requestedAmountValue == null) {
    stdout.write('> ');
    try {
      requestedAmountValue = int.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter how many $requestedDenomination being exchanged:');
    }
  }

  print('\nEnter how long you want this offer to be valid for in hours:');
  int? validityTimeHours;
  while (validityTimeHours == null) {
    stdout.write('> ');
    try {
      validityTimeHours = int.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter the number of hours this offer will be valid for:');
    }
  }

  final currentUnixTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final validityTime = currentUnixTimeStamp + (validityTimeHours * 60 * 60);

  LightningPaymentRequest? requestorPaymentRequest;
  if (offeredAmountType == ExchangeAmountType.XCH) {
    print(
      '\nCreate a lightning payment request for $requestedAmountValue satoshis and paste it here:',
    );
    while (requestorPaymentRequest == null) {
      stdout.write('> ');
      try {
        final paymentRequestString = stdin.readLineSync()!.trim().toLowerCase();
        requestorPaymentRequest = decodeLightningPaymentRequest(paymentRequestString);
      } catch (e) {
        print("\nCouldn't validate the lightning payment request. Please try again:");
      }
    }
  }

  final mojos = exchangeType == ExchangeType.xchToBtc ? offeredAmountValue : requestedAmountValue;

  // ask for enough XCH for the exchange from user to cover initialization, message coin acceptance,
  // escrow transfer (in case of XCH holder), and clawback or sweep
  final amountToSend = 3 + (fee * 3) + (exchangeType == ExchangeType.xchToBtc ? mojos + fee : 0);
  final coinPuzzlehash = keychain.puzzlehashes.first;
  final coinAddress = Address.fromContext(coinPuzzlehash);

  logFile = await generateLogFile(
    mnemonicSeed: keychainCoreSecret.mnemonicString,
    requestorPrivateKey: requestorPrivateKey,
  );

  print(
    '\nPlease send ${amountToSend > mojoCutoff ? '${(amountToSend / mojosPerXch).toStringAsFixed(9)} XCH' : '$amountToSend mojos'} to the following address.',
  );
  print(
    'These funds will be used to cover the transactions that make up the exchange.',
  );
  print(
    'You can use the mnemonic found in the log file to claim any XCH leftover',
  );
  print('at the end of the exchange or if the program closes prematurely.');
  print(coinAddress.address);

  final sentCoins = await waitForUserToSendXch(coinPuzzlehash, amountToSend);

  final coinsForInitialization = selectCoinsForAmount(sentCoins, 3 + fee);

  final initializationCoinId = coinsForInitialization.first.id;

  late final MakerCrossChainOfferFile offerFile;
  switch (exchangeType!) {
    case ExchangeType.xchToBtc:
      offerFile = crossChainOfferService.createXchToBtcMakerOfferFile(
        initializationCoinId: initializationCoinId,
        amountMojos: offeredAmountValue,
        amountSatoshis: requestedAmountValue,
        messageAddress: messageAddress,
        validityTime: validityTime,
        requestorPublicKey: requestorPublicKey,
        paymentRequest: requestorPaymentRequest!,
      );
      break;
    case ExchangeType.btcToXch:
      offerFile = crossChainOfferService.createBtcToXchMakerOfferFile(
        initializationCoinId: initializationCoinId,
        amountMojos: requestedAmountValue,
        amountSatoshis: offeredAmountValue,
        messageAddress: messageAddress,
        validityTime: validityTime,
        requestorPublicKey: requestorPublicKey,
      );
      break;
  }

  final serializedOfferFile = offerFile.serialize(requestorPrivateKey);

  await writeToLogFile(
    logFile,
    'Maker Offer File',
    serializedOfferFile,
  );

  print('\nBelow is your serialized offer file.');
  print(serializedOfferFile);

  final initializationSpendBundle = exchangeOfferWalletService.createInitializationSpendBundle(
    messagePuzzlehash: messagePuzzlehash,
    coinsInput: coinsForInitialization,
    initializationCoinId: initializationCoinId,
    keychain: keychain,
    derivationIndex: derivationIndex,
    serializedOfferFile: serializedOfferFile,
    changePuzzlehash: requestorPuzzlehash,
    fee: 50,
  );

  await fullNode.pushTransaction(initializationSpendBundle);

  await writeToLogFile(
    logFile,
    'Initialization Spend Bundle',
    initializationSpendBundle.toJson().toString(),
  );

  await waitForTransactionToComplete(
    coinBeingSpentId: initializationCoinId,
    startMessage: 'Initializating offer...',
    waitingMessage: 'Waiting for initialization transaction to complete...',
    completionMessage: 'Offer initialized!',
  );

  print('\nSend serialized offer file to Dexie? Y/N');

  var confirmation = '';
  while (!confirmation.startsWith('y') && !confirmation.startsWith('n')) {
    stdout.write('> ');
    confirmation = stdin.readLineSync()!.trim().toLowerCase();
    if (confirmation.startsWith('y')) {
      final response = await DexieApi().postOffer(serializedOfferFile);
      if (response.success == true) {
        print('\nOffer has been successfully added to Dexie. Your offer ID is:');
        print(response.id);
      } else {
        print('Request failed. Please try again.');
        exit(exitCode);
      }
    } else if (confirmation.startsWith('n')) {
      continue;
    } else {
      print('\nNot a valid choice.');
    }
  }

  print('\nPress any key to start waiting for a message coin with a taker offer');
  print('file to arrive at the address you supplied.');
  stdin.readLineSync();

  var messageCoinAccepted = false;
  MessageCoinInfo? messageCoinInfo;
  final declinedMessageCoinIds = <Bytes>[];
  while (!messageCoinAccepted) {
    while (messageCoinInfo == null) {
      print('Waiting for message coin...');
      await Future<void>.delayed(const Duration(seconds: 10));
      messageCoinInfo = await exchangeOfferService.getNextValidMessageCoin(
        initializationCoinId: initializationCoinId,
        serializedOfferFile: serializedOfferFile,
        messagePuzzlehash: messagePuzzlehash,
        exchangeType: exchangeType,
        satoshis: exchangeType == ExchangeType.btcToXch ? offerFile.satoshis : null,
        declinedMessageCoinIds: declinedMessageCoinIds,
      );
    }

    final messageCoin = messageCoinInfo.messageCoin;
    final messageCoinChild = await fullNode.getSingleChildCoinFromCoin(messageCoin);
    final messageCoinChildId = messageCoinChild!.id;

    print('\nA message coin has arrived!');
    print('\nValidity time: ${messageCoinInfo.exchangeValidityTime}');
    print('\nPublic key: ${messageCoinInfo.fulfillerPublicKey.toHex()}');
    if (messageCoinInfo.lightningPaymentRequest != null) {
      print(
        '\nLightning Payment Request: ${messageCoinInfo.lightningPaymentRequest!.paymentRequest}',
      );
    }

    print(
      '\nAfter the message coin is accepted, the exchange must be completed within ${messageCoinInfo.exchangeValidityTime ~/ 60} minutes.',
    );
    print('Do you accept? Y/N');

    var messageCoinDecision = '';
    while (!messageCoinDecision.startsWith('y') && !messageCoinDecision.startsWith('n')) {
      stdout.write('> ');
      messageCoinDecision = stdin.readLineSync()!.trim().toLowerCase();
      if (messageCoinDecision.startsWith('y')) {
        final messageCoinAcceptanceSpendBundle =
            exchangeOfferWalletService.createMessageCoinAcceptanceSpendBundle(
          initializationCoinId: initializationCoinId,
          messageCoinChild: messageCoinChild,
          targetPuzzlehash: requestorPuzzlehash,
          walletVector: walletVector,
        );

        final unspentCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

        final feeSpendBundle = standardWalletService.createFeeSpendBundle(
          fee: fee,
          standardCoins: selectCoinsForAmount(unspentCoins, fee),
          keychain: keychain,
          changePuzzlehash: requestorPuzzlehash,
        );

        final totalMessageCoinAcceptanceSpendBundle =
            messageCoinAcceptanceSpendBundle + feeSpendBundle;

        await fullNode.pushTransaction(totalMessageCoinAcceptanceSpendBundle);

        await writeToLogFile(
          logFile,
          'Message Coin Acceptance Spend Bundle',
          totalMessageCoinAcceptanceSpendBundle.toJson().toString(),
        );

        await writeToLogFile(
          logFile,
          'Taker Offer File',
          messageCoinInfo!.serializedOfferAcceptFile,
        );

        await waitForTransactionToComplete(
          coinBeingSpentId: messageCoinChildId,
          startMessage: 'Accepting message coin...',
          waitingMessage: 'Waiting for acceptance transaction to complete...',
          completionMessage: 'Message coin acceptance transaction complete!',
        );
        messageCoinAccepted = true;
      } else if (messageCoinDecision.startsWith('n')) {
        final messageCoinDeclinationSpendBundle =
            exchangeOfferWalletService.createMessageCoinDeclinationSpendBundle(
          messageCoinChild: messageCoinChild,
          targetPuzzlehash: requestorPuzzlehash,
          walletVector: walletVector,
        );

        final unspentCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

        final feeSpendBundle = standardWalletService.createFeeSpendBundle(
          fee: fee,
          standardCoins: selectCoinsForAmount(unspentCoins, fee),
          keychain: keychain,
          changePuzzlehash: requestorPuzzlehash,
        );

        final totalMessageCoinDeclinationSpendBundle =
            messageCoinDeclinationSpendBundle + feeSpendBundle;

        await fullNode.pushTransaction(totalMessageCoinDeclinationSpendBundle);

        declinedMessageCoinIds.add(messageCoin.id);

        await waitForTransactionToComplete(
          coinBeingSpentId: messageCoinChildId,
          startMessage: 'Declining message coin...',
          waitingMessage: 'Waiting for declination transaction to complete...',
          completionMessage: 'Message coin declination transaction complete.',
        );

        print('');

        messageCoinInfo = null;
      } else {
        print('\nNot a valid choice.');
      }
    }
  }

  final exchangeValidityTime = messageCoinInfo!.exchangeValidityTime;
  final fulfillerPublicKey = messageCoinInfo.fulfillerPublicKey;

  final lightningPaymentRequest =
      (requestorPaymentRequest ?? messageCoinInfo.lightningPaymentRequest)!;

  final paymentHash = lightningPaymentRequest.paymentHash!;

  final escrowPuzzlehash = offerFile.getEscrowPuzzlehash(
    requestorPrivateKey: requestorPrivateKey,
    clawbackDelaySeconds: messageCoinInfo.exchangeValidityTime,
    sweepPaymentHash: lightningPaymentRequest.paymentHash!,
    fulfillerPublicKey: messageCoinInfo.fulfillerPublicKey,
  );

  switch (exchangeType) {
    case ExchangeType.xchToBtc:
      await completeXchToBtcExchange(
        mojos: mojos,
        exchangeValidityTime: exchangeValidityTime,
        escrowPuzzlehash: escrowPuzzlehash,
        initializationCoinId: initializationCoinId,
        paymentHash: paymentHash,
        fulfillerPublicKey: fulfillerPublicKey,
        requestorPrivateKey: requestorPrivateKey,
        requestorPuzzlehash: requestorPuzzlehash,
        keychain: keychain,
      );

      break;
    case ExchangeType.btcToXch:
      await completeBtcToXchExchange(
        mojos: mojos,
        exchangeValidityTime: exchangeValidityTime,
        escrowPuzzlehash: escrowPuzzlehash,
        initializationCoinId: initializationCoinId,
        lightningPaymentRequest: lightningPaymentRequest,
        fulfillerPublicKey: fulfillerPublicKey,
        requestorPrivateKey: requestorPrivateKey,
        requestorPuzzlehash: requestorPuzzlehash,
        keychain: keychain,
      );
      break;
  }
}

Future<void> takeCrossChainOffer(ChiaFullNodeInterface fullNodeFromUrl) async {
  fullNode = fullNodeFromUrl;

  final keychainCoreSecret = KeychainCoreSecret.generate();
  final keychain = WalletKeychain.fromCoreSecret(keychainCoreSecret);
  final masterPrivateKey = keychainCoreSecret.masterPrivateKey;
  final derivationIndex = Random.secure().nextInt(10);

  final walletVector = await WalletVector.fromPrivateKeyAsync(masterPrivateKey, derivationIndex);

  final requestorPrivateKey = walletVector.childPrivateKey;
  final requestorPublicKey = requestorPrivateKey.getG1();
  final requestorPuzzlehash = keychain.puzzlehashes.first;

  print('\nPaste in the serialized cross chain offer file you want to take:');
  String? serializedOfferFile;
  MakerCrossChainOfferFile? makerOfferFile;
  while (makerOfferFile == null) {
    stdout.write('> ');
    try {
      stdin.lineMode = false;
      serializedOfferFile = stdin.readLineSync()!.trim();
      stdin.lineMode = true;
      makerOfferFile = MakerCrossChainOfferFile.fromSerializedOfferFile(serializedOfferFile);
    } catch (e) {
      if (serializedOfferFile!.startsWith('ccoffer_accept')) {
        print(
          "Wrong offer file type. The prefix should be 'ccoffer,' not 'ccoffer_accept.'",
        );
        print('\nPlease enter a valid cross chain offer file:');
      } else {
        print('\nPlease enter a valid cross chain offer file:');
      }
    }
  }

  try {
    CrossChainOfferFileService.checkValidity(makerOfferFile);
  } catch (e) {
    print('\nThis cross chain offer has expired. Try again with a still valid offer.');
    exit(exitCode);
  }

  print('\nEnter how many minutes you want to allow for the exchange to complete before');
  print('it is aborted. Must be at least 60 minutes.');
  int? exchangeValidityTime;
  while (exchangeValidityTime == null || exchangeValidityTime < 3600) {
    stdout.write('> ');
    try {
      exchangeValidityTime = int.parse(stdin.readLineSync()!.trim()) * 60;
      if (exchangeValidityTime < 3600) {
        print('\nMust be at least 60 minutes.');
      }
    } catch (e) {
      print(
        '\nPlease enter a valid duration in terms of minutes:',
      );
    }
  }

  final messageAddress = makerOfferFile.messageAddress;
  final initializationCoinId = makerOfferFile.initializationCoinId;
  final fulfillerPublicKey = makerOfferFile.publicKey;
  final mojos = makerOfferFile.mojos;
  final satoshis = makerOfferFile.satoshis;

  TakerCrossChainOfferFile? takerOfferFile;
  ExchangeType exchangeType;
  LightningPaymentRequest? requestorPaymentRequest;
  if (makerOfferFile.exchangeType == ExchangeType.btcToXch) {
    print(
      '\nCreate a lightning payment request for $satoshis satoshis and paste it here:',
    );
    while (requestorPaymentRequest == null) {
      stdout.write('> ');
      try {
        final paymentRequestString = stdin.readLineSync()!.trim().toLowerCase();
        requestorPaymentRequest = decodeLightningPaymentRequest(paymentRequestString);
      } catch (e) {
        print("\nCouldn't validate the lightning payment request. Please try again:");
      }
    }

    exchangeType = ExchangeType.xchToBtc;
    takerOfferFile = crossChainOfferService.createXchToBtcTakerOfferFile(
      initializationCoinId: initializationCoinId,
      serializedMakerOfferFile: serializedOfferFile!,
      validityTime: exchangeValidityTime,
      requestorPublicKey: requestorPublicKey,
      paymentRequest: requestorPaymentRequest,
    );
  } else {
    exchangeType = ExchangeType.btcToXch;
    takerOfferFile = crossChainOfferService.createBtcToXchTakerOfferFile(
      initializationCoinId: initializationCoinId,
      serializedMakerOfferFile: serializedOfferFile!,
      validityTime: exchangeValidityTime,
      requestorPublicKey: requestorPublicKey,
    );
  }

  final serializedTakerOfferFile = takerOfferFile.serialize(requestorPrivateKey);

  logFile = await generateLogFile(
    mnemonicSeed: keychainCoreSecret.mnemonicString,
    requestorPrivateKey: requestorPrivateKey,
    serializedOfferFile: serializedOfferFile,
    serializedTakerOfferFile: serializedTakerOfferFile,
  );

  // ask for enough XCH for the exchange from user to cover message coin send, escrow transfer (in case of XCH holder)
  // and clawback OR sweep
  final amountToSend = minimumNotificationCoinAmount +
      (fee * 2) +
      (exchangeType == ExchangeType.xchToBtc ? makerOfferFile.mojos + fee : 0);
  final coinPuzzlehash = keychain.puzzlehashes.first;
  final coinAddress = Address.fromContext(coinPuzzlehash);
  final messagePuzzlehash = messageAddress.toPuzzlehash();

  print(
    '\nPlease send ${amountToSend > mojoCutoff ? '${(amountToSend / mojosPerXch).toStringAsFixed(9)} XCH' : '$amountToSend mojos'} to the following address.',
  );
  print(
    'These funds will be used to cover the transactions that make up the exchange.',
  );
  print(
    'You can use the mnemonic found in the log file to claim any XCH leftover',
  );
  print('at the end of the exchange or if the program closes prematurely.');
  print(coinAddress.address);

  final sentCoins = await waitForUserToSendXch(coinPuzzlehash, amountToSend);

  final messageSpendBundle = exchangeOfferWalletService.createMessageSpendBundle(
    messagePuzzlehash: messagePuzzlehash,
    coinsInput: selectCoinsForAmount(sentCoins, minimumNotificationCoinAmount),
    keychain: keychain,
    serializedTakerOfferFile: serializedTakerOfferFile,
    initializationCoinId: initializationCoinId,
    fee: 50,
    changePuzzlehash: requestorPuzzlehash,
  );

  await fullNode.pushTransaction(messageSpendBundle);

  await writeToLogFile(
    logFile,
    'Message Spend Bundle',
    messageSpendBundle.toJson().toString(),
  );

  final messageCoinId = messageSpendBundle.coinSpends
      .where(
        (coinSpend) => coinSpend.puzzleReveal.uncurry().mod == notificationProgram,
      )
      .single
      .coin
      .id;

  await waitForTransactionToComplete(
    coinBeingSpentId: messageCoinId,
    startMessage: 'Sending message coin to maker...',
    waitingMessage: 'Waiting for transaction to complete...',
    completionMessage: 'Your message coin has arrived!',
  );

  final messageCoin = await fullNode.getCoinById(messageCoinId);
  final messageCoinChild = await fullNode.getSingleChildCoinFromCoin(messageCoin!);

  print('\nPress any key to start waiting for maker to accept or decline your message coin');
  stdin.readLineSync();

  await waitForMakerToSpendMessageCoinChild(
    messageCoinChildId: messageCoinChild!.id,
    initializationCoinId: initializationCoinId,
  );

  final lightningPaymentRequest =
      (requestorPaymentRequest ?? makerOfferFile.lightningPaymentRequest)!;

  final paymentHash = lightningPaymentRequest.paymentHash;

  final escrowPuzzlehash = takerOfferFile.getEscrowPuzzlehash(
    requestorPrivateKey: requestorPrivateKey,
    clawbackDelaySeconds: exchangeValidityTime,
    sweepPaymentHash: paymentHash!,
    fulfillerPublicKey: fulfillerPublicKey,
  );

  switch (exchangeType) {
    case ExchangeType.xchToBtc:
      await completeXchToBtcExchange(
        mojos: mojos,
        exchangeValidityTime: exchangeValidityTime,
        escrowPuzzlehash: escrowPuzzlehash,
        initializationCoinId: initializationCoinId,
        paymentHash: paymentHash,
        fulfillerPublicKey: fulfillerPublicKey,
        requestorPrivateKey: requestorPrivateKey,
        requestorPuzzlehash: requestorPuzzlehash,
        keychain: keychain,
      );

      break;
    case ExchangeType.btcToXch:
      await completeBtcToXchExchange(
          mojos: mojos,
          exchangeValidityTime: exchangeValidityTime,
          escrowPuzzlehash: escrowPuzzlehash,
          initializationCoinId: initializationCoinId,
          lightningPaymentRequest: lightningPaymentRequest,
          fulfillerPublicKey: fulfillerPublicKey,
          requestorPuzzlehash: requestorPuzzlehash,
          requestorPrivateKey: requestorPrivateKey,
          keychain: keychain);
      break;
  }
}

Future<List<Coin>> waitForEscrowCoins({
  required int amount,
  required Puzzlehash escrowPuzzlehash,
  required String waitingMessage,
}) async {
  // wait for XCH to arrive at the escrow address
  var transactionValidated = false;
  var escrowCoins = <Coin>[];

  while (escrowCoins.totalValue < amount) {
    if (transactionValidated == false) {
      print(waitingMessage);
    } else {
      print('Waiting for transaction to complete...');
    }
    await Future<void>.delayed(const Duration(seconds: 10));

    if (transactionValidated == false) {
      transactionValidated = await isTransactionValidated(escrowPuzzlehash, amount);
    }

    escrowCoins = await fullNode.getCoinsByPuzzleHashes(
      [escrowPuzzlehash],
    );
  }

  print('\nThe escrow address has received sufficient XCH!');

  final parentCoin = await fullNode.getCoinById(escrowCoins.first.parentCoinInfo);
  final sufficientConfirmationsHeight = parentCoin!.spentBlockIndex + 32;

  print(
    '\nWaiting 32 blocks for escrow transfer confirmation (until block ${parentCoin.spentBlockIndex}).\n',
  );

  while (true) {
    await Future<void>.delayed(const Duration(seconds: 30));

    final currentHeight = await fullNode.getCurrentBlockIndex();

    if (currentHeight != null) {
      if (currentHeight >= sufficientConfirmationsHeight) {
        print('\nEscrow transfer confirmed!');
        return escrowCoins;
      }
      print('${sufficientConfirmationsHeight - currentHeight} blocks remaining...');
    }
  }
}

Future<void> completeBtcToXchExchange({
  required int mojos,
  required int exchangeValidityTime,
  required Puzzlehash escrowPuzzlehash,
  required Bytes initializationCoinId,
  required LightningPaymentRequest lightningPaymentRequest,
  required JacobianPoint fulfillerPublicKey,
  required PrivateKey requestorPrivateKey,
  required Puzzlehash requestorPuzzlehash,
  required WalletKeychain keychain,
}) async {
  print('\nYour counter party will send $mojos mojos to the following escrow address:');
  print(Address.fromContext(escrowPuzzlehash).address);
  print('\nPress any key to start waiting for the XCH from your counter party.');
  stdin.readLineSync();

  final escrowCoins = await waitForEscrowCoins(
    amount: mojos,
    escrowPuzzlehash: escrowPuzzlehash,
    waitingMessage: 'Waiting for escrow transfer...',
  );

  print('\nPlease paste the following lightning invoice into your BTC wallet and pay it.');
  print('Note that you must use a wallet that supports preimage reveal, such as Muun.');
  print(lightningPaymentRequest.paymentRequest);
  print('\nAfter you have done so, you can find your lightning payment request');
  print('preimage by navigating to transaction history in your lightning wallet,');
  print('clicking on the transaction, and viewing the payment details.');
  print('\nPaste in the preimage below.');

  final paymentHash = lightningPaymentRequest.paymentHash;

  Bytes? preimage;
  while (preimage == null) {
    stdout.write('> ');
    final preimageInput = stdin.readLineSync()!.trim().toLowerCase();

    try {
      if (preimageInput.hexToBytes().sha256Hash() == paymentHash) {
        preimage = preimageInput.hexToBytes();
      } else {
        print("\nCouldn't verify input as preimage. Please try again.");
      }
    } catch (e) {
      LoggingContext().error(e.toString());
    }
  }

  print('\nPlease enter the address where you want the XCH to be swept to:');
  final sweepPuzzlehash = getUserPuzzlehash();

  final sweepSpendBundle = exchangeOfferWalletService.createSweepSpendBundle(
    initializationCoinId: initializationCoinId,
    escrowCoins: escrowCoins,
    requestorPuzzlehash: sweepPuzzlehash,
    requestorPrivateKey: requestorPrivateKey,
    exchangeValidityTime: exchangeValidityTime,
    paymentHash: paymentHash!,
    preimage: preimage,
    fulfillerPublicKey: fulfillerPublicKey,
  );

  final unspentCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

  final feeSpendBundle = standardWalletService.createFeeSpendBundle(
    fee: fee,
    standardCoins: selectCoinsForAmount(unspentCoins, fee),
    keychain: keychain,
    changePuzzlehash: requestorPuzzlehash,
  );

  final totalSweepSpendBundle = sweepSpendBundle + feeSpendBundle;

  await writeToLogFile(logFile, 'Sweep Spend Bundle', totalSweepSpendBundle.toJson().toString());

  try {
    await fullNode.pushTransaction(totalSweepSpendBundle);
  } catch (e) {
    print('\nTRANSACTION FAILED. The spend bundle was rejected. You may have responded');
    print('too late.');
  }

  await waitForTransactionToComplete(
    coinBeingSpentId: escrowCoins.first.id,
    startMessage: 'Sweeping escrow address...',
    waitingMessage: 'Waiting for sweep transaction to complete...',
    completionMessage: 'XCH swept to your address. Exchange complete.',
  );
}

Future<void> completeXchToBtcExchange({
  required int mojos,
  required int exchangeValidityTime,
  required Puzzlehash escrowPuzzlehash,
  required Bytes initializationCoinId,
  required Bytes paymentHash,
  required JacobianPoint fulfillerPublicKey,
  required PrivateKey requestorPrivateKey,
  required Puzzlehash requestorPuzzlehash,
  required WalletKeychain keychain,
}) async {
  print(
    '\nThe program will send the amount of XCH being exchanged to the escrow address,',
  );
  print('where it will be held until your counterparty pays the lightning invoice.');
  print('Press any key to proceed.');
  stdin.readLineSync();

  var unspentCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

  final escrowTransferSpendBundle = exchangeOfferWalletService.createEscrowTransferSpendBundle(
    initializationCoinId: initializationCoinId,
    mojos: mojos,
    escrowPuzzlehash: escrowPuzzlehash,
    coinsInput: selectCoinsForAmount(unspentCoins, mojos + fee),
    keychain: keychain,
    requestorPrivateKey: requestorPrivateKey,
    fee: fee,
    changePuzzlehash: requestorPuzzlehash,
  );

  await fullNode.pushTransaction(escrowTransferSpendBundle);

  await writeToLogFile(
    logFile,
    'Escrow Transfer Spend Bundle',
    escrowTransferSpendBundle.toJson().toString(),
  );

  print('Transfering XCH to escrow address...\n');

  final escrowCoins = await waitForEscrowCoins(
    amount: mojos,
    escrowPuzzlehash: escrowPuzzlehash,
    waitingMessage: 'Waiting for transaction to complete...',
  );

  print('\nEnter the address where the XCH will be returned in the event the exchange');
  print('is aborted or fails:');
  final clawbackPuzzlehash = getUserPuzzlehash();

  final clawbackSpendBundle = exchangeOfferWalletService.createClawbackSpendBundle(
    initializationCoinId: paymentHash,
    escrowCoins: escrowCoins,
    requestorPuzzlehash: clawbackPuzzlehash,
    requestorPrivateKey: requestorPrivateKey,
    exchangeValidityTime: exchangeValidityTime,
    paymentHash: paymentHash,
    fulfillerPublicKey: fulfillerPublicKey,
  );

  unspentCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

  final feeSpendBundle = standardWalletService.createFeeSpendBundle(
    fee: fee,
    standardCoins: selectCoinsForAmount(unspentCoins, fee),
    keychain: keychain,
    changePuzzlehash: requestorPuzzlehash,
  );

  final totalClawbackSpendBundle = clawbackSpendBundle + feeSpendBundle;

  await writeToLogFile(
    logFile,
    'Clawback Spend Bundle',
    totalClawbackSpendBundle.toJson().toString(),
  );

  final validityTimeMinutes = exchangeValidityTime ~/ 60;

  print('\nOnce your counter party has paid the lightning invoice you may safely exit the');
  print('program. The exchange complete.');

  print('\nIf your counter party does not pay the lightning invoice, you may claw back');
  print('your XCH after $validityTimeMinutes minutes.');

  print("\nIf $validityTimeMinutes minutes haven't passed, the spend bundle will be rejected.");
  print('Proceed? Y/N');

  var confirmation = '';
  while (!confirmation.startsWith('y')) {
    stdout.write('> ');
    confirmation = stdin.readLineSync()!.trim().toLowerCase();
    if (confirmation.toLowerCase().startsWith('y')) {
      try {
        await fullNode.pushTransaction(totalClawbackSpendBundle);
      } catch (e) {
        print('\nTRANSACTION FAILED. The spend bundle was rejected. If the clawback delay');
        print("period hasn't passed yet, keep waiting and manually push the transaction");
        print(
          'using spend bundle in log file with the following command:',
        );
        print('https://docs.chia.net/full-node-rpc/#push_tx');
        print(
          'If it has, your counterparty may have already claimed funds from the escrow address.',
        );
      }
    } else if (confirmation.startsWith('n')) {
      print(
        '\nOnce $validityTimeMinutes minutes have passed, you may reclaim the XCH either by responding',
      );
      print(
        "with 'Y' here or by manually pushing the spend bundle using the spend bundle found in",
      );
      print('the log file.');
      await Future<void>.delayed(const Duration(seconds: 2));
      print(
        '\nHave $validityTimeMinutes minutes passed? If so, push spend bundle to claw back funds?',
      );
    } else {
      print('\nNot a valid choice.');
    }
  }

  await waitForTransactionToComplete(
    coinBeingSpentId: escrowCoins.first.id,
    startMessage: 'Clawing back XCH from escrow address...',
    waitingMessage: 'Waiting for clawback to complete...',
    completionMessage: 'XCH has been clawed back. Exchange successfully aborted.',
  );
}

Future<File> generateLogFile({
  required String mnemonicSeed,
  required PrivateKey requestorPrivateKey,
  String? serializedOfferFile,
  String? serializedTakerOfferFile,
}) async {
  print('\nGenerating log file...');

  final logFile = File('exchange-log-${DateTime.now().toString().replaceAll(' ', '-')}.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync('Mnemonic Seed:\n$mnemonicSeed', mode: FileMode.append)
    ..writeAsStringSync(
      '\n\nPrivate Key:\n${requestorPrivateKey.toHex()}',
      mode: FileMode.append,
    );

  if (serializedOfferFile != null && serializedTakerOfferFile != null) {
    logFile
      ..writeAsStringSync('\n\nOffer File:\n$serializedOfferFile', mode: FileMode.append)
      ..writeAsStringSync(
        '\n\nTaker Offer File:\n$serializedTakerOfferFile',
        mode: FileMode.append,
      );
  }

  return logFile;
}

Future<void> writeToLogFile(File logFile, String label, String content) async {
  await logFile.writeAsString('\n\n$label:\n$content', mode: FileMode.append);
}

Future<List<Coin>> waitForUserToSendXch(Puzzlehash targetPuzzlehash, int amount) async {
  print('\nPress any key to continue once you have done so.');
  stdin.readLineSync();

  var transactionValidated = false;
  var coins = <Coin>[];

  while (coins.totalValue < amount) {
    print('Waiting for XCH...');
    await Future<void>.delayed(const Duration(seconds: 10));

    if (transactionValidated == false) {
      transactionValidated = await isTransactionValidated(targetPuzzlehash, amount);
    }

    coins = await fullNode.getCoinsByPuzzleHashes(
      [targetPuzzlehash],
    );
  }

  print('\nXCH received!');

  return coins;
}

Future<bool> isTransactionValidated(Puzzlehash targetPuzzlehash, int amount) async {
  final mempoolItemsResponse = await fullNode.getAllMempoolItems();
  final mempoolItems = mempoolItemsResponse.mempoolItemMap.values;

  for (final mempoolItem in mempoolItems) {
    for (final addition in mempoolItem.additions) {
      if (addition.puzzlehash == targetPuzzlehash && addition.amount == amount) {
        print('\nThe transaction has been validated and is now in the mempool.\n');
        return true;
      }
    }
  }
  return false;
}

Future<bool> isTransactionValidatedFromSpentCoinId(Bytes spentCoinId) async {
  final mempoolItemsResponse = await fullNode.getAllMempoolItems();
  final mempoolItems = mempoolItemsResponse.mempoolItemMap.values;

  for (final mempoolItem in mempoolItems) {
    for (final coinSpend in mempoolItem.spendBundle.coinSpends) {
      if (coinSpend.coin.id == spentCoinId) {
        print('\nThe transaction has been validated and is now in the mempool.\n');
        return true;
      }
    }
  }
  return false;
}

Future<void> waitForTransactionToComplete({
  required Bytes coinBeingSpentId,
  required String startMessage,
  required String waitingMessage,
  required String completionMessage,
}) async {
  var transactionValidated = false;

  print('\n$startMessage\n');

  while (true) {
    print(waitingMessage);
    await Future<void>.delayed(const Duration(seconds: 10));
    final coinBeingSpent = await fullNode.getCoinById(coinBeingSpentId);

    if (coinBeingSpent == null) continue;

    if (transactionValidated == false) {
      transactionValidated = await isTransactionValidatedFromSpentCoinId(coinBeingSpentId);
    }

    if (coinBeingSpent.isSpent) {
      print('\n$completionMessage');
      return;
    }
  }
}

Future<void> waitForMakerToSpendMessageCoinChild({
  required Bytes messageCoinChildId,
  required Bytes initializationCoinId,
}) async {
  var transactionValidated = false;

  while (true) {
    print('Waiting for maker to accept or decline message coin...');
    await Future<void>.delayed(const Duration(seconds: 10));
    final messageCoinChild = await fullNode.getCoinById(messageCoinChildId);

    if (transactionValidated == false) {
      transactionValidated = await isTransactionValidatedFromSpentCoinId(messageCoinChildId);
    }

    if (messageCoinChild!.isSpent) {
      final coinSpend = await fullNode.getCoinSpend(messageCoinChild);
      final memos = await coinSpend!.memos;

      if (memos.contains(initializationCoinId)) {
        print('\nMaker accepted message coin!');
        return;
      } else {
        print('\nMaker declined message coin. The exchange will not proceed.');
        exit(exitCode);
      }
    }
  }
}
