import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/session_models.dart';

class FullNodeWalletConnectRequestHandler
    with IrulastWalletConnectRequestHandlerMixin
    implements WalletConnectRequestHandler {
  FullNodeWalletConnectRequestHandler({
    required this.keychain,
    required this.coreSecret,
    required this.fullNode,
    this.approveRequest = true,
  });

  @override
  Wallet get wallet => ColdWallet(fullNode: fullNode, keychain: keychain);

  @override
  final ChiaFullNodeInterface fullNode;

  @override
  int get fingerprint => coreSecret.fingerprint;

  final WalletKeychain keychain;
  final KeychainCoreSecret coreSecret;
  bool approveRequest;

  final standardWalletService = StandardWalletService();
  final catWalletService = Cat2WalletService();

  Map<int, ChiaWalletInfo>? walletInfoMap;

  Future<void> initializeWalletMap() async {
    LoggingContext().info('Initializing wallet map');
    final catCoins = await wallet.getCatCoins();
    final assetIds = catCoins.map((catCoin) => catCoin.assetId).toSet();
    final didInfos = await wallet.getDidInfosWithOriginCoin();

    final tempWalletMap = <int, ChiaWalletInfo>{1: StandardWalletInfo()};

    await addNewWalletsInfos(
      tempWalletMap: tempWalletMap,
      assetIds: assetIds,
      didInfos: didInfos,
    );
  }

  Future<void> refreshWalletMap() async {
    LoggingContext().info('Refreshing wallet map');

    if (walletInfoMap == null) {
      throw WalletsUninitializedException();
    }

    final tempWalletMap = Map<int, ChiaWalletInfo>.from(walletInfoMap!);

    final catCoins = await wallet.getCatCoins();
    final assetIds = catCoins.map((catCoin) => catCoin.assetId).toSet().toList();
    final didInfos = await wallet.getDidInfosWithOriginCoin();
    final dids = didInfos.map((didRecord) => didRecord.did).toList();

    final walletIdsToRemove = <int>[];

    // cat wallets
    final currentAssetIds = tempWalletMap.catWallets().assetIdMap;

    final catWalletIdsToRemove =
        Map.fromEntries(currentAssetIds.entries.where((entry) => !assetIds.contains(entry.value)))
            .keys;
    walletIdsToRemove.addAll(catWalletIdsToRemove);

    final assetIdsToAdd =
        assetIds.where((assetId) => !currentAssetIds.containsValue(assetId)).toSet();

    // did wallets
    final currentDids = tempWalletMap.didWallets().didMap;

    final didWalletIdsToRemove =
        Map.fromEntries(currentDids.entries.where((entry) => !dids.contains(entry.value))).keys;
    walletIdsToRemove.addAll(didWalletIdsToRemove);

    final didInfosToAdd =
        didInfos.where((didInfo) => !currentDids.containsValue(didInfo.did)).toList();

    tempWalletMap.removeWhere((key, value) => walletIdsToRemove.contains(key));

    await addNewWalletsInfos(
      tempWalletMap: tempWalletMap,
      assetIds: assetIdsToAdd,
      didInfos: didInfosToAdd,
    );
  }

  Future<void> addNewWalletsInfos({
    required Map<int, ChiaWalletInfo> tempWalletMap,
    required Set<Puzzlehash> assetIds,
    required List<DidInfoWithOriginCoin> didInfos,
  }) async {
    var id = tempWalletMap.keys.last;

    // Add CAT Wallet for each kind of CAT owned
    for (final assetId in assetIds) {
      id++;
      tempWalletMap[id] = CatWalletInfo(assetId: assetId, id: id);
    }

    // Add DID wallet for each DID
    for (final didInfo in didInfos) {
      id++;
      tempWalletMap[id] = DIDWalletInfo(didInfoWithOriginCoin: didInfo, id: id);
    }

    walletInfoMap = tempWalletMap;
  }

  Future<void> indexWalletMap() async {
    if (walletInfoMap == null) {
      await initializeWalletMap();
    } else {
      await refreshWalletMap();
    }
  }

  @override
  ChiaWalletInfo getWalletInfoForId(int walletId) {
    if (walletInfoMap == null) {
      throw WalletsUninitializedException();
    }

    final wallet = walletInfoMap![walletId];

    if (wallet == null) {
      throw InvalidWalletIdException();
    }

    return wallet;
  }

  @override
  Future<WalletConnectCommandBaseResponse> handleRequest({
    required SessionData sessionData,
    required WalletConnectCommandType type,
    required dynamic params,
  }) async {
    try {
      if (!approveRequest) {
        throw UserRejectedRequestException();
      }

      final command = parseCommand(type, params);

      return executeCommand(command, sessionData);
    } catch (e) {
      return WalletConnectCommandErrorResponse(
        WalletConnectCommandBaseResponseImp.error(
          endpointName: type,
          originalArgs: params as Map<String, dynamic>,
          startedTimestamp: DateTime.now().unixTimestamp,
        ),
        e.toString(),
      );
    }
  }

  @override
  CheckOfferValidityResponse checkOfferValidity(
    CheckOfferValidityCommand command,
    SessionData sessionData,
  ) {
    throw UnsupportedCommandException(command.type);
  }

  @override
  GetAddressResponse getCurrentAddress(GetCurrentAddressCommand command, SessionData sessionData) {
    final startedTimestamp = DateTime.now().unixTimestamp;

    final address = Address.fromContext(keychain.puzzlehashes.first);

    return GetAddressResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      address,
    );
  }

  @override
  GetAddressResponse getNextAddress(GetNextAddressCommand command, SessionData sessionData) {
    final startedTimestamp = DateTime.now().unixTimestamp;

    final address = Address.fromContext(
      keychain.addPuzzleHashes(coreSecret.masterPrivateKey, 1).unhardened.last,
    );

    return GetAddressResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      address,
    );
  }

  @override
  GetSyncStatusResponse getSyncStatus(SessionData sessionData) {
    return GetSyncStatusResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: const GetSyncStatus(),
        startedTimestamp: DateTime.now().unixTimestamp,
      ),
      const SyncStatusData(
        genesisInitialized: true,
        synced: true,
        syncing: false,
      ),
    );
  }

  @override
  Future<GetTransactionResponse> getTransaction(
    GetTransactionCommand command,
    SessionData sessionData,
  ) {
    throw UnsupportedCommandException(command.type);
  }

  @override
  Future<GetWalletBalanceResponse> getWalletBalance(
    GetWalletBalanceCommand command,
    SessionData sessionData,
  ) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    await indexWalletMap();

    final wallet = getWalletInfoForId(command.walletId ?? 1);

    final puzzlehashes = keychain.puzzlehashes;

    late final int coinCount;
    late final int balance;

    final additions = <CoinPrototype>[];
    final removals = <CoinPrototype>[];
    if (wallet.type == ChiaWalletType.did) {
      coinCount = 0;
      balance = 0;
    } else if (wallet.type == ChiaWalletType.nft) {
      // according to Chia, NFT Wallets don't really have a balance
      coinCount = 0;
      balance = 0;
    } else if (wallet.type == ChiaWalletType.cat) {
      final outerPuzzlehashesForAssetId =
          keychain.getOuterPuzzleHashesForAssetId((wallet as CatWalletInfo).assetId);

      final catCoins = await fullNode.getCatCoinsByOuterPuzzleHashes(outerPuzzlehashesForAssetId);
      coinCount = catCoins.length;
      balance = catCoins.totalValue;

      final mempoolItemsResponse = await fullNode.getAllMempoolItems();

      final additions = <CoinPrototype>[];
      final removals = <CoinPrototype>[];
      for (final mempoolItem in mempoolItemsResponse.mempoolItemMap.values) {
        for (final addition in mempoolItem.additions) {
          if (outerPuzzlehashesForAssetId.contains(addition.puzzlehash)) {
            additions.add(addition);
          }
        }

        for (final removal in mempoolItem.additions) {
          if (outerPuzzlehashesForAssetId.contains(removal.puzzlehash)) {
            removals.add(removal);
          }
        }
      }
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
    }

    final pendingChange = (additions.totalValue - removals.totalValue).abs();
    final pendingCoinRemovalCount = removals.length;
    final spendableBalance = balance - removals.totalValue;

    return GetWalletBalanceResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
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
  Future<SendTransactionResponse> sendTransaction(
    SendTransactionCommand command,
    SessionData sessionData,
  ) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    final walletId = command.walletId ?? 1;

    await indexWalletMap();

    final wallet = getWalletInfoForId(walletId);

    final targetPuzzlehash = command.address.toPuzzlehash();

    final memos = command.memos.toMemos();

    late final SpendBundle spendBundle;
    if (wallet.type == ChiaWalletType.cat) {
      spendBundle = await _createCatSpendBundle(
        assetId: (wallet as CatWalletInfo).assetId,
        amount: command.amount,
        fee: command.fee,
        targetPuzzlehash: targetPuzzlehash,
        memos: memos,
      );
    } else if (wallet.type == ChiaWalletType.standard) {
      final allCoins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

      final coinsInput = selectCoinsForAmount(allCoins, command.amount);

      spendBundle = standardWalletService.createSpendBundle(
        payments: [Payment(command.amount, targetPuzzlehash, memos: memos)],
        coinsInput: coinsInput,
        keychain: keychain,
        changePuzzlehash: keychain.puzzlehashes[2],
        fee: command.fee,
      );
    } else {
      throw UnsupportedWalletTypeException(wallet.type);
    }

    final transactionMemos = makeTransactionMemos(spendBundle, memos);

    final transactionId = spendBundle.id.toHex();

    if (command.waitForConfirmation) {
      final coins = await fullNode.pushAndWaitForSpendBundle(spendBundle);

      return SendTransactionResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimestamp: startedTimestamp,
        ),
        SentTransactionData(
          transaction: TransactionRecord(
            additions: spendBundle.additions,
            amount: command.amount,
            confirmed: true,
            confirmedAtHeight: coins.first.confirmedBlockIndex,
            createdAtTime: startedTimestamp,
            feeAmount: command.fee,
            memos: transactionMemos,
            name: transactionId,
            removals: spendBundle.removals,
            sent: 0,
            toAddress: command.address,
            toPuzzlehash: targetPuzzlehash,
            type: ChiaTransactionType.outgoing,
            walletId: walletId,
            spendBundle: spendBundle,
          ),
          transactionId: spendBundle.id.toHex(),
          success: coins.isNotEmpty,
        ),
      );
    } else {
      final response = await fullNode.pushTransaction(spendBundle);

      return SendTransactionResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimestamp: startedTimestamp,
        ),
        SentTransactionData(
          transaction: TransactionRecord(
            additions: spendBundle.additions,
            amount: command.amount,
            confirmed: false,
            confirmedAtHeight: 0,
            createdAtTime: startedTimestamp,
            feeAmount: command.fee,
            memos: transactionMemos,
            name: transactionId,
            removals: spendBundle.removals,
            sent: 0,
            toAddress: command.address,
            toPuzzlehash: targetPuzzlehash,
            type: ChiaTransactionType.outgoing,
            walletId: walletId,
            spendBundle: spendBundle,
          ),
          transactionId: spendBundle.id.toHex(),
          success: response.success,
        ),
      );
    }
  }

  Future<SpendBundle> _createCatSpendBundle({
    required Puzzlehash assetId,
    required int amount,
    required int fee,
    required Puzzlehash targetPuzzlehash,
    List<Memo> memos = const [],
  }) async {
    final allCatCoins = await fullNode
        .getCatCoinsByOuterPuzzleHashes(keychain.getOuterPuzzleHashesForAssetId(assetId));

    final catCoins = selectCoinsForAmount(allCatCoins, amount);

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
  Future<SendTransactionResponse> spendCat(SpendCatCommand command, SessionData sessionData) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    await indexWalletMap();

    final wallet = getWalletInfoForId(command.walletId);

    if (wallet.type != ChiaWalletType.cat) {
      throw const WrongWalletTypeException(ChiaWalletType.cat);
    }

    final catWallet = wallet as CatWalletInfo;

    final targetPuzzlehash = command.address.toPuzzlehash();

    final memos = command.memos.toMemos();

    final spendBundle = await _createCatSpendBundle(
      assetId: catWallet.assetId,
      amount: command.amount,
      fee: command.fee,
      targetPuzzlehash: targetPuzzlehash,
      memos: memos,
    );

    final transactionMemos = makeTransactionMemos(spendBundle, memos);

    final transactionId = spendBundle.id.toHex();

    if (command.waitForConfirmation) {
      final coins = await fullNode.pushAndWaitForSpendBundle(spendBundle);

      return SendTransactionResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimestamp: startedTimestamp,
        ),
        SentTransactionData(
          transaction: TransactionRecord(
            additions: spendBundle.additions,
            amount: command.amount,
            confirmed: true,
            confirmedAtHeight: coins.first.confirmedBlockIndex,
            createdAtTime: startedTimestamp,
            feeAmount: command.fee,
            memos: transactionMemos,
            name: transactionId,
            removals: spendBundle.removals,
            sent: 0,
            toAddress: command.address,
            toPuzzlehash: targetPuzzlehash,
            type: ChiaTransactionType.outgoing,
            walletId: wallet.id,
            spendBundle: spendBundle,
          ),
          transactionId: spendBundle.id.toHex(),
          success: coins.isNotEmpty,
        ),
      );
    } else {
      final response = await fullNode.pushTransaction(spendBundle);

      return SendTransactionResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimestamp: startedTimestamp,
        ),
        SentTransactionData(
          transaction: TransactionRecord(
            additions: spendBundle.additions,
            amount: command.amount,
            confirmed: false,
            confirmedAtHeight: 0,
            createdAtTime: startedTimestamp,
            feeAmount: command.fee,
            memos: transactionMemos,
            name: transactionId,
            removals: spendBundle.removals,
            sent: 0,
            toAddress: command.address,
            toPuzzlehash: targetPuzzlehash,
            type: ChiaTransactionType.outgoing,
            walletId: wallet.id,
            spendBundle: spendBundle,
          ),
          transactionId: spendBundle.id.toHex(),
          success: response.success,
        ),
      );
    }
  }

  @override
  Future<TransferNftResponse> transferNft(
    TransferNftCommand command,
    SessionData sessionData,
  ) async {
    throw UnsupportedCommandException(command.type);
  }

  @override
  LogInResponse logIn(LogInCommand command, SessionData sessionData) {
    final startedTimestamp = DateTime.now().unixTimestamp;

    // return true if fingerprint from command matches keychain fingerprint, else return false
    if (command.fingerprint == coreSecret.fingerprint) {
      return LogInResponse(
        WalletConnectCommandBaseResponseImp.success(
          command: command,
          startedTimestamp: startedTimestamp,
        ),
        LogInData(fingerprint: coreSecret.fingerprint, success: true),
      );
    }

    return LogInResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      LogInData(fingerprint: coreSecret.fingerprint, success: false),
    );
  }

  @override
  Future<TakeOfferResponse> takeOffer(TakeOfferCommand command, SessionData sessionData) async {
    throw UnsupportedCommandException(command.type);
  }

  @override
  CreateOfferForIdsResponse createOfferForIds(
    CreateOfferForIdsCommand command,
    SessionData sessionData,
  ) {
    throw UnsupportedCommandException(command.type);
  }

  @override
  Future<GetNftInfoResponse> getNftInfo(GetNftInfoCommand command, SessionData sessionData) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    await indexWalletMap();

    final nftInfo = walletInfoMap!
        .nftWallets()
        .nftInfos
        .firstWhere((nftInfo) => nftInfo.nftCoinId == command.coinId);

    return GetNftInfoResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      nftInfo,
    );
  }

  @override
  GetNftsResponse getNfts(GetNftsCommand command, SessionData sessionData) {
    throw UnsupportedCommandException(command.type);
  }

  @override
  Future<GetNftCountResponse> getNftsCount(
    GetNftsCountCommand command,
    SessionData sessionData,
  ) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    await indexWalletMap();

    final countData = walletInfoMap!
        .nftWallets(command.walletIds)
        .map((key, value) => MapEntry(key.toString(), value.nftInfos.length));

    countData['total'] = countData.values.reduce((a, b) => a + b);

    return GetNftCountResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      countData,
    );
  }

  @override
  Future<GetWalletsResponse> getWallets(GetWalletsCommand command, SessionData sessionData) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    await indexWalletMap();

    late final List<ChiaWalletInfo> walletsData;
    if (!command.includeData) {
      walletsData = walletInfoMap!.values.map((wallet) => wallet.stripData()).toList();
    } else {
      walletsData = walletInfoMap!.values.toList();
    }

    return GetWalletsResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      walletsData,
    );
  }

  @override
  Future<SignMessageByAddressResponse> signMessageByAddress(
    SignMessageByAddressCommand command,
    SessionData sessionData,
  ) =>
      executeSignMessageByAddress(command);

  @override
  Future<SignMessageByIdResponse> signMessageById(
    SignMessageByIdCommand command,
    SessionData sessionData,
  ) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    await indexWalletMap();

    final didWallets = walletInfoMap!.didWallets().values.where(
          (wallet) => wallet.didInfoWithOriginCoin.did == command.id,
        );

    if (didWallets.isEmpty) {
      throw InvalidDIDException();
    }

    final didInfo = didWallets.single.didInfoWithOriginCoin;

    final p2Puzzlehash = didInfo.p2Puzzle.hash();

    return completeSignMessageById(
      command: command,
      startedTimestamp: startedTimestamp,
      p2Puzzlehash: p2Puzzlehash,
      latestCoinId: didInfo.coin.id,
    );
  }

  @override
  Future<VerifySignatureResponse> verifySignature(
    VerifySignatureCommand command,
    SessionData sessionData,
  ) =>
      executeVerifySignature(command);
}
