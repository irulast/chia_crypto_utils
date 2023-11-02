import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// a [Wallet] has access to a keychain and that keychain's coins
abstract class Wallet {
  ChiaFullNodeInterface get fullNode;
  Future<List<CatCoin>> getCatCoins();

  Future<List<NftRecordWithMintInfo>> getNftRecordsWithMintInfo();

  Future<List<DidInfoWithOriginCoin>> getDidInfosWithOriginCoin();

  FutureOr<WalletKeychain> getKeychain();

  Future<List<Coin>> getCoins();

  Future<List<CatCoin>> getCatCoinsByAssetId(
    Puzzlehash assetId, {
    int catVersion = 2,
  });

  Future<NftRecord?> getNftRecordByLauncherId(Bytes launcherId);
}

extension MixedCoinsGetterX on Wallet {
  /// throws
  /// [InsufficientStandardBalanceException],
  /// [InsufficientCatBalanceException], or
  /// [InsufficientNftBalanceException]
  ///  if there are not enough coins for a requested type
  Future<MixedCoins> getMixedCoinsForAmounts(
    MixedAmounts amounts, {
    int catVersion = 2,
  }) async {
    // standard
    final allCoins = await getCoins();
    final standardCoinsForOffer =
        selectStandardCoinsForAmount(allCoins, amounts.standard);

    // cat
    final catCoinsForOffer = <CatCoin>[];
    for (final requestedCat in amounts.cat.entries) {
      final catCoins =
          await getCatCoinsByAssetId(requestedCat.key, catVersion: catVersion);
      catCoinsForOffer.addAll(
        selectCatCoinsForAmount(
          catCoins,
          requestedCat.value,
          assetId: requestedCat.key,
        ),
      );
    }

    // nft
    final nftsForOffer = <Nft>[];

    for (final requestedNft in amounts.nft.entries) {
      final nftRecord = await getNftRecordByLauncherId(requestedNft.key);
      if (nftRecord == null) {
        LoggingContext()
            .error('could not find offer requested nft ${requestedNft.key}');
        throw InsufficientNftBalanceException(requestedNft.key);
      }
      try {
        final nft = nftRecord.toNft(await getKeychain());
        nftsForOffer.add(nft);
      } on KeyMismatchException {
        throw InsufficientNftBalanceException(requestedNft.key);
      }
    }

    return MixedCoins(
      standardCoins: standardCoinsForOffer,
      cats: catCoinsForOffer,
      nfts: nftsForOffer,
    );
  }
}

extension SendCoinsX on Wallet {
  Future<void> sendCat(
    Puzzlehash destinationPuzzlehash, {
    required int amount,
    required Puzzlehash assetId,
    Puzzlehash? changePuzzlehash,
    int fee = 50,
    int catVersion = 2,
  }) async {
    return sendCatForPayments(
      [CatPayment(amount, destinationPuzzlehash)],
      assetId: assetId,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      catVersion: catVersion,
    );
  }

  Future<void> sendCatForPayments(
    List<CatPayment> payments, {
    required Puzzlehash assetId,
    Puzzlehash? changePuzzlehash,
    int fee = 50,
    int catVersion = 2,
  }) async {
    final coins = await getCatCoinsByAssetId(assetId, catVersion: catVersion);
    final coinsForAmount =
        selectCatCoinsForAmount(coins, payments.totalValue, assetId: assetId);

    final standardCoins = await getCoins();

    final coinsForFee = selectStandardCoinsForAmount(standardCoins, fee);

    final walletService = CatWalletService.fromCatVersion(catVersion);

    final keychain = await getKeychain();

    final spendBundle = walletService.createSpendBundle(
      payments: payments,
      catCoinsInput: coinsForAmount,
      changePuzzlehash: changePuzzlehash ?? keychain.puzzlehashes.random,
      standardCoinsForFee: coinsForFee,
      fee: fee,
      keychain: keychain,
    );

    await fullNode.pushAndWaitForSpendBundle(spendBundle);
  }

  Future<void> sendXch(
    Puzzlehash destinationPuzzlehash, {
    required int amount,
    Puzzlehash? changePuzzlehash,
    int fee = 50,
  }) async {
    return sendXchForPayments(
      [Payment(amount, destinationPuzzlehash)],
      changePuzzlehash: changePuzzlehash,
      fee: fee,
    );
  }

  Future<void> sendXchForPayments(
    List<Payment> payments, {
    Puzzlehash? changePuzzlehash,
    int fee = 50,
  }) async {
    final coins = await getCoins();
    final coinsForAmount =
        selectStandardCoinsForAmount(coins, payments.totalValue);

    final walletService = StandardWalletService();

    final keychain = await getKeychain();

    final spendBundle = walletService.createSpendBundle(
      payments: payments,
      coinsInput: coinsForAmount,
      changePuzzlehash: changePuzzlehash ?? keychain.puzzlehashes.random,
      fee: fee,
      keychain: keychain,
    );

    await fullNode.pushAndWaitForSpendBundle(spendBundle);
  }
}
