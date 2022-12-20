import 'dart:io';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/validity_time.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/utils/cross_chain_offer_file_serialization.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/btc_to_xch.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/xch_to_btc.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';

final xchToBtcService = XchToBtcService();
final btcToXchService = BtcToXchService();

Future<void> makeCrossChainOffer(ChiaFullNodeInterface fullNode) async {
  final privateKey = PrivateKey.generate();
  final publicKey = privateKey.getG1();

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

  while (choice != '1' && choice != '2') {
    stdout.write('> ');
    choice = stdin.readLineSync()!.trim();

    if (choice == '1') {
      offeredAmountType = ExchangeAmountType.XCH;
      requestedAmountType = ExchangeAmountType.BTC;
    } else if (choice == '2') {
      offeredAmountType = ExchangeAmountType.BTC;
      requestedAmountType = ExchangeAmountType.XCH;
    } else {
      print('\nNot a valid choice.');
    }
  }

  print('\nHow much ${offeredAmountType!.name} are you offering?');
  double? offeredAmountValue;
  while (offeredAmountValue == null) {
    stdout.write('> ');
    try {
      offeredAmountValue = double.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter the amount of ${offeredAmountType.name} being exchanged:');
    }
  }

  print('\nHow much ${requestedAmountType!.name} are you requesting in exchange?');
  double? requestedAmountValue;
  while (requestedAmountValue == null) {
    stdout.write('> ');
    try {
      requestedAmountValue = double.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter the amount of ${requestedAmountType.name} being exchanged:');
    }
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

  print('\nEnter when you want the offer to expire as a unix epoch timestamp:');
  int? validityTime;
  while (validityTime == null || validityTime < (DateTime.now().millisecondsSinceEpoch / 1000)) {
    stdout.write('> ');
    try {
      validityTime = int.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter a valid unix epoch timestamp greater than the current time:');
    }
  }

  CrossChainOfferFile? offerFile;

  if (requestedAmountType == ExchangeAmountType.BTC) {
    print('\nCreate a lightning payment request for $requestedAmountValue BTC and paste it here:');
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
      offeredAmount: ExchangeAmount(type: offeredAmountType, value: offeredAmountValue),
      requestedAmount: ExchangeAmount(type: requestedAmountType, value: requestedAmountValue),
      messageAddress: messageAddress,
      validityTime: ValidityTime(type: ValidityTimeType.unix_epoch, value: validityTime),
      publicKey: publicKey,
      lightningPaymentRequest: paymentRequest,
    );
  } else {
    offerFile = BtcToXchOfferFile(
      offeredAmount: ExchangeAmount(type: offeredAmountType, value: offeredAmountValue),
      requestedAmount: ExchangeAmount(type: requestedAmountType, value: requestedAmountValue),
      messageAddress: messageAddress,
      validityTime: ValidityTime(type: ValidityTimeType.unix_epoch, value: validityTime),
      publicKey: publicKey,
    );
  }

  final serializedOfferFile = serializeCrossChainOfferFile(offerFile, privateKey);

  // XCH TO BTC
  // send to dexie endpoint
  // when message coin with public key arrives
  // parse out public key and validation time
  // construct escrow address for xch holder to send coins to
  // wait for coins to arrive at escrow address
  // past validity time, try pushing clawback spend bundle

  // BTC TO XCH
  // send offer file to dexie endpoint
  // when message coin with public key arrives
  // parse out public key, validation time, lightning invoice
  // output lightning invoice so user can pay it
  // construct escrow address to watch
  // wait for coins to arrive at escrow address
  // push sweep spend bundle
}

Future<void> acceptCrossChainOffer(ChiaFullNodeInterface fullNode) async {
  final privateKey = PrivateKey.generate();
  final publicKey = privateKey.getG1();

  print('\nPaste in the serialized cross chain offer file you want to accept:');
  CrossChainOfferFile? deserializedOfferFile;
  while (deserializedOfferFile == null) {
    stdout.write('> ');
    try {
      deserializedOfferFile = deserializeCrossChainOfferFile(stdin.readLineSync()!.trim());
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

  print('\nEnter how long you want to allow for the exchange to complete before it is');
  print('aborted in terms of seconds.');
  int? validityTime;
  while (validityTime == null) {
    stdout.write('> ');
    try {
      validityTime = int.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print(
        '\nPlease enter a valid duration in terms of seconds:',
      );
    }
  }

  CrossChainOfferFile? acceptOfferFile;

  if (deserializedOfferFile.type == CrossChainOfferFileType.btcToXch) {
    deserializedOfferFile = deserializedOfferFile as BtcToXchOfferFile;

    print(
        '\nCreate a lightning payment request for ${deserializedOfferFile.offeredAmount.value} BTC and paste it here:');
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

    acceptOfferFile = XchToBtcAcceptOfferFile(
      validityTime: ValidityTime(type: ValidityTimeType.seconds, value: validityTime),
      publicKey: publicKey,
      lightningPaymentRequest: paymentRequest,
    );
  } else {
    acceptOfferFile = BtcToXchAcceptOfferFile(
      validityTime: ValidityTime(type: ValidityTimeType.seconds, value: validityTime),
      publicKey: publicKey,
    );
  }

  final serializedAcceptOfferFile = serializeCrossChainOfferFile(acceptOfferFile, privateKey);

  // BTC TO XCH
  // send coin with accept offer file as memo to message address
  // construct escrow address
  // wait for coins to arrive at escrow address
  // when coins have arrived ask user for preimage
  // push sweep spend bundle

  // XCH TO BTC
  // send coin with accept offer file as memo to message address
  // construct escrow address for xch holder to send coins to
  // wait for coins to arrive at escrow address
  // past validity time, try pushing clawback spend bundle
}

Future<void> resumeCrossChainOfferExchange(ChiaFullNodeInterface fullNode) async {
  print('\n Please paste in the original cross chain offer file:');
  CrossChainOfferFile? deserializedOfferFile;
  while (deserializedOfferFile == null) {
    stdout.write('> ');
    try {
      deserializedOfferFile = deserializeCrossChainOfferFile(stdin.readLineSync()!.trim());
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

  print('\n Please paste in the cross chain offer accept file:');
  CrossChainOfferFile? deserializedAcceptOfferFile;
  while (deserializedAcceptOfferFile == null) {
    stdout.write('> ');
    try {
      deserializedOfferFile = deserializeCrossChainOfferFile(stdin.readLineSync()!.trim());
      if (deserializedOfferFile.prefix.name == 'ccoffer') {
        print(
          "Wrong offer file type. The prefix should be 'ccoffer_accept,' not 'ccoffer.'",
        );
        deserializedOfferFile = null;
      }
    } catch (e) {
      print('\nPlease enter a valid cross chain offer accept file:');
    }
  }

  // prompt user for private key they used in the exchange

  // prompt user for what side of the exchange they were on

  // reconstruct escrow address
}
