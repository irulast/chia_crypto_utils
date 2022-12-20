import 'dart:io';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';

Future<void> MakeCrossChainOfferExchange(ChiaFullNodeInterface fullNode) async {
  // XCH TO BTC
  // get offered amount, requested amount
  // get message address
  // generate public key
  // get lightning payment request
  // generate offer file, send to dexie endpoint

  // when message coin with public key arrives:
  // parse out public key and validation time
  // construct escrow address for xch holder to send coins to
  // wait for coins to arrive at escrow address

  // BTC TO XCH
  // get offered amount, requested amount
  // get message address
  // generate public key
  // get lightning payment request
  // generate offer file, send to dexie endpoint
}

Future<void> TakeCrossChainOfferExchange(ChiaFullNodeInterface fullNode) async {
  // BTC TO XCH
  // get and deserialize offer file
  // generate public key
  // get validity time
  // send coin with memo to message address
  // generate escrow address
  // wait for coins to arrive at escrow address
  // when coins have arrived ask user for preimage
  // push sweep spend bundle

  // XCH TO BTC
  // get and deserialize offer file
  // generate public key
  // get lightning payment request
  // get validity time
  // send coin with memo to message address
  // construct escrow address for xch holder to send coins to
  // wait for coins to arrive at escrow address
}

Future<void> getOfferSide(ChiaFullNodeInterface fullNode) async {
  print('\nAre you making an offer or taking a cross chain offer?');
  print('\n1. Making');
  print('2. Taking');

  String? choice;

  while (choice != '1' && choice != '2') {
    stdout.write('> ');
    choice = stdin.readLineSync()!.trim();

    if (choice == '1') {
      await MakeCrossChainOfferExchange(fullNode);
    } else if (choice == '2') {
      await TakeCrossChainOfferExchange(fullNode);
    } else {
      print('\nNot a valid choice.');
    }
  }
}

Future<void> generateOfferFile() async {
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

  print('\nAre you offering XCH or BTC?');
  print('\n1. XCH');
  print('2. BTC');

  String? choice;
  String? offeredAmountType;
  String? requestedAmountType;

  while (choice != '1' && choice != '2') {
    stdout.write('> ');
    choice = stdin.readLineSync()!.trim();

    if (choice == '1') {
      offeredAmountType = 'XCH';
      requestedAmountType = 'BTC';
    } else if (choice == '2') {
      offeredAmountType = 'BTC';
      requestedAmountType = 'XCH';
    } else {
      print('\nNot a valid choice.');
    }
  }

  double? offeredAmount;

  print('\nHow much $offeredAmountType are you offering?');
  while (offeredAmount == null) {
    stdout.write('> ');
    try {
      offeredAmount = double.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter the amount of $offeredAmountType being exchanged:');
    }
  }

  double? requestedAmount;

  print('\nHow much $requestedAmountType are you requesting in exchange?');
  while (requestedAmount == null) {
    stdout.write('> ');
    try {
      requestedAmount = double.parse(stdin.readLineSync()!.trim());
    } catch (e) {
      print('\nPlease enter the amount of $requestedAmount being exchanged:');
    }
  }

  print('\nEnter an address for receiving message coins');

  // xchAmountMojos = (xchAmount * 1e12).toInt();
}
