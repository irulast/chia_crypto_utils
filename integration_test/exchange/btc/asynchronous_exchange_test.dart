// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
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
    final btcHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();

    // XCH holder generates a random private key to be used for the exchange
    final xchHolderPrivateKey = PrivateKey.generate();

    // XCH holder creates advertisement with the following details:
    const amountMojos = 10000000;
    const clawbackDelaySeconds = 5000;
    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';
    final xchHolderCoins = xchHolder.standardCoins;
    final xchHolderPublicKey = xchHolderPrivateKey.getG1();

    // BTC holder generates a random private key to be used for the exchange
    final btcHolderPrivateKey = PrivateKey.generate();
    final btcHolderPublicKey = btcHolderPrivateKey.getG1();

    // BTC holder views advertisement and accepts offer, their public key is sent to XCH holder
    // XCH holder inputs BTC holder's public key and program outputs exchange address that the
    // XCH holder should send funds to
    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);
    final sweepPaymentHash = decodedPaymentRequest.tags.paymentHash;

    final exchangePuzzlehash = xchToBtcService.generateExchangePuzzlehash(
      requestorPrivateKey: xchHolderPrivateKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash!,
      fulfillerPublicKey: btcHolderPublicKey,
    );

    // XCH holder transfers XCH to exchange address
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountMojos, exchangePuzzlehash)],
      coinsInput: xchHolderCoins,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      keychain: xchHolder.keychain,
    );
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final exchangeCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([exchangePuzzlehash]);

    // meanwhile, BTC holder inputs details from advertisement into their instance of the program
    // which constructs the exchange address for them as well, such that they can monitor when
    // the XCH has arrived at the exchange address

    // after the BTC holder sees that XCH has arrived at the exchange address, they pay the lightning invoice.
    // after the preimage is revealed, the BTC holder inputs the preimage, their disposable private key,
    // and the puzzlehash where they want to receive their XCH into the program, which then creates
    // and pushes a spend bundle to sweep funds to the BTC holder
    final sweepPreimage =
        '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();
    final sweepPuzzlehash = btcHolder.firstPuzzlehash;
    final startingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    final sweepSpendBundle = btcToXchService.createSweepSpendBundle(
      payments: [Payment(exchangeCoins.totalValue, sweepPuzzlehash)],
      coinsInput: exchangeCoins,
      requestorPrivateKey: btcHolderPrivateKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      sweepPreimage: sweepPreimage,
      fulfillerPublicKey: xchHolderPublicKey,
    );

    await fullNodeSimulator.pushTransaction(sweepSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSweepBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    expect(
      endingSweepBalance,
      equals(startingSweepBalance + exchangeCoins.totalValue),
    );
  });
}
