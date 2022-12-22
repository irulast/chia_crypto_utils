import 'dart:async';
import 'dart:io';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/command/exchange/exchange_btc.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/dexie/dexie_offers.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/utils/cross_chain_offer_file_serialization.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/btc_to_xch.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/xch_to_btc.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';

final xchToBtcService = XchToBtcService();
final btcToXchService = BtcToXchService();
final standardWalletService = StandardWalletService();

Future<void> makeCrossChainOffer(ChiaFullNodeInterface fullNode) async {
  final requestorPrivateKey = PrivateKey.generate();
  final requestorPublicKey = requestorPrivateKey.getG1();

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
  print('\n1. XCH in exchange for BTC');
  print('2. BTC in exchange for XCH');

  String? choice;
  ExchangeAmountType? offeredAmountType;
  ExchangeAmountType? requestedAmountType;
  String? offeredDenomination;
  String? requestedDenomination;

  while (choice != '1' && choice != '2') {
    stdout.write('> ');
    choice = stdin.readLineSync()!.trim();

    if (choice == '1') {
      offeredAmountType = ExchangeAmountType.XCH;
      requestedAmountType = ExchangeAmountType.BTC;
      offeredDenomination = 'mojos';
      requestedDenomination = 'satoshis';
    } else if (choice == '2') {
      offeredAmountType = ExchangeAmountType.BTC;
      requestedAmountType = ExchangeAmountType.XCH;
      offeredDenomination = 'satoshis';
      requestedDenomination = 'satoshis';
    } else {
      print('\nNot a valid choice.');
    }
  }

  print(
    '\nHow much ${offeredAmountType!.name} are you offering in terms of $offeredDenomination?',
  );
  int? offeredAmountInput;
  while (offeredAmountInput == null) {
    stdout.write('> ');
    try {
      offeredAmountInput = int.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter the amount of ${offeredAmountType.name} being exchanged:');
    }
  }

  double? offeredAmountValue;
  if (offeredDenomination == 'mojos') {
    offeredAmountValue = offeredAmountInput / 1e12;
  } else {
    offeredAmountValue = offeredAmountInput / 1e8;
  }

  print(
    '\nHow much ${requestedAmountType!.name} are you requesting in exchange in terms of $requestedDenomination?',
  );
  int? requestedAmountInput;
  while (requestedAmountInput == null) {
    stdout.write('> ');
    try {
      requestedAmountInput = int.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter the amount of ${requestedAmountType.name} being exchanged:');
    }
  }

  double? requestedAmountValue;
  if (requestedDenomination == 'mojos') {
    requestedAmountValue = requestedAmountInput / 1e12;
  } else {
    requestedAmountValue = requestedAmountInput / 1e8;
  }

  print('\nEnter an XCH address for interested parties to send message coins to.');
  Address? messageAddress;
  while (messageAddress == null) {
    stdout.write('> ');
    try {
      messageAddress = Address(stdin.readLineSync()!.trim().toLowerCase());
    } catch (e) {
      print("\nCouldn't verify your address. Please try again:");
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
  final validityTime = currentUnixTimeStamp + (validityTimeHours * 60);

  CrossChainOfferFile? offerFile;

  if (requestedAmountType == ExchangeAmountType.BTC) {
    print(
        '\nCreate a lightning payment request for $requestedAmountInput satoshis and paste it here:');
    LightningPaymentRequest? paymentRequest;
    while (paymentRequest == null) {
      stdout.write('> ');
      try {
        final paymentRequestString = stdin.readLineSync()!.trim().toLowerCase();
        paymentRequest = decodeLightningPaymentRequest(paymentRequestString);
      } catch (e) {
        print("\nCouldn't validate the lightning payment request. Please try again:");
      }
    }

    offerFile = XchToBtcOfferFile(
      offeredAmount: ExchangeAmount(type: offeredAmountType, amount: offeredAmountValue),
      requestedAmount: ExchangeAmount(type: requestedAmountType, amount: requestedAmountValue),
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: requestorPublicKey,
      lightningPaymentRequest: paymentRequest,
    );
  } else {
    offerFile = BtcToXchOfferFile(
      offeredAmount: ExchangeAmount(type: offeredAmountType, amount: offeredAmountValue),
      requestedAmount: ExchangeAmount(type: requestedAmountType, amount: requestedAmountValue),
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: requestorPublicKey,
    );
  }

  final serializedOfferFile = serializeCrossChainOfferFile(offerFile, requestorPrivateKey);

  print('\nBelow is your serialized offer file.');
  print(serializedOfferFile);

  await generateLogFile(requestorPrivateKey, serializedOfferFile);

  // print('\nSend serialized offer file to dexie? Y/N');

  // var confirmation = '';
  // while (!confirmation.startsWith('y') && !confirmation.startsWith('n')) {
  //   stdout.write('> ');
  //   confirmation = stdin.readLineSync()!.trim().toLowerCase();
  //   if (confirmation.startsWith('y')) {
  //     // post request to dexie
  //   } else if (confirmation.startsWith('n')) {
  //     continue;
  //   } else {
  //     print('\nNot a valid choice.');
  //   }
  // }
  print('\nPress any key to start waiting for message coin to arrive.');
  stdin.readLineSync();

  final serializedOfferAcceptFile =
      await waitForMessageCoin(messageAddress.toPuzzlehash(), fullNode);
  var deserializedOfferAcceptFile = deserializeCrossChainOfferFile(serializedOfferAcceptFile);

  if (offerFile.type == CrossChainOfferFileType.xchToBtc) {
    offerFile = offerFile as XchToBtcOfferFile;
    deserializedOfferAcceptFile = deserializedOfferAcceptFile as BtcToXchOfferAcceptFile;

    await completeXchToBtcExchange(
      amountXch: offeredAmountValue,
      requestorPrivateKey: requestorPrivateKey,
      validityTime: deserializedOfferAcceptFile.validityTime,
      paymentRequest: offerFile.lightningPaymentRequest,
      fulfillerPublicKey: deserializedOfferAcceptFile.publicKey,
      fullNode: fullNode,
    );
  } else {
    offerFile = offerFile as BtcToXchOfferFile;
    deserializedOfferAcceptFile = deserializedOfferAcceptFile as XchToBtcOfferAcceptFile;

    await completeBtcToXchExchange(
      amountXch: requestedAmountValue,
      requestorPrivateKey: requestorPrivateKey,
      validityTime: deserializedOfferAcceptFile.validityTime,
      paymentRequest: deserializedOfferAcceptFile.lightningPaymentRequest,
      fulfillerPublicKey: deserializedOfferAcceptFile.publicKey,
      fullNode: fullNode,
    );
  }
}

Future<void> acceptCrossChainOffer(ChiaFullNodeInterface fullNode) async {
  final requestorPrivateKey = PrivateKey.generate();
  final requestorPublicKey = requestorPrivateKey.getG1();

  print('\nPaste in the serialized cross chain offer file you want to accept:');
  String? offerFile;
  CrossChainOfferFile? deserializedOfferFile;
  while (deserializedOfferFile == null) {
    stdout.write('> ');
    try {
      stdin.lineMode = false;
      offerFile = stdin.readLineSync()!.trim();
      stdin.lineMode = true;
      deserializedOfferFile = deserializeCrossChainOfferFile(offerFile);
      if (deserializedOfferFile.prefix.name == 'ccoffer_accept') {
        print(
          "Wrong offer file type. The prefix should be 'ccoffer,' not 'ccoffer_accept.'",
        );
        deserializedOfferFile = null;
      }
    } catch (e) {
      print('\nPlease enter a valid cross chain offer file:');
    }
  }

  if (deserializedOfferFile.validityTime < (DateTime.now().millisecondsSinceEpoch / 1000)) {
    print('\nThis cross chain offer has expired. Try again with a still valid offer.');
    exit(exitCode);
  }

  print('\nEnter how long you want to allow for the exchange to complete before it is');
  print('aborted in terms of minutes.');
  int? validityTime;
  while (validityTime == null) {
    stdout.write('> ');
    try {
      validityTime = int.parse(stdin.readLineSync()!.trim()) * 60;
    } catch (e) {
      print(
        '\nPlease enter a valid duration in terms of minutes:',
      );
    }
  }

  CrossChainOfferFile? offerAcceptFile;
  Address? messageAddress;

  if (deserializedOfferFile.type == CrossChainOfferFileType.btcToXch) {
    deserializedOfferFile = deserializedOfferFile as BtcToXchOfferFile;

    messageAddress = deserializedOfferFile.messageAddress;

    print(
      '\nCreate a lightning payment request for ${deserializedOfferFile.offeredAmount.amount * 1e8} satoshis and paste it here:',
    );
    LightningPaymentRequest? paymentRequest;
    while (paymentRequest == null) {
      stdout.write('> ');
      try {
        final paymentRequestString = stdin.readLineSync()!.trim().toLowerCase();
        paymentRequest = decodeLightningPaymentRequest(paymentRequestString);
      } catch (e) {
        print("\nCouldn't validate the lightning payment request. Please try again:");
      }
    }

    offerAcceptFile = XchToBtcOfferAcceptFile(
      validityTime: validityTime,
      publicKey: requestorPublicKey,
      lightningPaymentRequest: paymentRequest,
    );
  } else {
    deserializedOfferFile = deserializedOfferFile as XchToBtcOfferFile;

    messageAddress = deserializedOfferFile.messageAddress;

    offerAcceptFile = BtcToXchOfferAcceptFile(
      validityTime: validityTime,
      publicKey: requestorPublicKey,
    );
  }

  final serializedOfferAcceptFile =
      serializeCrossChainOfferFile(offerAcceptFile, requestorPrivateKey);

  await generateLogFile(requestorPrivateKey, offerFile!, serializedOfferAcceptFile);

  final keychainCoreSecret = KeychainCoreSecret.generate();
  final keychain = WalletKeychain.fromCoreSecret(keychainCoreSecret);
  final coinPuzzlehash = keychain.puzzlehashes.first;
  final coinAddress = Address.fromContext(coinPuzzlehash);
  final messagePuzzlehash = messageAddress.toPuzzlehash();

  print('\nA coin with a memo containing your serialized offer accept file below must');
  print('be sent to the message address indicated in the original offer file.');
  print(serializedOfferAcceptFile);
  print('\nYou may either send a coin with the above memo yourself, OR you may');
  print('send at least 100 mojos the following address, and the program will');
  print('send the coin with memo on your behalf:');

  print('\nPlease indicate your choice:');
  print('1. Manually send coin with memo');
  print('2. Have program send coin with memo');
  String? choice;
  while (choice != '1' && choice != '2') {
    stdout.write('> ');
    choice = stdin.readLineSync()!.trim();
    if (choice == '1') {
      print('\nSend a coin with the above memo to the this address:');
      print(messageAddress.address);
      print('\nPress any key to continue once you have done so.');
      stdin.readLineSync();
    } else if (choice == '2') {
      print('\nSend at least 100 mojos the following address, and the program will');
      print('send the coin with memo on your behalf:');
      print(coinAddress.address);

      print('\nPress any key to continue once you have done so.');
      stdin.readLineSync();

      final additionPuzzlehashes = <Puzzlehash>[];
      var transactionValidated = false;
      var coins = <Coin>[];

      while (coins.totalValue < 100) {
        print('Waiting for coin...');
        await Future<void>.delayed(const Duration(seconds: 10));

        // if transaction hasn't been validated yet, keep checking mempool
        if (transactionValidated == false) {
          final mempoolItemsResponse = await fullNode.getAllMempoolItems();
          mempoolItemsResponse.mempoolItemMap.forEach((key, item) {
            additionPuzzlehashes.addAll(item.additions.map((addition) => addition.puzzlehash));
          });

          if (additionPuzzlehashes.contains(coinPuzzlehash)) {
            print('\nThe transaction has been validated and is now in the mempool.\n');
            transactionValidated = true;
          }
        }

        coins = await fullNode.getCoinsByPuzzleHashes(
          [coinPuzzlehash],
        );
      }

      print('\nXCH received!');

      final messageSpendBundle = standardWalletService.createSpendBundle(
        payments: [
          Payment(50, messagePuzzlehash, memos: <String>[serializedOfferAcceptFile])
        ],
        coinsInput: coins,
        keychain: keychain,
        fee: 50,
      );

      await fullNode.pushTransaction(messageSpendBundle);

      print('\nSending coin with memo to message address...\n');
    } else {
      print('\nNot a valid choice.');
    }
  }

  var offerAcceptFileMemo = await waitForMessageCoin(messagePuzzlehash, fullNode);

  if (offerAcceptFileMemo != serializedOfferAcceptFile) {
    print('The coin send to the message address has the wrong memo. Please try again.');
    offerAcceptFileMemo = await waitForMessageCoin(messagePuzzlehash, fullNode);
  }

  if (offerAcceptFile.type == CrossChainOfferFileType.xchToBtcAccept) {
    deserializedOfferFile = deserializedOfferFile as BtcToXchOfferFile;
    offerAcceptFile = offerAcceptFile as XchToBtcOfferAcceptFile;

    await completeXchToBtcExchange(
      amountXch: deserializedOfferFile.requestedAmount.amount,
      requestorPrivateKey: requestorPrivateKey,
      validityTime: validityTime,
      paymentRequest: offerAcceptFile.lightningPaymentRequest,
      fulfillerPublicKey: deserializedOfferFile.publicKey,
      fullNode: fullNode,
    );
  } else {
    deserializedOfferFile = deserializedOfferFile as XchToBtcOfferFile;
    offerAcceptFile = offerAcceptFile as BtcToXchOfferAcceptFile;

    await completeBtcToXchExchange(
      amountXch: deserializedOfferFile.offeredAmount.amount,
      requestorPrivateKey: requestorPrivateKey,
      validityTime: validityTime,
      paymentRequest: deserializedOfferFile.lightningPaymentRequest,
      fulfillerPublicKey: deserializedOfferFile.publicKey,
      fullNode: fullNode,
    );
  }
}

Future<void> resumeCrossChainOfferExchange(ChiaFullNodeInterface fullNode) async {
  print('\nPlease paste in the original cross chain offer file:');
  CrossChainOfferFile? deserializedOfferFile;
  while (deserializedOfferFile == null) {
    stdout.write('> ');
    try {
      stdin.lineMode = false;
      deserializedOfferFile = deserializeCrossChainOfferFile(stdin.readLineSync()!.trim());
      stdin.lineMode = true;
      if (deserializedOfferFile.prefix.name == 'ccoffer_accept') {
        print(
          "Wrong offer file type. The prefix should be 'ccoffer,' not 'ccoffer_accept.'",
        );
        deserializedOfferFile = null;
      }
    } catch (e) {
      print('\nPlease enter a valid cross chain offer file:');
    }
  }

  if (deserializedOfferFile.validityTime < (DateTime.now().millisecondsSinceEpoch / 1000)) {
    print('\nThis cross chain offer has expired. Try again with a still valid offer.');
    exit(exitCode);
  }

  print('\nPlease paste in the cross chain offer accept file:');
  CrossChainOfferFile? deserializedOfferAcceptFile;
  while (deserializedOfferAcceptFile == null) {
    stdout.write('> ');
    try {
      stdin.lineMode = false;
      deserializedOfferAcceptFile = deserializeCrossChainOfferFile(stdin.readLineSync()!.trim());
      stdin.lineMode = true;
      if (deserializedOfferAcceptFile.prefix.name == 'ccoffer') {
        print(
          "Wrong offer file type. The prefix should be 'ccoffer_accept,' not 'ccoffer.'",
        );
        deserializedOfferAcceptFile = null;
      }
    } catch (e) {
      print('\nPlease enter a valid cross chain offer accept file:');
    }
  }

  print('\nPlease paste in the private key you used for this exchange:');
  PrivateKey? requestorPrivateKey;
  while (requestorPrivateKey == null) {
    stdout.write('> ');
    try {
      final privateKeyInput = PrivateKey.fromHex(stdin.readLineSync()!.trim());
      if (deserializedOfferFile!.publicKey == privateKeyInput.getG1() &&
          deserializedOfferAcceptFile != null) {
        // user made offer
        requestorPrivateKey = privateKeyInput;

        if (deserializedOfferFile.type == CrossChainOfferFileType.xchToBtc) {
          deserializedOfferFile = deserializedOfferFile as XchToBtcOfferFile;
          deserializedOfferAcceptFile = deserializedOfferAcceptFile as BtcToXchOfferAcceptFile;

          await completeXchToBtcExchange(
            amountXch: deserializedOfferFile.offeredAmount.amount,
            requestorPrivateKey: requestorPrivateKey,
            validityTime: deserializedOfferAcceptFile.validityTime,
            paymentRequest: deserializedOfferFile.lightningPaymentRequest,
            fulfillerPublicKey: deserializedOfferAcceptFile.publicKey,
            fullNode: fullNode,
          );
        } else {
          deserializedOfferFile = deserializedOfferFile as BtcToXchOfferFile;
          deserializedOfferAcceptFile = deserializedOfferAcceptFile as XchToBtcOfferAcceptFile;

          await completeBtcToXchExchange(
            amountXch: deserializedOfferFile.requestedAmount.amount,
            requestorPrivateKey: requestorPrivateKey,
            validityTime: deserializedOfferAcceptFile.validityTime,
            paymentRequest: deserializedOfferAcceptFile.lightningPaymentRequest,
            fulfillerPublicKey: deserializedOfferAcceptFile.publicKey,
            fullNode: fullNode,
          );
        }
      } else if (deserializedOfferAcceptFile!.publicKey == privateKeyInput.getG1()) {
        // user is accepting offer
        requestorPrivateKey = privateKeyInput;

        if (deserializedOfferAcceptFile.type == CrossChainOfferFileType.xchToBtcAccept) {
          deserializedOfferFile = deserializedOfferFile as BtcToXchOfferFile;
          deserializedOfferAcceptFile = deserializedOfferAcceptFile as XchToBtcOfferAcceptFile;

          await completeXchToBtcExchange(
            amountXch: deserializedOfferFile.requestedAmount.amount,
            requestorPrivateKey: requestorPrivateKey,
            validityTime: deserializedOfferAcceptFile.validityTime,
            paymentRequest: deserializedOfferAcceptFile.lightningPaymentRequest,
            fulfillerPublicKey: deserializedOfferFile.publicKey,
            fullNode: fullNode,
          );
        } else {
          deserializedOfferFile = deserializedOfferFile as XchToBtcOfferFile;
          deserializedOfferAcceptFile = deserializedOfferAcceptFile as BtcToXchOfferAcceptFile;

          await completeBtcToXchExchange(
            amountXch: deserializedOfferFile.offeredAmount.amount,
            requestorPrivateKey: requestorPrivateKey,
            validityTime: deserializedOfferAcceptFile.validityTime,
            paymentRequest: deserializedOfferFile.lightningPaymentRequest,
            fulfillerPublicKey: deserializedOfferFile.publicKey,
            fullNode: fullNode,
          );
        }
      }
    } catch (e) {
      print('\nInvalid key. Please try again:');
    }
  }
}

Future<String> waitForMessageCoin(
  Puzzlehash messagePuzzlehash,
  ChiaFullNodeInterface fullNode,
) async {
  final additionPuzzlehashes = <Puzzlehash>[];
  var transactionValidated = false;

  while (true) {
    print('Waiting for message coin to arrive...');
    await Future<void>.delayed(const Duration(seconds: 10));

    // if transaction hasn't been validated yet, keep checking mempool
    if (transactionValidated == false) {
      final mempoolItemsResponse = await fullNode.getAllMempoolItems();
      mempoolItemsResponse.mempoolItemMap.forEach((key, item) {
        additionPuzzlehashes.addAll(item.additions.map((addition) => addition.puzzlehash));
      });

      if (additionPuzzlehashes.contains(messagePuzzlehash)) {
        print('\nThe transaction has been validated and is now in the mempool.\n');
        transactionValidated = true;
      }
    }

    // check whether coins at message address have a valid ccoffer_accept memo
    final coins = await fullNode.getCoinsByPuzzleHashes(
      [messagePuzzlehash],
    );

    for (final coin in coins) {
      final parentCoin = await fullNode.getCoinById(coin.parentCoinInfo);
      final coinSpend = await fullNode.getCoinSpend(parentCoin!);

      final memos = await coinSpend!.memoStrings;

      for (final memo in memos) {
        if (memo.startsWith('ccoffer_accept')) {
          return memo;
        }
      }
    }
  }
}

Future<List<Coin>> waitForEscrowCoins({
  required int amountMojos,
  required Puzzlehash escrowPuzzlehash,
  required ChiaFullNodeInterface fullNode,
}) async {
  // wait for XCH to arrive at the escrow address
  final additionPuzzlehashes = <Puzzlehash>[];
  var transactionValidated = false;
  var escrowCoins = <Coin>[];

  while (escrowCoins.totalValue < amountMojos) {
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
    }

    escrowCoins = await fullNode.getCoinsByPuzzleHashes(
      [escrowPuzzlehash],
    );
  }

  print('\nThe escrow address has received sufficient XCH!');

  return escrowCoins;
}

Future<void> completeBtcToXchExchange({
  required double amountXch,
  required PrivateKey requestorPrivateKey,
  required int validityTime,
  required LightningPaymentRequest paymentRequest,
  required JacobianPoint fulfillerPublicKey,
  required ChiaFullNodeInterface fullNode,
}) async {
  final paymentHash = paymentRequest.tags.paymentHash!;

  final escrowPuzzlehash = btcToXchService.generateEscrowPuzzlehash(
    requestorPrivateKey: requestorPrivateKey,
    clawbackDelaySeconds: validityTime,
    sweepPaymentHash: paymentHash,
    fulfillerPublicKey: fulfillerPublicKey,
  );

  final amountMojos = (amountXch * 1e12).toInt();

  print('\nYour counter party should be sending XCH to the following escrow address:');
  print(Address.fromContext(escrowPuzzlehash).address);
  print('\nPress any key to start waiting for the XCH from your counter party.');
  stdin.readLineSync();

  final escrowCoins = await waitForEscrowCoins(
    amountMojos: amountMojos,
    escrowPuzzlehash: escrowPuzzlehash,
    fullNode: fullNode,
  );

  print('\nPlease paste the following lightning invoice into your BTC wallet and pay it.');
  print('Note that you must use a wallet that supports preimage reveal, such as Muun.');
  print(paymentRequest.paymentRequest);
  print('\nAfter you have done so, you can find your lightning payment request');
  print('preimage by navigating to transaction history in your lightning wallet,');
  print('clicking on the transaction, and viewing the payment details.');
  print('\nPaste in the preimage below.');

  Bytes? preimage;

  while (preimage == null) {
    stdout.write('> ');
    final preimageInput = stdin.readLineSync()!.trim().toLowerCase();

    try {
      if (preimageInput.hexToBytes().sha256Hash() == paymentRequest.tags.paymentHash) {
        preimage = preimageInput.hexToBytes();
      } else {
        print("\nCouldn't verify input as preimage. Please try again.");
      }
    } catch (e) {
      LoggingContext().error(e.toString());
    }
  }

  print('\nPlease enter the address where you want to receive the XCH:');
  final sweepPuzzlehash = getRequestorPuzzlehash();

  final sweepSpendBundle = btcToXchService.createSweepSpendBundle(
    payments: [Payment(escrowCoins.totalValue, sweepPuzzlehash)],
    coinsInput: escrowCoins,
    requestorPrivateKey: requestorPrivateKey,
    clawbackDelaySeconds: validityTime,
    sweepPaymentHash: paymentHash,
    sweepPreimage: preimage,
    fulfillerPublicKey: fulfillerPublicKey,
  );

  print('\nPushing spend bundle to sweep XCH to your address...');
  await generateSpendBundleFile(sweepSpendBundle);
  try {
    await fullNode.pushTransaction(sweepSpendBundle);
    await verifyTransaction(escrowCoins, sweepPuzzlehash, fullNode);
  } catch (e) {
    print('\nTRANSACTION FAILED. The spend bundle was rejected. You may have responded');
    print('after the agreed upon expiration time.');
  }
}

Future<void> completeXchToBtcExchange({
  required double amountXch,
  required PrivateKey requestorPrivateKey,
  required int validityTime,
  required LightningPaymentRequest paymentRequest,
  required JacobianPoint fulfillerPublicKey,
  required ChiaFullNodeInterface fullNode,
}) async {
  final paymentHash = paymentRequest.tags.paymentHash!;

  final escrowPuzzlehash = xchToBtcService.generateEscrowPuzzlehash(
    requestorPrivateKey: requestorPrivateKey,
    clawbackDelaySeconds: validityTime,
    sweepPaymentHash: paymentRequest.tags.paymentHash!,
    fulfillerPublicKey: fulfillerPublicKey,
  );

  print('\nPlease send $amountXch XCH to the following escrow address:');
  print(escrowPuzzlehash.toAddressWithContext().address);

  print('\nPress any key to continue once you have done so.');
  stdin.readLineSync();

  final amountMojos = (amountXch * 1e12).toInt();

  final escrowCoins = await waitForEscrowCoins(
    amountMojos: amountMojos,
    escrowPuzzlehash: escrowPuzzlehash,
    fullNode: fullNode,
  );

  print('\nEnter the address where the XCH will be returned in the event the exchange');
  print('is aborted or fails.');
  final clawbackPuzzlehash = getRequestorPuzzlehash();

  final clawbackSpendBundle = xchToBtcService.createClawbackSpendBundle(
    payments: [Payment(escrowCoins.totalValue, clawbackPuzzlehash)],
    coinsInput: escrowCoins,
    requestorPrivateKey: requestorPrivateKey,
    sweepPaymentHash: paymentHash,
    fulfillerPublicKey: fulfillerPublicKey,
  );

  final validityTimeMinutes = (validityTime / 60).round();

  print('\nAfter $validityTimeMinutes, you may claw back your XCH if your counter');
  print('party does not pay the lightning invoice.');

  await confirmClawback(
    clawbackSpendBundle: clawbackSpendBundle,
    clawbackDelayMinutes: validityTimeMinutes,
    escrowCoins: escrowCoins,
    clawbackPuzzlehash: clawbackPuzzlehash,
    fullNode: fullNode,
  );
}

Future<void> generateLogFile(
  PrivateKey requestorPrivateKey,
  String serializedOfferFile, [
  String? serializedOfferAcceptFile,
]) async {
  final logFile = File('exchange-log-${DateTime.now().toString().replaceAll(' ', '-')}.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync(serializedOfferFile, mode: FileMode.append);

  if (serializedOfferAcceptFile == null) {
    print('\nPrinting serialized offer file and disposable private key to a file...');
    logFile.writeAsStringSync('\n\n${requestorPrivateKey.toHex()}', mode: FileMode.append);
  } else {
    print('\nPrinting serialized offer file, serialized offer accept file, and');
    print('disposable private key to a file...');
    logFile
      ..writeAsStringSync('\n\n$serializedOfferAcceptFile', mode: FileMode.append)
      ..writeAsStringSync('\n\n${requestorPrivateKey.toHex()}', mode: FileMode.append);
  }
}
