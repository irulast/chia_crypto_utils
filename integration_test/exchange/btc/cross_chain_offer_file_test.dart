import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
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
  final btcToXchService = BtcToXchService(fullNodeSimulator);
  final xchToBtcService = XchToBtcService(fullNodeSimulator);
  final crossChainOfferService = CrossChainOfferService(fullNodeSimulator);

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

    final offerFile = crossChainOfferService.createXchToBtcOfferFile(
      amountMojos: amountMojos,
      amountSatoshis: amountSatoshis,
      messageAddress: messageAddress,
      validityTime: validityTime,
      requestorPublicKey: xchHolderPublicKey,
      paymentRequest: decodedPaymentRequest,
    );

    final serializedOfferFile = offerFile.serialize(xchHolderPrivateKey);

    // A public/private key pair is generated for the BTC holder to use for the exchange
    final btcHolderPrivateKey = PrivateKey.generate();
    final btcHolderPublicKey = btcHolderPrivateKey.getG1();

    // BTC holder's side views offer, deserialized it, checks validity, and creates a cross chain offer accept file
    final deserializedOfferFile = XchToBtcOfferFile.fromSerializedOfferFile(serializedOfferFile);
    expect(() => CrossChainOfferService.checkValidity(deserializedOfferFile), returnsNormally);
    const postAcceptValidityTime = 600;

    final offerAcceptFile = crossChainOfferService.createBtcToXchAcceptFile(
      serializedOfferFile: serializedOfferFile,
      validityTime: postAcceptValidityTime,
      requestorPublicKey: btcHolderPublicKey,
    );

    final serializedOfferAcceptFile =
        serializeCrossChainOfferFile(offerAcceptFile, btcHolderPrivateKey);

    // BTC holder's side sends message coin with offer accept file to message puzzlehash and verifies receipt
    final messagePuzzlehash = deserializedOfferFile.messageAddress.toPuzzlehash();

    await crossChainOfferService.sendMessageCoin(
      keychain: btcHolder.keychain,
      coinsInput: [btcHolder.standardCoins.first],
      messagePuzzlehash: messagePuzzlehash,
      requestorPrivateKey: btcHolderPrivateKey,
      serializedOfferAcceptFile: serializedOfferAcceptFile,
      changePuzzlehash: btcHolder.firstPuzzlehash,
      fee: 50,
    );

    await fullNodeSimulator.moveToNextBlock();

    final messageVerification = await crossChainOfferService.verifyMessageCoinReceipt(
      messagePuzzlehash,
      serializedOfferAcceptFile,
    );

    expect(messageVerification, equals(true));

    // BTC holder's side gets exchange info from offer file and offer accept file details
    final btcHolderExchangeInfo = offerAcceptFile.getExchangeInfo(offerFile, btcHolderPrivateKey);
    final btcHolderEscrowPuzzlehash = btcHolderExchangeInfo.escrowPuzzlehash;

    // XCH holder's side deserializes memo from the received coin
    final offerAcceptFileMemo = await crossChainOfferService
        .getOfferAcceptFileFromMessagePuzzlehash(messagePuzzlehash, serializedOfferFile);

    expect(offerAcceptFileMemo, equals(serializedOfferAcceptFile));

    final deserializedOfferAcceptFile =
        BtcToXchOfferAcceptFile.fromSerializedOfferFile(offerAcceptFileMemo!);

    // XCH holder's side gets exchange info from details in offer file and offer accept file
    final xchHolderExchangeInfo =
        offerFile.getExchangeInfo(deserializedOfferAcceptFile, xchHolderPrivateKey);
    final xchHolderEscrowPuzzlehash = xchHolderExchangeInfo.escrowPuzzlehash;

    // the escrow puzzlehashes from the two sides should match
    expect(xchHolderExchangeInfo.escrowPuzzlehash, equals(btcHolderEscrowPuzzlehash));

    // XCH holder transfers XCH to escrow address
    final coinsForExchange = xchHolder.standardCoins;

    await xchToBtcService.sendXchToEscrowPuzzlehash(
      amount: xchHolderExchangeInfo.amountMojos,
      escrowPuzzlehash: xchHolderEscrowPuzzlehash,
      coinsInput: coinsForExchange,
      keychain: xchHolder.keychain,
      changePuzzlehash: xchHolder.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();

    final escrowCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([xchHolderEscrowPuzzlehash]);

    expect(escrowCoins.totalValue, equals(amountMojos));

    // after the BTC holder sees that XCH has arrived at the escrow address, they pay the lightning invoice.
    // the BTC holder inputs into the program the preimage that is revealed after payment and the puzzlehash
    // where they want to receive their XCH, which then creates and pushes a spend bundle to sweep funds
    final sweepPreimage =
        '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();
    final sweepPuzzlehash = btcHolder.firstPuzzlehash;
    final startingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    await btcToXchService.pushSweepSpendbundle(
      escrowPuzzlehash: btcHolderEscrowPuzzlehash,
      sweepPuzzlehash: sweepPuzzlehash,
      requestorPrivateKey: btcHolderPrivateKey,
      validityTime: postAcceptValidityTime,
      paymentHash: btcHolderExchangeInfo.paymentHash!,
      preimage: sweepPreimage,
      fulfillerPublicKey: xchHolderPublicKey,
    );

    await fullNodeSimulator.moveToNextBlock();

    final endingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    expect(
      endingSweepBalance,
      equals(startingSweepBalance + amountMojos),
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

    final offerFile = crossChainOfferService.createBtcToXchOfferFile(
      amountMojos: amountMojos,
      amountSatoshis: amountSatoshis,
      messageAddress: messageAddress,
      validityTime: validityTime,
      requestorPublicKey: btcHolderPublicKey,
    );

    final serializedOfferFile = offerFile.serialize(btcHolderPrivateKey);

    // A public/private key pair is generated for the XCH holder to use for the exchange
    final xchHolderPrivateKey = PrivateKey.generate();
    final xchHolderPublicKey = xchHolderPrivateKey.getG1();

    // XCH holder's side views offer, deserialized it, checks validity, and creates a cross chain offer accept file
    final deserializedOfferFile = BtcToXchOfferFile.fromSerializedOfferFile(serializedOfferFile);
    expect(() => CrossChainOfferService.checkValidity(deserializedOfferFile), returnsNormally);
    const postAcceptValidityTime = 600;

    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';
    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    final offerAcceptFile = crossChainOfferService.createXchToBtcAcceptFile(
      serializedOfferFile: serializedOfferFile,
      validityTime: postAcceptValidityTime,
      requestorPublicKey: xchHolderPublicKey,
      paymentRequest: decodedPaymentRequest,
    );

    final serializedOfferAcceptFile = offerAcceptFile.serialize(xchHolderPrivateKey);

    // XCH holder sends message coin with offer accept file to message puzzlehash and verifies receipt
    final messagePuzzlehash = deserializedOfferFile.messageAddress.toPuzzlehash();

    await crossChainOfferService.sendMessageCoin(
      keychain: xchHolder.keychain,
      coinsInput: [xchHolder.standardCoins.first],
      messagePuzzlehash: messagePuzzlehash,
      requestorPrivateKey: xchHolderPrivateKey,
      serializedOfferAcceptFile: serializedOfferAcceptFile,
      changePuzzlehash: xchHolder.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();

    final messageVerification = await crossChainOfferService.verifyMessageCoinReceipt(
      messagePuzzlehash,
      serializedOfferAcceptFile,
    );

    expect(messageVerification, equals(true));

    // XCH holder's side gets exchange info from offer file and offer accept file details
    final xchHolderExchangeInfo = offerAcceptFile.getExchangeInfo(offerFile, xchHolderPrivateKey);
    final xchHolderEscrowPuzzlehash = xchHolderExchangeInfo.escrowPuzzlehash;

    // BTC holder's side deserializes memo from the received coin
    final offerAcceptFileMemo = await crossChainOfferService
        .getOfferAcceptFileFromMessagePuzzlehash(messagePuzzlehash, serializedOfferFile);

    expect(offerAcceptFileMemo, equals(serializedOfferAcceptFile));

    final deserializedOfferAcceptFile =
        XchToBtcOfferAcceptFile.fromSerializedOfferFile(offerAcceptFileMemo!);

    // BTC holder's side gets escrow address from details in offer file and offer accept file
    final btcHolderExchangeInfo =
        offerFile.getExchangeInfo(deserializedOfferAcceptFile, btcHolderPrivateKey);
    final btcHolderEscrowPuzzlehash = btcHolderExchangeInfo.escrowPuzzlehash;

    // the escrow puzzlehashes on either side should match
    expect(btcHolderEscrowPuzzlehash, equals(xchHolderEscrowPuzzlehash));

    // XCH holder transfers XCH to escrow address
    await xchHolder.refreshCoins();
    final coinsForExchange = xchHolder.standardCoins;

    await xchToBtcService.sendXchToEscrowPuzzlehash(
      amount: xchHolderExchangeInfo.amountMojos,
      escrowPuzzlehash: xchHolderEscrowPuzzlehash,
      coinsInput: coinsForExchange,
      keychain: xchHolder.keychain,
      changePuzzlehash: xchHolder.firstPuzzlehash,
    );

    await fullNodeSimulator.moveToNextBlock();

    final escrowCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([xchHolderEscrowPuzzlehash]);

    expect(escrowCoins.totalValue, equals(amountMojos));

    // after the BTC holder sees that XCH has arrived at the escrow address, they pay the lightning invoice.
    // the BTC holder inputs into the program the preimage that is revealed after payment and the puzzlehash
    // where they want to receive their XCH, which then creates and pushes a spend bundle to sweep funds
    final sweepPreimage =
        '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();
    final sweepPuzzlehash = btcHolder.firstPuzzlehash;
    final startingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    await btcToXchService.pushSweepSpendbundle(
      escrowPuzzlehash: btcHolderEscrowPuzzlehash,
      sweepPuzzlehash: sweepPuzzlehash,
      requestorPrivateKey: btcHolderPrivateKey,
      validityTime: postAcceptValidityTime,
      paymentHash: btcHolderExchangeInfo.paymentHash!,
      preimage: sweepPreimage,
      fulfillerPublicKey: xchHolderPublicKey,
    );

    await fullNodeSimulator.moveToNextBlock();

    final endingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    expect(
      endingSweepBalance,
      equals(startingSweepBalance + amountMojos),
    );
  });
}
