import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/command/exchange/cross_chain_offer_exchange.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/xch_to_btc_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/utils/cross_chain_offer_file_serialization.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/btc_to_xch.dart';
import 'package:chia_crypto_utils/src/exchange/btc/service/xch_to_btc.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final simulatorHttpRpc = SimulatorHttpRpc(
    SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );

  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final walletService = StandardWalletService();
  final btcToXchService = BtcToXchService();
  final xchToBtcService = XchToBtcService();

  test(
      'should create and accept XCH to BTC offer file and complete exchange by sweeping XCH to BTC holder with preimage',
      () async {
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();

    final btcHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await btcHolder.farmCoins();
    await btcHolder.refreshCoins();

    // A public/private key pair is generated for the XCH holder to use for the exchange
    final xchHolderPrivateKey = PrivateKey.generate();
    final xchHolderPublicKey = xchHolderPrivateKey.getG1();

    // XCH holder inputs details to create an cross chain offer file
    const amountMojos = 100000;
    const amountSatoshis = 100;

    final messageAddress =
        Address.fromContext(xchHolder.keychain.unhardenedWalletVectors[1].puzzlehash);

    const validityTimeHours = 1;
    final currentUnixTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final validityTime = currentUnixTimeStamp + (validityTimeHours * 60 * 60);

    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';
    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    final offerFile = XchToBtcOfferFile(
      offeredAmount: const ExchangeAmount(type: ExchangeAmountType.XCH, amount: amountMojos),
      requestedAmount: const ExchangeAmount(type: ExchangeAmountType.BTC, amount: amountSatoshis),
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: xchHolderPublicKey,
      lightningPaymentRequest: decodedPaymentRequest,
    );

    final serializedOfferFile = serializeCrossChainOfferFile(offerFile, xchHolderPrivateKey);

    // A public/private key pair is generated for the BTC holder to use for the exchange
    final btcHolderPrivateKey = PrivateKey.generate();
    final btcHolderPublicKey = btcHolderPrivateKey.getG1();

    // BTC holder's side views offer, checks validity, and creates a cross chain offer accept file
    expect(() => checkValidity(offerFile), returnsNormally);

    const postAcceptValidityTime = 600;
    final acceptedOfferHash = Bytes.encodeFromString(serializedOfferFile).sha256Hash();

    final offerAcceptFile = BtcToXchOfferAcceptFile(
      validityTime: postAcceptValidityTime,
      publicKey: btcHolderPublicKey,
      acceptedOfferHash: acceptedOfferHash,
    );

    final serializedOfferAcceptFile =
        serializeCrossChainOfferFile(offerAcceptFile, btcHolderPrivateKey);

    // BTC holder sends a coin with the serialized offer accept file as a memo to the message address
    // from the XCH holder's offer file and verifies receipt of message coin
    final messagePuzzlehash = messageAddress.toPuzzlehash();

    final messageSpendBundle = walletService.createSpendBundle(
      payments: [
        Payment(50, messagePuzzlehash, memos: <String>[serializedOfferAcceptFile])
      ],
      coinsInput: [btcHolder.standardCoins.first],
      keychain: btcHolder.keychain,
      changePuzzlehash: btcHolder.firstPuzzlehash,
      fee: 50,
    );

    await fullNodeSimulator.pushTransaction(messageSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final messageVerification = await verifyOfferAcceptFileMemo(
      messagePuzzlehash,
      serializedOfferAcceptFile,
      fullNodeSimulator,
    );

    expect(messageVerification, equals(true));

    // BTC holder's side constructs escrow address from offer file and offer accept file details
    final deserializedOfferFile =
        deserializeCrossChainOfferFile(serializedOfferFile) as XchToBtcOfferFile;

    final paymentHash = deserializedOfferFile.lightningPaymentRequest.tags.paymentHash!;

    final btcHolderEscrowPuzzlehash = btcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: btcHolderPrivateKey,
      clawbackDelaySeconds: postAcceptValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: deserializedOfferFile.publicKey,
    );

    // XCH holder's side deserializes memo from the received coin
    final offerAcceptFileMemo =
        await getOfferAcceptFileMemo(messagePuzzlehash, serializedOfferFile, fullNodeSimulator);

    expect(offerAcceptFileMemo, equals(serializedOfferAcceptFile));

    final deserializedOfferAcceptFile =
        deserializeCrossChainOfferFile(offerAcceptFileMemo!) as BtcToXchOfferAcceptFile;

    // XCH holder's side constructs escrow address from details in offer file and offer accept file
    final xchHolderEscrowPuzzlehash = xchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: xchHolderPrivateKey,
      clawbackDelaySeconds: deserializedOfferAcceptFile.validityTime,
      sweepPaymentHash: decodedPaymentRequest.tags.paymentHash!,
      fulfillerPublicKey: deserializedOfferAcceptFile.publicKey,
    );

    // the escrow puzzlehashes on either side should match
    expect(xchHolderEscrowPuzzlehash, equals(btcHolderEscrowPuzzlehash));

    // XCH holder transfers XCH to escrow address
    final coinsForExchange = xchHolder.standardCoins;

    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountMojos, xchHolderEscrowPuzzlehash)],
      coinsInput: coinsForExchange,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      keychain: xchHolder.keychain,
    );
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final escrowCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([xchHolderEscrowPuzzlehash]);

    // after the BTC holder sees that XCH has arrived at the escrow address, they pay the lightning invoice.
    // the BTC holder inputs into the program the preimage that is revealed after payment and the puzzlehash
    // where they want to receive their XCH, which then creates and pushes a spend bundle to sweep funds
    final sweepPreimage =
        '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();
    final sweepPuzzlehash = btcHolder.firstPuzzlehash;
    final startingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    final sweepSpendBundle = btcToXchService.createSweepSpendBundle(
      payments: [Payment(escrowCoins.totalValue, sweepPuzzlehash)],
      coinsInput: escrowCoins,
      requestorPrivateKey: btcHolderPrivateKey,
      clawbackDelaySeconds: postAcceptValidityTime,
      sweepPaymentHash: paymentHash,
      sweepPreimage: sweepPreimage,
      fulfillerPublicKey: xchHolderPublicKey,
    );

    await fullNodeSimulator.pushTransaction(sweepSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    expect(
      endingSweepBalance,
      equals(startingSweepBalance + escrowCoins.totalValue),
    );
  });

  test(
      'should create and accept BTC to XCH offer file and complete exchange by sweeping XCH to BTC holder with preimage',
      () async {
    final btcHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await btcHolder.farmCoins();
    await btcHolder.refreshCoins();

    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();

    // A public/private key pair is generated for the BTC holder to use for the exchange
    final btcHolderPrivateKey = PrivateKey.generate();
    final btcHolderPublicKey = btcHolderPrivateKey.getG1();

    // BTC holder inputs details to create an cross chain offer file
    const amountSatoshis = 100;
    const amountMojos = 100000;

    final messageAddress =
        Address.fromContext(xchHolder.keychain.unhardenedWalletVectors[1].puzzlehash);

    const validityTimeHours = 1;
    final currentUnixTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final validityTime = currentUnixTimeStamp + (validityTimeHours * 60 * 60);

    final offerFile = BtcToXchOfferFile(
      offeredAmount: const ExchangeAmount(type: ExchangeAmountType.BTC, amount: amountSatoshis),
      requestedAmount: const ExchangeAmount(type: ExchangeAmountType.XCH, amount: amountMojos),
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: btcHolderPublicKey,
    );

    final serializedOfferFile = serializeCrossChainOfferFile(offerFile, btcHolderPrivateKey);

    // A public/private key pair is generated for the XCH holder to use for the exchange
    final xchHolderPrivateKey = PrivateKey.generate();
    final xchHolderPublicKey = xchHolderPrivateKey.getG1();

    // XCH holder's side views offer, checks validity, and creates a cross chain offer accept file
    expect(() => checkValidity(offerFile), returnsNormally);

    const postAcceptValidityTime = 600;
    final acceptedOfferHash = Bytes.encodeFromString(serializedOfferFile).sha256Hash();

    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';
    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    final offerAcceptFile = XchToBtcOfferAcceptFile(
      validityTime: postAcceptValidityTime,
      publicKey: xchHolderPublicKey,
      acceptedOfferHash: acceptedOfferHash,
      lightningPaymentRequest: decodedPaymentRequest,
    );

    final serializedOfferAcceptFile =
        serializeCrossChainOfferFile(offerAcceptFile, xchHolderPrivateKey);

    // XCH holder sends a coin with the serialized offer accept file as a memo to the message address
    // from the BTC holder's offer file and verifies receipt of message coin
    final messagePuzzlehash = messageAddress.toPuzzlehash();

    final messageSpendBundle = walletService.createSpendBundle(
      payments: [
        Payment(50, messagePuzzlehash, memos: <String>[serializedOfferAcceptFile])
      ],
      coinsInput: [xchHolder.standardCoins.first],
      keychain: xchHolder.keychain,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      fee: 50,
    );

    await fullNodeSimulator.pushTransaction(messageSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final messageVerification = await verifyOfferAcceptFileMemo(
      messagePuzzlehash,
      serializedOfferAcceptFile,
      fullNodeSimulator,
    );

    expect(messageVerification, equals(true));

    // XCH holder's side constructs escrow address from offer file and offer accept file details
    final deserializedOfferFile =
        deserializeCrossChainOfferFile(serializedOfferFile) as BtcToXchOfferFile;

    final xchHolderEscrowPuzzlehash = xchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: xchHolderPrivateKey,
      clawbackDelaySeconds: postAcceptValidityTime,
      sweepPaymentHash: decodedPaymentRequest.tags.paymentHash!,
      fulfillerPublicKey: deserializedOfferFile.publicKey,
    );

    // BTC holder's side deserializes memo from the received coin
    final offerAcceptFileMemo =
        await getOfferAcceptFileMemo(messagePuzzlehash, serializedOfferFile, fullNodeSimulator);

    expect(offerAcceptFileMemo, equals(serializedOfferAcceptFile));

    final deserializedOfferAcceptFile =
        deserializeCrossChainOfferFile(offerAcceptFileMemo!) as XchToBtcOfferAcceptFile;

    // BTC holder's side constructs escrow address from details in offer file and offer accept file
    final paymentHash = deserializedOfferAcceptFile.lightningPaymentRequest.tags.paymentHash;

    final btcHolderExcrowPuzzle = btcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: btcHolderPrivateKey,
      clawbackDelaySeconds: postAcceptValidityTime,
      sweepPaymentHash: paymentHash!,
      fulfillerPublicKey: deserializedOfferAcceptFile.publicKey,
    );

    // the escrow puzzlehashes on either side should match
    expect(btcHolderExcrowPuzzle, equals(xchHolderEscrowPuzzlehash));

    // XCH holder transfers XCH to escrow address
    await xchHolder.refreshCoins();
    final coinsForExchange = xchHolder.standardCoins;

    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountMojos, xchHolderEscrowPuzzlehash)],
      coinsInput: coinsForExchange,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      keychain: xchHolder.keychain,
    );
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final escrowCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([xchHolderEscrowPuzzlehash]);

    // after the BTC holder sees that XCH has arrived at the escrow address, they pay the lightning invoice.
    // the BTC holder inputs into the program the preimage that is revealed after payment and the puzzlehash
    // where they want to receive their XCH, which then creates and pushes a spend bundle to sweep funds
    final sweepPreimage =
        '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();
    final sweepPuzzlehash = btcHolder.firstPuzzlehash;
    final startingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    final sweepSpendBundle = btcToXchService.createSweepSpendBundle(
      payments: [Payment(escrowCoins.totalValue, sweepPuzzlehash)],
      coinsInput: escrowCoins,
      requestorPrivateKey: btcHolderPrivateKey,
      clawbackDelaySeconds: postAcceptValidityTime,
      sweepPaymentHash: paymentHash,
      sweepPreimage: sweepPreimage,
      fulfillerPublicKey: xchHolderPublicKey,
    );

    await fullNodeSimulator.pushTransaction(sweepSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    expect(
      endingSweepBalance,
      equals(startingSweepBalance + escrowCoins.totalValue),
    );
  });
}
