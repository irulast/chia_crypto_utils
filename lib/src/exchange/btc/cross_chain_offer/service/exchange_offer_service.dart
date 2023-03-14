import 'dart:collection';
import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class ExchangeOfferService {
  ExchangeOfferService(this.fullNode);

  final ChiaFullNodeInterface fullNode;
  final StandardWalletService standardWalletService = StandardWalletService();
  final BaseWalletService baseWalletService = BaseWalletService();

  Future<ChiaBaseResponse> pushInitializationSpendBundle({
    required Puzzlehash messagePuzzlehash,
    required CoinPrototype initializationCoin,
    required WalletKeychain keychain,
    required int derivationIndex,
    required String serializedOfferFile,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    final initializationSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          3,
          messagePuzzlehash,
          memos: <Memo>[
            Memo(encodeInt(derivationIndex)),
            Memo(Bytes.encodeFromString(serializedOfferFile)),
          ],
        )
      ],
      coinsInput: [initializationCoin],
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    final result = await fullNode.pushTransaction(initializationSpendBundle);

    return result;
  }

  Future<ChiaBaseResponse> cancelExchangeOffer({
    required Bytes initializationCoinId,
    required Puzzlehash messagePuzzlehash,
    required PrivateKey masterPrivateKey,
    required int derivationIndex,
    WalletKeychain? keychain,
    List<Coin> coinsForFee = const [],
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    final initializationCoin = await fullNode.getCoinById(initializationCoinId);
    final cancelCoinId = (await fullNode.getCoinSpend(initializationCoin!))!
        .additions
        .where((coin) => coin.puzzlehash == messagePuzzlehash && coin.amount == 3)
        .single
        .id;
    final cancelCoin = await fullNode.getCoinById(cancelCoinId);

    final walletVector = WalletVector.fromPrivateKey(
      masterPrivateKey,
      derivationIndex,
    );

    final exchangeWalletVector = WalletVector.fromPrivateKey(walletVector.childPrivateKey, 1);
    final hardenedMap = LinkedHashMap<Puzzlehash, WalletVector>();
    hardenedMap[exchangeWalletVector.puzzlehash] = exchangeWalletVector;

    final messagePuzzlehashKeychain = WalletKeychain(
      hardenedMap: hardenedMap,
      unhardenedMap: LinkedHashMap<Puzzlehash, UnhardenedWalletVector>(),
      singletonWalletVectorsMap: {},
    );

    final cancellationSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(3, initializationCoin.puzzlehash, memos: <Memo>[Memo(initializationCoinId)]),
      ],
      coinsInput: [cancelCoin!],
      keychain: messagePuzzlehashKeychain,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    final result = await fullNode.pushTransaction(cancellationSpendBundle);

    return result;
  }
}
