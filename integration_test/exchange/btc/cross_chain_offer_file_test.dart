import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/btc_to_xch_accept_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_accept_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';
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
      'should carry out asynchronous exchange with XCH holder creating their side of the exchange first',
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

    // BTC holder views offer and creates a cross chain offer accept file
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
    // from the XCH holder's offer file
    final messagePuzzlehash = messageAddress.toPuzzlehash();
    final coinForMessage = btcHolder.standardCoins.first;

    final messageSpendBundle = walletService.createSpendBundle(
      payments: [
        Payment(50, messagePuzzlehash, memos: <String>[serializedOfferAcceptFile])
      ],
      coinsInput: [coinForMessage],
      keychain: btcHolder.keychain,
      changePuzzlehash: btcHolder.firstPuzzlehash,
      fee: 50,
    );

    await fullNodeSimulator.pushTransaction(messageSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

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

    final coins = await fullNodeSimulator.getCoinsByPuzzleHashes(
      [messagePuzzlehash],
    );

    String? offerAcceptFileMemo;
    for (final coin in coins) {
      final parentCoin = await fullNodeSimulator.getCoinById(coin.parentCoinInfo);
      final coinSpend = await fullNodeSimulator.getCoinSpend(parentCoin!);
      final memos = await coinSpend!.memoStrings;
      offerAcceptFileMemo = memos.firstWhere((memo) => memo.startsWith('ccoffer_accept'));

      for (final memo in memos) {
        if (memo.startsWith('ccoffer_accept') &&
            (deserializeCrossChainOfferFile(memo) as CrossChainOfferAcceptFile).acceptedOfferHash ==
                Bytes.encodeFromString(serializedOfferFile).sha256Hash()) {
          offerAcceptFileMemo = memo;
        }
      }
    }

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
}
