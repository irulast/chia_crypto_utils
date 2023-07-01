import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class FullNodeWalletConnectRequestHandler implements WalletConnectRequestHandler {
  FullNodeWalletConnectRequestHandler({
    required this.keychain,
    required this.coreSecret,
    required this.fullNode,
    this.approveRequest = true,
  }) : supportedCommands = fullNodeSupportedCommandTypes.commandNames;

  final ChiaFullNodeInterface fullNode;

  final WalletKeychain keychain;
  final KeychainCoreSecret coreSecret;
  bool approveRequest;

  final standardWalletService = StandardWalletService();
  final catWalletService = Cat2WalletService();

  @override
  Map<int, ChiaWalletInfo>? walletMap;

  @override
  List<String> supportedCommands;

  @override
  Future<void> indexWalletMap() async {
    final catCoins = <CatCoin>[];
    for (final puzzlehash in keychain.puzzlehashes) {
      final catCoinsByHint = await fullNode.getCatCoinsByHint(puzzlehash);
      catCoins.addAll(catCoinsByHint);
    }

    final assetIds = catCoins.map((catCoin) => catCoin.assetId).toSet().toList();

    final didRecords = await fullNode.getDidRecordsFromHints(keychain.puzzlehashes);

    final tempWalletMap = <int, ChiaWalletInfo>{1: StandardWalletInfo(coreSecret.fingerprint)};

    await _addNewWalletsInfos(
      tempWalletMap: tempWalletMap,
      assetIds: assetIds,
      didRecords: didRecords,
    );
  }

  @override
  Future<void> refreshWalletMap() async {
    if (walletMap == null) {
      throw WalletsUninitializedException();
    }

    final tempWalletMap = Map<int, ChiaWalletInfo>.from(walletMap!);

    final catCoins = <CatCoin>[];
    for (final puzzlehash in keychain.puzzlehashes) {
      final catCoinsByHint = await fullNode.getCatCoinsByHint(puzzlehash);
      catCoins.addAll(catCoinsByHint);
    }

    final assetIds = catCoins.map((catCoin) => catCoin.assetId).toSet().toList();

    final didRecords = await fullNode.getDidRecordsFromHints(keychain.puzzlehashes);
    final dids = didRecords.map((didRecord) => didRecord.did).toList();

    final walletIdsToRemove = <int>[];

    // cat wallets
    final currentAssetIds = tempWalletMap.catWallets().assetIds;

    final catWalletIdsToRemove =
        Map.fromEntries(currentAssetIds.entries.where((entry) => !assetIds.contains(entry.value)))
            .keys;
    walletIdsToRemove.addAll(catWalletIdsToRemove);

    final assetIdsToAdd =
        assetIds.where((assetId) => !currentAssetIds.containsValue(assetId)).toList();

    // did wallets
    final currentDids = tempWalletMap.didWallets().dids;

    final didWalletIdsToRemove =
        Map.fromEntries(currentDids.entries.where((entry) => !dids.contains(entry.value))).keys;
    walletIdsToRemove.addAll(didWalletIdsToRemove);

    final didRecordsToAdd = didRecords.where((did) => !currentDids.containsValue(did)).toList();

    tempWalletMap.removeWhere((key, value) => walletIdsToRemove.contains(key));

    await _addNewWalletsInfos(
      tempWalletMap: tempWalletMap,
      assetIds: assetIdsToAdd,
      didRecords: didRecordsToAdd,
    );
  }

  Future<void> _addNewWalletsInfos({
    required Map<int, ChiaWalletInfo> tempWalletMap,
    required List<Puzzlehash> assetIds,
    required List<DidRecord> didRecords,
  }) async {
    var id = tempWalletMap.keys.last;
    for (final assetId in assetIds) {
      id++;
      tempWalletMap[id] = CatWalletInfo.fromAssetId(assetId: assetId, id: id);
      keychain.addOuterPuzzleHashesForAssetId(assetId);
    }

    for (final didRecord in didRecords) {
      final didInfo = didRecord.toDidInfo(keychain);
      if (didInfo != null) {
        id++;
        tempWalletMap[id] = DIDWalletInfo.fromDID(did: didInfo, id: id);
      } else {
        LoggingContext().error(
          'Found did ${didRecord.did} does not belong to keychain ${coreSecret.fingerprint}',
        );
      }
    }

    walletMap = tempWalletMap;
  }

  @override
  Future<bool> handleRequest(String topic, WalletConnectCommand command) async {
    return approveRequest;
  }

  @override
  Future<CheckOfferValidityResponse> checkOfferValidity(CheckOfferValidityCommand command) {
    throw UnsupportedCommandException(command.type);
  }

  @override
  GetAddressResponse getCurrentAddress(GetCurrentAddressCommand command) {
    final startedTimeStamp = DateTime.now().unixTimeStamp;

    final address = Address.fromContext(keychain.puzzlehashes.first);

    return GetAddressResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimeStamp: startedTimeStamp,
      ),
      address,
    );
  }

  @override
  GetAddressResponse getNextAddress(GetNextAddressCommand command) {
    final startedTimeStamp = DateTime.now().unixTimeStamp;

    final address = Address.fromContext(
      keychain.addPuzzleHashes(coreSecret.masterPrivateKey, 1).unhardened.last,
    );

    return GetAddressResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimeStamp: startedTimeStamp,
      ),
      address,
    );
  }

  @override
  Future<GetNftInfoResponse> getNftInfo(GetNftInfoCommand command) async {
    throw UnsupportedCommandException(command.type);
  }

  @override
  GetNftsResponse getNfts(GetNftsCommand command) {
    throw UnsupportedCommandException(command.type);
  }

  @override
  GetNftCountResponse getNftsCount(GetNftsCountCommand command) {
    throw UnsupportedCommandException(command.type);
  }

  @override
  GetSyncStatusResponse getSyncStatus() {
    return GetSyncStatusResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: const GetSyncStatus(),
        startedTimeStamp: DateTime.now().unixTimeStamp,
      ),
      const SyncStatusData(
        genesisInitialized: true,
        synced: true,
        syncing: false,
      ),
    );
  }

  @override
  Future<GetTransactionResponse> getTransaction(GetTransactionCommand command) {
    throw UnsupportedCommandException(command.type);
  }

  @override
  Future<GetWalletBalanceResponse> getWalletBalance(GetWalletBalanceCommand command) async {
    final startedTimeStamp = DateTime.now().unixTimeStamp;

    if (walletMap == null) {
      throw WalletsUninitializedException();
    }

    final wallet = walletMap![command.walletId ?? 1];

    if (wallet == null) {
      throw InvalidWalletIdException();
    }

    final puzzlehashes = keychain.puzzlehashes;

    late final int coinCount;
    late final int balance;
    late final int pendingChange;
    late final int pendingCoinRemovalCount;
    late final int spendableBalance;
    if (wallet.type == ChiaWalletType.did || wallet.type == ChiaWalletType.nft) {
      coinCount = 1;
      balance = 1;
    } else if (wallet.type == ChiaWalletType.cat) {
      final catCoins = await fullNode.getCatCoinsByOuterPuzzleHashes(
        keychain.getOuterPuzzleHashesForAssetId((wallet as CatWalletInfo).assetId),
      );
      coinCount = catCoins.length;
      balance = catCoins.totalValue;
    } else {
      final coins = await fullNode.getCoinsByPuzzleHashes(puzzlehashes);
      coinCount = coins.length;
      balance = coins.totalValue;

      final mempoolItemsResponse = await fullNode.getAllMempoolItems();

      final additions = <CoinPrototype>[];
      final removals = <CoinPrototype>[];
      for (final mempoolItem in mempoolItemsResponse.mempoolItemMap.values) {
        for (final addition in mempoolItem.additions) {
          if (puzzlehashes.contains(addition.puzzlehash)) {
            additions.add(addition);
          }
        }

        for (final removal in mempoolItem.additions) {
          if (puzzlehashes.contains(removal.puzzlehash)) {
            removals.add(removal);
          }
        }
      }

      pendingChange = (additions.totalValue - removals.totalValue).abs();
      pendingCoinRemovalCount = removals.length;
      spendableBalance = balance - removals.totalValue;
    }

    return GetWalletBalanceResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimeStamp: startedTimeStamp,
      ),
      WalletBalance(
        confirmedWalletBalance: balance,
        fingerprint: coreSecret.fingerprint,
        maxSendAmount: spendableBalance,
        pendingChange: pendingChange,
        pendingCoinRemovalCount: pendingCoinRemovalCount,
        spendableBalance: spendableBalance,
        unconfirmedWalletBalance: balance - pendingChange,
        unspentCoinCount: coinCount,
        walletId: wallet.id,
        walletType: wallet.type,
      ),
    );
  }

  @override
  GetWalletsResponse getWallets(GetWalletsCommand command) {
    final startedTimeStamp = DateTime.now().unixTimeStamp;

    if (walletMap == null) {
      throw WalletsUninitializedException();
    }

    late final List<ChiaWalletInfo> walletsData;
    if (!command.includeData) {
      walletsData = walletMap!.values.map((wallet) => wallet.stripData()).toList();
    } else {
      walletsData = walletMap!.values.toList();
    }

    return GetWalletsResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimeStamp: startedTimeStamp,
      ),
      walletsData,
    );
  }

  @override
  Future<SendTransactionResponse> sendTransaction(SendTransactionCommand command) async {
    final startedTimeStamp = DateTime.now().unixTimeStamp;

    final walletId = command.walletId ?? 1;

    if (walletMap == null) {
      throw WalletsUninitializedException();
    }

    final wallet = walletMap![walletId];

    if (wallet == null) {
      throw InvalidWalletIdException();
    }

    final targetPuzzlehash = command.address.toPuzzlehash();

    final memos = command.memos?.map((memo) => Memo(Bytes.encodeFromString(memo))).toList() ?? [];

    late final SpendBundle spendBundle;
    if (wallet.type == ChiaWalletType.nft) {
      throw UnsupportedCommandException(command.type);
    } else if (wallet.type == ChiaWalletType.cat) {
      spendBundle = await _createCatSpendBundle(
        assetId: (wallet as CatWalletInfo).assetId,
        amount: command.amount,
        fee: command.fee,
        targetPuzzlehash: targetPuzzlehash,
        memos: memos,
      );
    } else {
      final allCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

      final coinsInput = selectCoinsForAmount(allCoins, command.amount);

      spendBundle = standardWalletService.createSpendBundle(
        payments: [Payment(command.amount, targetPuzzlehash, memos: memos)],
        coinsInput: coinsInput,
        keychain: keychain,
        changePuzzlehash: keychain.puzzlehashes[2],
        fee: command.fee,
      );
    }

    final response = await fullNode.pushTransaction(spendBundle);

    final transactionMemos =
        Map.fromEntries(spendBundle.coins.map((coin) => MapEntry(coin.id, memos)));

    if (command.waitForConfirmation) {
      final coinId = spendBundle.coins.first.id;

      final coin = await _waitForConfirmation(coinId);

      return SendTransactionResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimeStamp: startedTimeStamp,
        ),
        SentTransactionData(
          transaction: TransactionRecord(
            additions: spendBundle.additions,
            amount: command.amount,
            confirmed: true,
            confirmedAtHeight: coin.confirmedBlockIndex,
            createdAtTime: startedTimeStamp,
            feeAmount: command.fee,
            memos: transactionMemos,
            name: spendBundle.id,
            removals: spendBundle.removals,
            sent: 0,
            toAddress: command.address,
            toPuzzlehash: targetPuzzlehash,
            type: ChiaTransactionType.outgoing,
            walletId: walletId,
            spendBundle: spendBundle,
          ),
          transactionId: spendBundle.id,
          success: response.success,
        ),
      );
    } else {
      return SendTransactionResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimeStamp: startedTimeStamp,
        ),
        SentTransactionData(
          transaction: TransactionRecord(
            additions: spendBundle.additions,
            amount: command.amount,
            confirmed: false,
            confirmedAtHeight: 0,
            createdAtTime: startedTimeStamp,
            feeAmount: command.fee,
            memos: transactionMemos,
            name: spendBundle.id,
            removals: spendBundle.removals,
            sent: 0,
            toAddress: command.address,
            toPuzzlehash: targetPuzzlehash,
            type: ChiaTransactionType.outgoing,
            walletId: walletId,
            spendBundle: spendBundle,
          ),
          transactionId: spendBundle.id,
          success: response.success,
        ),
      );
    }
  }

  @override
  SignMessageByAddressResponse signMessageByAddress(SignMessageByAddressCommand command) {
    final startedTimeStamp = DateTime.now().unixTimeStamp;
    final puzzlehash = command.address.toPuzzlehash();

    final walletVector = keychain.getWalletVector(puzzlehash);

    final signature =
        AugSchemeMPL.sign(walletVector!.childPrivateKey, Bytes.encodeFromString(command.message));

    return SignMessageByAddressResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimeStamp: startedTimeStamp,
      ),
      SignMessageByAddressData(
        publicKey: walletVector.childPublicKey,
        signature: signature,
        signingMode: SigningMode.blsMessageAugHex,
        success: true,
      ),
    );
  }

  @override
  Future<SignMessageByIdResponse> signMessageById(SignMessageByIdCommand command) async {
    final startedTimeStamp = DateTime.now().unixTimeStamp;

    if (walletMap == null) {
      throw WalletsUninitializedException();
    }

    final didWallets = walletMap!.didWallets().values.where(
          (wallet) => wallet.didInfo.did == command.id,
        );

    if (didWallets.isEmpty) {
      throw InvalidDIDException();
    }

    final didInfo = didWallets.single.didInfo;

    final p2Puzzlehash = didInfo.p2Puzzle.hash();

    final walletVector = keychain.getWalletVector(p2Puzzlehash);

    final signature =
        AugSchemeMPL.sign(walletVector!.childPrivateKey, Bytes.encodeFromString(command.message));

    return SignMessageByIdResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimeStamp: startedTimeStamp,
      ),
      SignMessageByIdData(
        latestCoinId: didInfo.coin.id,
        publicKey: walletVector.childPublicKey,
        signature: signature,
        signingMode: SigningMode.blsMessageAugHex,
        success: true,
      ),
    );
  }

  Future<SpendBundle> _createCatSpendBundle({
    required Puzzlehash assetId,
    required int amount,
    required int fee,
    required Puzzlehash targetPuzzlehash,
    List<Memo> memos = const [],
  }) async {
    final catCoins = await fullNode
        .getCatCoinsByOuterPuzzleHashes(keychain.getOuterPuzzleHashesForAssetId(assetId));

    final allCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

    final coinsForFee = selectCoinsForAmount(allCoins, fee);

    return catWalletService.createSpendBundle(
      payments: [
        CatPayment(
          amount,
          targetPuzzlehash,
          memos: memos,
        )
      ],
      catCoinsInput: catCoins,
      keychain: keychain,
      changePuzzlehash: keychain.puzzlehashes[2],
      fee: fee,
      standardCoinsForFee: coinsForFee,
    );
  }

  @override
  Future<SendTransactionResponse> spendCat(SpendCatCommand command) async {
    final startedTimeStamp = DateTime.now().unixTimeStamp;

    if (walletMap == null) {
      throw WalletsUninitializedException();
    }

    final wallet = walletMap![command.walletId];

    if (wallet == null) {
      throw InvalidWalletIdException();
    }

    if (wallet.type != ChiaWalletType.cat) {
      throw const WrongWalletTypeException(ChiaWalletType.cat);
    }

    final catWallet = wallet as CatWalletInfo;

    final targetPuzzlehash = command.address.toPuzzlehash();

    final memos = command.memos.map((memo) => Memo(Bytes.encodeFromString(memo))).toList();

    final spendBundle = await _createCatSpendBundle(
      assetId: catWallet.assetId,
      amount: command.amount,
      fee: command.fee,
      targetPuzzlehash: targetPuzzlehash,
      memos: memos,
    );

    final response = await fullNode.pushTransaction(spendBundle);

    final transactionMemos =
        Map.fromEntries(spendBundle.coins.map((coin) => MapEntry(coin.id, memos)));

    final coinId = spendBundle.coins.first.id;

    if (command.waitForConfirmation) {
      final coin = await _waitForConfirmation(coinId);

      return SendTransactionResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimeStamp: startedTimeStamp,
        ),
        SentTransactionData(
          transaction: TransactionRecord(
            additions: spendBundle.additions,
            amount: command.amount,
            confirmed: true,
            confirmedAtHeight: coin.confirmedBlockIndex,
            createdAtTime: startedTimeStamp,
            feeAmount: command.fee,
            memos: transactionMemos,
            name: spendBundle.id,
            removals: spendBundle.removals,
            sent: 0,
            toAddress: command.address,
            toPuzzlehash: targetPuzzlehash,
            type: ChiaTransactionType.outgoing,
            walletId: wallet.id,
            spendBundle: spendBundle,
          ),
          transactionId: spendBundle.id,
          success: response.success,
        ),
      );
    } else {
      return SendTransactionResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimeStamp: startedTimeStamp,
        ),
        SentTransactionData(
          transaction: TransactionRecord(
            additions: spendBundle.additions,
            amount: command.amount,
            confirmed: false,
            confirmedAtHeight: 0,
            createdAtTime: startedTimeStamp,
            feeAmount: command.fee,
            memos: transactionMemos,
            name: spendBundle.id,
            removals: spendBundle.removals,
            sent: 0,
            toAddress: command.address,
            toPuzzlehash: targetPuzzlehash,
            type: ChiaTransactionType.outgoing,
            walletId: wallet.id,
            spendBundle: spendBundle,
          ),
          transactionId: spendBundle.id,
          success: response.success,
        ),
      );
    }
  }

  @override
  Future<TakeOfferResponse> takeOffer(TakeOfferCommand command) async {
    throw UnsupportedCommandException(command.type);
  }

  @override
  Future<TransferNftResponse> transferNft(TransferNftCommand command) async {
    throw UnsupportedCommandException(command.type);
  }

  @override
  VerifySignatureResponse verifySignature(VerifySignatureCommand command) {
    final startedTimeStamp = DateTime.now().unixTimeStamp;

    final verification = AugSchemeMPL.verify(
      command.publicKey,
      Bytes.encodeFromString(command.message),
      command.signature,
    );

    return VerifySignatureResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimeStamp: startedTimeStamp,
      ),
      VerifySignatureData(isValid: verification, success: true),
    );
  }

  @override
  FutureOr<LogInResponse> logIn(LogInCommand command) {
    final startedTimeStamp = DateTime.now().unixTimeStamp;

    // return true if fingerprint from command matches keychain fingerprint, else return false
    if (command.fingerprint == coreSecret.fingerprint) {
      return LogInResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimeStamp: startedTimeStamp,
        ),
        LogInData(fingerprint: coreSecret.fingerprint, success: true),
      );
    }

    return LogInResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimeStamp: startedTimeStamp,
      ),
      LogInData(fingerprint: coreSecret.fingerprint, success: false),
    );
  }

  Future<Coin> _waitForConfirmation(Bytes coinId) async {
    var coin = await fullNode.getCoinById(coinId);

    while (coin!.isNotSpent) {
      print('waiting for confirmation');
      await Future<void>.delayed(const Duration(seconds: 10));

      coin = await fullNode.getCoinById(coinId);
    }

    return coin;
  }
}

class WalletsUninitializedException implements Exception {
  @override
  String toString() {
    return 'Wallet must be initialized before using this method';
  }
}

class InvalidWalletIdException implements Exception {
  @override
  String toString() {
    return 'Invalid wallet ID';
  }
}

class WrongWalletTypeException implements Exception {
  const WrongWalletTypeException(this.type);

  final ChiaWalletType type;

  @override
  String toString() {
    return 'Wrong wallet type. Excepcted ${type.name}';
  }
}

class UnsupportedCommandException implements Exception {
  UnsupportedCommandException(this.commandType);

  WalletConnectCommandType commandType;

  @override
  String toString() {
    return "The full node implementation of the WalletConnectWalletClient doesn't support command $commandType";
  }
}

class InvalidNftCoinIdsException implements Exception {
  @override
  String toString() {
    return 'Invalid NFT coin IDs';
  }
}

class InvalidDIDException implements Exception {
  @override
  String toString() {
    return 'Could not find DID on keychain';
  }
}

const fullNodeSupportedCommandTypes = [
  WalletConnectCommandType.getCurrentAddress,
  WalletConnectCommandType.getNextAddress,
  WalletConnectCommandType.getSyncStatus,
  WalletConnectCommandType.getWalletBalance,
  WalletConnectCommandType.getWallets,
  WalletConnectCommandType.logIn,
  WalletConnectCommandType.sendTransaction,
  WalletConnectCommandType.signMessageByAddress,
  WalletConnectCommandType.signMessageById,
  WalletConnectCommandType.spendCAT,
  WalletConnectCommandType.verifySignature,
];
