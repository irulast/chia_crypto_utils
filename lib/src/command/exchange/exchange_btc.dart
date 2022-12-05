import 'dart:io';
import 'package:bip39/bip39.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/btc_to_xch.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/exchange.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/xch_to_btc.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';

Future<void> exchangeXchForBtc(ChiaFullNodeInterface fullNode) async {
  final walletService = StandardWalletService();
  final exchangeService = BtcExchangeService();
  final xchToBtcService = XchToBtcService();

  final disposableMnemonic = generateMnemonic(strength: 256);
  final disposableKeychainSecret = KeychainCoreSecret.fromMnemonic(disposableMnemonic.split(' '));

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 5; i++) {
    final set1 = WalletSet.fromPrivateKey(disposableKeychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final disposableKeychain = WalletKeychain.fromWalletSets(walletsSetList);
  final disposableKeychainWalletVector = disposableKeychain.unhardenedMap.values.first;
  final disposableKeychainPuzzlehash = disposableKeychainWalletVector.puzzlehash;
  final disposableAddress = Address.fromContext(disposableKeychainPuzzlehash);
  final disposablePrivateKey = disposableKeychainWalletVector.childPrivateKey;
  final signedPublicKey = exchangeService.createSignedPublicKey(disposableKeychain);

  print('');
  print('Send the line below to your counter party. It contains your signed public key.');
  print(signedPublicKey);

  print('');
  print("Enter your counter party's signed public key");
  stdout.write('> ');
  final btcHolderSignedPublicKey = stdin.readLineSync();
  final btcHolderPublicKey = exchangeService.parseSignedPublicKey(btcHolderSignedPublicKey!);

  final response = await XchScan().getChiaPrice();
  final btcPerXch = response.priceBtc;
  final xchPerBtc = 1 / btcPerXch;
  final usdPerXch = response.priceUsd;
  final usdPerBtc = usdPerXch / btcPerXch;

  print('');
  print('These are the current prices:');
  print('1 XCH = $btcPerXch BTC or $usdPerXch USD');
  print('1 BTC = $xchPerBtc XCH or $usdPerBtc USD');

  print('');
  print('How much XCH is being traded?');
  stdout.write('> ');
  final xchAmountString = stdin.readLineSync();
  final xchAmount = double.parse(xchAmountString!);
  final btcAmount = xchAmount * btcPerXch.toInt();
  final xchAmountMojos = (xchAmount * 1e12).toInt();

  print('');
  print('Create a lightning payment request for $btcAmount');
  print('The timeout must be at least ten minutes');
  print('Copy and paste the lightning payment request here:');
  stdout.write('> ');
  final paymentRequest = stdin.readLineSync();
  final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest!);
  final sweepPaymentHash = decodedPaymentRequest.tags.paymentHash;

  final chiaswapPuzzleAddress = xchToBtcService.generateChiaswapPuzzleAddress(
    requestorKeychain: disposableKeychain,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: btcHolderPublicKey,
  );

  print(chiaswapPuzzleAddress.address);

  final chiaswapPuzzlehash = chiaswapPuzzleAddress.toPuzzlehash();

  print('');
  print('Transfer enough funds for the exchange to the following address: ');
  print(disposableAddress.address);

  print('Press any key when the funds have been sent.');
  stdin.readLineSync();

  var coins = <Coin>[];
  while (coins.totalValue < xchAmountMojos) {
    print('waiting for XCH...');
    await Future<void>.delayed(const Duration(seconds: 3));
    coins = await fullNode.getCoinsByPuzzleHashes(
      [disposableKeychainPuzzlehash],
    );
  }

  print('XCH received!');

  print('');
  print('Enter the address where the XCH will be returned if the exchange fails.');
  stdout.write('> ');
  final clawbackAddress = stdin.readLineSync();
  final clawbackPuzzlehash = Address(clawbackAddress!).toPuzzlehash();

  final coinsForChiaswap = await fullNode.getCoinsByPuzzleHashes([disposableKeychainPuzzlehash]);

  final chiaswapTransferSpendBundle = walletService.createSpendBundle(
    payments: [Payment(xchAmountMojos, chiaswapPuzzlehash)],
    coinsInput: coinsForChiaswap,
    changePuzzlehash: clawbackPuzzlehash,
    keychain: disposableKeychain,
  );
  await fullNode.pushTransaction(chiaswapTransferSpendBundle);

  final chiaswapAddressCoins =
      await fullNode.getCoinsByPuzzleHashes([chiaswapPuzzleAddress.toPuzzlehash()]);

  final clawbackSpendBundle = xchToBtcService.createClawbackSpendBundle(
    payments: [Payment(xchAmountMojos, clawbackPuzzlehash)],
    coinsInput: chiaswapAddressCoins,
    requestorKeychain: disposableKeychain,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: btcHolderPublicKey,
  );

  print('');
  print('Wait for your counter party to pay the lightning invoice.');
  print(
    'When the invoice is paid, share the private key below to allow your counter party to cleanly claim the XCH',
  );
  print(disposablePrivateKey.toHexWithPrefix());
  print('');
  print(
    'If the invoice is never paid, use the spend bundle below to claw back funds after 24 hours:',
  );
  print(clawbackSpendBundle.toHex());
  print('');
  print('Leave this window open or control-C to exit.');
  print('Warning: if you answer before 24 hours have passed, the spend bundle will be rejected.');
  print('Send spend bundle to claw back funds? (Y/N)');
  stdout.write('> ');
  final confirmation = stdin.readLineSync();
  if (confirmation!.toLowerCase() == 'Y') {
    try {
      await fullNode.pushTransaction(clawbackSpendBundle);
    } catch (e) {
      LoggingContext().error(e.toString());
    }
  }
}

Future<void> exchangeBtcForXch(ChiaFullNodeInterface fullNode) async {
  final exchangeService = BtcExchangeService();
  final btcToXchService = BtcToXchService();

  final disposableMnemonic = generateMnemonic(strength: 256);
  final disposableKeychainSecret = KeychainCoreSecret.fromMnemonic(disposableMnemonic.split(' '));

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 5; i++) {
    final set1 = WalletSet.fromPrivateKey(disposableKeychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final disposableKeychain = WalletKeychain.fromWalletSets(walletsSetList);
  final disposableKeychainWalletVector = disposableKeychain.unhardenedMap.values.first;
  final disposablePrivateKey = disposableKeychainWalletVector.childPrivateKey;
  final signedPublicKey = exchangeService.createSignedPublicKey(disposableKeychain);

  print('');
  print('Send the line below to your counter party. It contains your signed public key.');
  print(signedPublicKey);

  print('');
  print("Enter your counter party's signed public key.");
  stdout.write('> ');
  final xchHolderSignedPublicKey = stdin.readLineSync();
  final xchHolderPublicKey = exchangeService.parseSignedPublicKey(xchHolderSignedPublicKey!);

  final response = await XchScan().getChiaPrice();
  final btcPerXch = response.priceBtc;
  final xchPerBtc = 1 / btcPerXch;
  final usdPerXch = response.priceUsd;
  final usdPerBtc = usdPerXch / btcPerXch;

  print('');
  print('These are the current prices:');
  print('1 XCH = $btcPerXch BTC or $usdPerXch USD');
  print('1 BTC = $xchPerBtc XCH or $usdPerBtc USD');

  print('');
  print('How much XCH is being traded?');
  stdout.write('> ');
  final xchAmount = stdin.readLineSync();
  final xchAmountMojos = (double.parse(xchAmount!) * 1e12).toInt();

  print('');
  print('Paste the lightning payment request from your counter party here:');
  stdout.write('> ');
  final paymentRequest = stdin.readLineSync();
  final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest!);
  final sweepPaymentHash = decodedPaymentRequest.tags.paymentHash;

  final chiaswapPuzzleAddress = btcToXchService.generateChiaswapPuzzleAddress(
    requestorKeychain: disposableKeychain,
    sweepPaymentHash: sweepPaymentHash,
    fulfillerPublicKey: xchHolderPublicKey,
  );

  final chiaswapPuzzlehash = chiaswapPuzzleAddress.toPuzzlehash();

  print('');
  print('Enter the address where you would like the XCH delivered.');
  stdout.write('> ');
  final sweepAddress = stdin.readLineSync();
  final sweepPuzzlehash = Address(sweepAddress!).toPuzzlehash();

  print('');
  print('The XCH from your counter party will be received at the below address:');
  print(chiaswapPuzzleAddress.address);

  print('Go to an explorer and watch for payments:');
  print('https://xchscan.com/address/${chiaswapPuzzleAddress.address}');

  var coins = <Coin>[];
  while (coins.totalValue < xchAmountMojos) {
    await Future<void>.delayed(const Duration(seconds: 3));
    coins = await fullNode.getCoinsByPuzzleHashes(
      [chiaswapPuzzlehash],
    );
  }

  print('');
  print(
    'The XCH have been received. Once the payment has enough confirmations, pay the lightning invoice.',
  );
  print('');
  print('If you DO NOT want to complete this transaction, DO NOT pay the lightning invoice.');
  print(
    'Instead, send the following private key to your counter party to allow them to reclaim the XCH.',
  );
  print(disposablePrivateKey.toHexWithPrefix());

  print('');
  print(
    'Once you have paid the lightning invoice, ask your counter party to share their disposable private key',
  );
  print(
    'Also look up your lightning invoice preimage receipt in case your counter party disappears',
  );

  SpendBundle? sweepSpendBundle;

  print('');
  print(
    "Enter the private key from your counter party OR the lightning invoice preimage or 'quit'",
  );
  stdout.write('> ');
  final userInput = stdin.readLineSync();
  if (userInput == 'quit') {
    exit(exitCode);
  } else {
    try {
      final xchHolderPrivateKey = PrivateKey.fromHex(userInput!);

      if (xchHolderPrivateKey.getG1() == xchHolderPublicKey) {
        sweepSpendBundle = btcToXchService.createSweepSpendBundleWithPk(
          payments: [Payment(xchAmountMojos, sweepPuzzlehash)],
          coinsInput: coins,
          requestorKeychain: disposableKeychain,
          sweepPaymentHash: sweepPaymentHash,
          fulfillerPrivateKey: xchHolderPrivateKey,
        );
      }

      final sweepPreimage = userInput.hexToBytes();

      if (sweepPreimage.sha256Hash() == sweepPaymentHash) {
        sweepSpendBundle = btcToXchService.createSweepSpendBundle(
          payments: [Payment(xchAmountMojos, sweepPuzzlehash)],
          coinsInput: coins,
          requestorKeychain: disposableKeychain,
          sweepPaymentHash: sweepPaymentHash,
          sweepPreimage: sweepPreimage,
          fulfillerPublicKey: xchHolderPublicKey,
        );
      }
    } catch (e) {
      print("Couldn't verify input as either private key or preimage.");
    }
  }

  print('Send spend bundle to claim funds? (Y/N)');
  stdout.write('> ');
  final confirmation = stdin.readLineSync();
  if (confirmation!.toLowerCase() == 'Y') {
    try {
      await fullNode.pushTransaction(sweepSpendBundle!);
    } catch (e) {
      LoggingContext().error(e.toString());
    }
  }
}
