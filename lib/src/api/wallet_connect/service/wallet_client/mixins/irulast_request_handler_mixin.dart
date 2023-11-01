import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Creates a mapping of walletId to [ChiaWalletInfo] in order to conform to Chia's standard and holds
/// functionality for command execution methods that is shared between implementations of [WalletConnectRequestHandler].
mixin IrulastWalletConnectRequestHandlerMixin
    implements WalletConnectRequestHandler {
  OfferService get offerService;
  Wallet get wallet;
  ChiaFullNodeInterface get fullNode;

  FutureOr<ChiaWalletInfo?> getWalletInfoForId(int walletId);
  FutureOr<List<NftInfo>> getNftInfosForWalletId(int walletId);

  Future<SignMessageByAddressResponse> executeSignMessageByAddress(
    SignMessageByAddressCommand command,
  ) async {
    final startedTimestamp = DateTime.now().unixTimestamp;
    final puzzlehash = command.address.toPuzzlehash();

    final keychain = await wallet.getKeychain();

    final walletVector = keychain.getWalletVector(puzzlehash);

    final syntheticSecretKey =
        calculateSyntheticPrivateKey(walletVector!.childPrivateKey);

    final message = constructChip002Message(command.message);

    final signature = await AugSchemeMPL.signAsync(syntheticSecretKey, message);

    return SignMessageByAddressResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      SignMessageByAddressData(
        publicKey: syntheticSecretKey.getG1(),
        signature: signature,
        signingMode: SigningMode.chip0002,
        success: true,
      ),
    );
  }

  Future<SignMessageByIdResponse> completeSignMessageById({
    required SignMessageByIdCommand command,
    required int startedTimestamp,
    required Puzzlehash p2Puzzlehash,
    required Bytes latestCoinId,
  }) async {
    final keychain = await wallet.getKeychain();

    final walletVector = keychain.getWalletVector(p2Puzzlehash);

    final syntheticSecretKey =
        calculateSyntheticPrivateKey(walletVector!.childPrivateKey);

    final message = constructChip002Message(command.message);

    final signature = await AugSchemeMPL.signAsync(syntheticSecretKey, message);

    return SignMessageByIdResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      SignMessageByIdData(
        latestCoinId: latestCoinId,
        publicKey: syntheticSecretKey.getG1(),
        signature: signature,
        signingMode: SigningMode.chip0002,
        success: true,
      ),
    );
  }

  Future<VerifySignatureResponse> executeVerifySignature(
      VerifySignatureCommand command) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    // default to CHIP-002 because that is how messages are signed with the sign methods on this handler
    final message = constructMessageForSignature(
      command.message,
      command.signingMode ?? SigningMode.chip0002,
    );

    final verification = await AugSchemeMPL.verifyAsync(
      command.publicKey,
      message,
      command.signature,
    );

    return VerifySignatureResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      VerifySignatureData(isValid: verification, success: true),
    );
  }

  static final dependentCoinService = DependentCoinWalletService();

  Future<ParsedOfferMap> parseAmountsFromOfferMap(
    Map<String, int> offerMap,
    Puzzlehash puzzlehash,
  ) async {
    var offeredXch = 0;
    final requestedStandard = <Payment>[];

    final offeredCat = <Puzzlehash, int>{};
    final requestedCat = <Puzzlehash, List<CatPayment>>{};

    final offeredNftLauncherIds = <Puzzlehash>{};
    final offeredNfts = <NftRecord>[];
    final requestedNftPayments = <NftRequestedPayment>[];

    for (final entry in offerMap.entries) {
      final amount = entry.value;
      final walletId = int.parse(entry.key);

      final walletInfo = await getWalletInfoForId(walletId);

      if (walletInfo == null) {
        throw InvalidWalletIdException();
      }

      if (walletInfo.type == ChiaWalletType.standard) {
        if (amount.isNegative) {
          offeredXch = amount.abs();
        } else {
          requestedStandard.add(Payment(amount, puzzlehash));
        }
      } else if (walletInfo.type == ChiaWalletType.cat) {
        final assetId = (walletInfo as CatWalletInfo).assetId;

        if (amount.isNegative) {
          offeredCat[assetId] = amount.abs();
        } else {
          requestedCat[assetId] = [CatPayment(amount, puzzlehash)];
        }
      } else if (walletInfo.type == ChiaWalletType.nft) {
        final nftInfos = await getNftInfosForWalletId(walletId);

        if (nftInfos.isEmpty) {
          throw EmptyNftWalletException();
        }

        final launcherId = Puzzlehash(nftInfos.first.launcherId);

        final nftRecord = await wallet.getNftRecordByLauncherId(launcherId);

        if (nftRecord == null) {
          throw InvalidNftException();
        }

        if (amount.isNegative) {
          offeredNftLauncherIds.add(launcherId);
          offeredNfts.add(nftRecord);
        } else {
          requestedNftPayments.add(NftRequestedPayment(launcherId, nftRecord));
        }
      } else {
        throw UnsupportedWalletTypeException(walletInfo.type);
      }
    }

    final offeredAmounts = MixedAmounts(
        standard: offeredXch, cat: offeredCat, nft: offeredNftLauncherIds);

    final requestedPayments = RequestedMixedPayments(
      standard: requestedStandard,
      cat: requestedCat,
      nfts: requestedNftPayments,
    );

    return ParsedOfferMap(
      offeredAmounts: offeredAmounts,
      requestedPayments: requestedPayments,
      offeredNfts: offeredNfts,
    );
  }

  Future<CheckOfferValidityResponse> executeCheckOfferValidity(
    CheckOfferValidityCommand command,
  ) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    final valid = await command.offer.validateCoins(fullNode);

    return CheckOfferValidityResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      OfferValidityData(valid: valid, id: command.offer.offeredSpendBundle.id),
    );
  }

  GetNftsResponse completeGetNfts({
    required GetNftsCommand command,
    required List<MapEntry<int, List<NftInfo>>> nftInfosMapEntries,
    required int startedTimestamp,
  }) {
    final start = command.startIndex ?? 0;

    final end = command.num != null && command.num! < nftInfosMapEntries.length
        ? (start + command.num!)
        : null;

    final nfts = Map.fromEntries(nftInfosMapEntries.sublist(start, end));

    return GetNftsResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      nfts,
    );
  }

  Future<SignSpendBundleResponse> executeSignSpendBundle(
      SignSpendBundleCommand command) async {
    final startedTimestamp = DateTime.now().unixTimestamp;

    final keychain = await wallet.getKeychain();

    final signedBundle = command.spendBundle.sign(keychain).signedBundle;

    return SignSpendBundleResponse(
      WalletConnectCommandBaseResponseImp.success(
        command: command,
        startedTimestamp: startedTimestamp,
      ),
      signedBundle.aggregatedSignature!,
    );
  }
}

class ParsedOfferMap {
  const ParsedOfferMap({
    required this.offeredAmounts,
    required this.requestedPayments,
    required this.offeredNfts,
  });

  final MixedAmounts offeredAmounts;
  final RequestedMixedPayments requestedPayments;
  final List<NftRecord> offeredNfts;

  Future<ParsedOffer> toParsedOffer() {
    return OfferWalletService.parseAmounts(
      offeredAmounts: offeredAmounts,
      requestedAmounts: requestedPayments.toMixedAmounts(),
      offeredNfts: offeredNfts,
    );
  }
}

class EmptyNftWalletException implements Exception {
  @override
  String toString() => 'NFT Wallet has no NFTs.';
}
