import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

/// Used for connecting to wallets and requesting data from them via a [WalletConnectCommand].
class WalletConnectAppClient {
  WalletConnectAppClient(
    this._web3App,
    this.displayUri,
  );

  // factory WalletConnectAppClient.fromProjectId(
  //   String projectId, {
  //   required FutureOr<void> Function(Uri uri) displayUri,
  // }) {
  //   final web3App = Web3App(core: Core(projectId: projectId), metadata: defaultPairingMetadata);
  //   return WalletConnectAppClient(web3App, displayUri);
  // }

  final Web3App _web3App;
  final FutureOr<void> Function(Uri uri) displayUri;
  SessionData? _sessionData;

  /// throws [NotConnectedException] if not yet initialized
  SessionData get sessionData {
    if (_sessionData == null) {
      throw NotConnectedException();
    }
    return _sessionData!;
  }

  /// throws [NotConnectedException] if not yet initialized
  String get _topic {
    return sessionData.topic;
  }

  /// throws [NotConnectedException] if not yet initialized
  List<int> get fingerprints {
    return sessionData.fingerprints;
  }

  Future<void> init() => _web3App.init();

  /// Establish a connection with a new wallet
  Future<SessionData> pair({
    List<WalletConnectCommandType> requiredCommandTypes = const [],
  }) async {
    final methods = requiredCommandTypes.isNotEmpty
        ? requiredCommandTypes.commandNames
        : WalletConnectCommandType.values.commandNames;

    final connectResponse = await _web3App.connect(
      requiredNamespaces: {
        'chia': RequiredNamespace(
          chains: [walletConnectChainId],
          methods: methods,
          events: [],
        ),
      },
      methods: [],
    );

    final uri = connectResponse.uri;

    if (uri != null) {
      await displayUri(uri);
    }

    return _waitForSessionApproval(connectResponse);
  }

  /// Request a new session with a wallet that has already been paired. Previous session must still be active.
  Future<SessionData> requestNewSession({
    List<WalletConnectCommandType> requiredCommandTypes = const [],
    required String pairingTopic,
  }) async {
    if (_sessionData == null) {
      throw Exception('Must have already established pairing to reconnect.');
    }

    final methods = requiredCommandTypes.isNotEmpty
        ? requiredCommandTypes.map((type) => type.commandName).toList()
        : WalletConnectCommandType.values.commandNames;

    final connectResponse = await _web3App.connect(
      requiredNamespaces: {
        'chia': RequiredNamespace(
          chains: [walletConnectChainId],
          methods: methods,
          events: [],
        ),
      },
      pairingTopic: pairingTopic,
    );

    return _waitForSessionApproval(connectResponse);
  }

  Future<SessionData> _waitForSessionApproval(
    ConnectResponse connectResponse,
  ) async {
    print('waiting for session to be approved');
    try {
      final sessionData = await connectResponse.session.future;
      _sessionData = sessionData;

      print('wallet approved session');
      return sessionData;
    } catch (e) {
      if (e.toString().contains('User rejected')) {
        throw RejectedSessionProposalException();
      }

      if (e is JsonRpcError) {
        throw JsonRpcErrorWalletResponseException(e.message);
      }

      throw GeneralWalletResponseException(e.toString());
    }
  }

  List<PairingInfo> getPairings() => _web3App.pairings.getAll();

  Future<GetTransactionResponse> getTransaction({
    required int fingerprint,
    required String transactionId,
  }) async {
    return request(
      fingerprint: fingerprint,
      command:
          GetTransactionCommand(transactionId: Bytes.fromHex(transactionId)),
      parseResponse: GetTransactionResponse.fromJson,
    );
  }

  Future<GetWalletBalanceResponse> getWalletBalance({
    required int fingerprint,
    int? walletId = 1,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: GetWalletBalanceCommand(walletId: walletId),
      parseResponse: GetWalletBalanceResponse.fromJson,
    );
  }

  Future<GetNftsResponse> getNFTs({
    required int fingerprint,
    required List<int> walletIds,
    int? startIndex,
    int? num,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: GetNftsCommand(
        walletIds: walletIds,
        startIndex: startIndex,
        num: num,
      ),
      parseResponse: GetNftsResponse.fromJson,
    );
  }

  Future<GetNftInfoResponse> getNFTInfo({
    required int fingerprint,
    required Bytes coinId,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: GetNftInfoCommand(coinId: coinId),
      parseResponse: GetNftInfoResponse.fromJson,
    );
  }

  Future<GetNftCountResponse> getNFTsCount({
    required int fingerprint,
    required List<int> walletIds,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: GetNftsCountCommand(walletIds: walletIds),
      parseResponse: GetNftCountResponse.fromJson,
    );
  }

  Future<SignMessageByIdResponse> signMessageById({
    required int fingerprint,
    required Bytes id,
    required String message,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: SignMessageByIdCommand(message: message, id: id),
      parseResponse: SignMessageByIdResponse.fromJson,
    );
  }

  Future<SignMessageByAddressResponse> signMessageByAddress({
    required int fingerprint,
    required Address address,
    required String message,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: SignMessageByAddressCommand(message: message, address: address),
      parseResponse: SignMessageByAddressResponse.fromJson,
    );
  }

  Future<SignSpendBundleResponse> signSpendBundle({
    required int fingerprint,
    required SpendBundle spendBundle,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: SignSpendBundleCommand(spendBundle: spendBundle),
      parseResponse: SignSpendBundleResponse.fromJson,
    );
  }

  Future<VerifySignatureResponse> verifySignature({
    required int fingerprint,
    required JacobianPoint publicKey,
    required String message,
    required JacobianPoint signature,
    Address? address,
    SigningMode? signingMode,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: VerifySignatureCommand(
        address: address,
        message: message,
        signature: signature,
        publicKey: publicKey,
        signingMode: signingMode,
      ),
      parseResponse: VerifySignatureResponse.fromJson,
    );
  }

  Future<CheckOfferValidityResponse> checkOfferValidity({
    required int fingerprint,
    required Offer offer,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: CheckOfferValidityCommand(
        offer: offer,
      ),
      parseResponse: CheckOfferValidityResponse.fromJson,
    );
  }

  Future<TransferNftResponse> transferNFT({
    required int fingerprint,
    required int walletId,
    required Address targetAddress,
    required List<Bytes> nftCoinIds,
    required int fee,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: TransferNftCommand(
        walletId: walletId,
        fee: fee,
        targetAddress: targetAddress,
        nftCoinIds: nftCoinIds,
      ),
      parseResponse: TransferNftResponse.fromJson,
    );
  }

  Future<SendTransactionResponse> sendTransaction({
    required int fingerprint,
    int? walletId = 1,
    required Address address,
    required int amount,
    bool waitForConfirmation = false,
    required int fee,
    List<String>? memos,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: SendTransactionCommand(
        walletId: walletId,
        address: address,
        amount: amount,
        fee: fee,
        memos: memos ?? [],
        waitForConfirmation: waitForConfirmation,
      ),
      parseResponse: SendTransactionResponse.fromJson,
    );
  }

  Future<TakeOfferResponse> takeOffer({
    required int fingerprint,
    required String offer,
    required int fee,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: TakeOfferCommand(
        offer: offer,
        fee: fee,
      ),
      parseResponse: TakeOfferResponse.fromJson,
    );
  }

  Future<SendTransactionResponse> spendCat({
    required int fingerprint,
    required int walletId,
    required Address address,
    required int amount,
    required int fee,
    bool waitForConfirmation = false,
    List<String> memos = const [],
  }) async {
    return request(
      fingerprint: fingerprint,
      command: SpendCatCommand(
        walletId: walletId,
        address: address,
        waitForConfirmation: waitForConfirmation,
        amount: amount,
        fee: fee,
        memos: memos,
      ),
      parseResponse: SendTransactionResponse.fromJson,
    );
  }

  Future<GetAddressResponse> getCurrentAddress({
    required int fingerprint,
    int? walletId = 1,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: GetCurrentAddressCommand(
        walletId: walletId,
      ),
      parseResponse: GetAddressResponse.fromJson,
    );
  }

  Future<GetAddressResponse> getNextAddress({
    required int fingerprint,
    int? walletId = 1,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: GetNextAddressCommand(
        walletId: walletId,
      ),
      parseResponse: GetAddressResponse.fromJson,
    );
  }

  Future<GetSyncStatusResponse> getSyncStatus({
    required int fingerprint,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: const GetSyncStatus(),
      parseResponse: GetSyncStatusResponse.fromJson,
    );
  }

  Future<GetWalletsResponse> getWallets({
    required int fingerprint,
    ChiaWalletType? type,
    bool includeData = false,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: GetWalletsCommand(
        includeData: includeData,
        walletType: type,
      ),
      parseResponse: GetWalletsResponse.fromJson,
    );
  }

  Future<LogInResponse> logIn({
    required int fingerprint,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: LogInCommand(fingerprint: fingerprint),
      parseResponse: LogInResponse.fromJson,
    );
  }

  Future<CreateOfferForIdsResponse> createOfferForIds({
    required int fingerprint,
    required Map<String, int> offer,
    Map<String, dynamic> driverDict = const {},
    bool validateOnly = false,
    bool disableJsonFormatting = true,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: CreateOfferForIdsCommand(
        offerMap: offer,
        driverDict: driverDict,
        validateOnly: validateOnly,
        disableJsonFormatting: disableJsonFormatting,
      ),
      parseResponse: CreateOfferForIdsResponse.fromJson,
    );
  }

  Future<AddCatTokenResponse> addCatToken({
    required int fingerprint,
    required Puzzlehash assetId,
    required String name,
  }) async {
    return request(
      fingerprint: fingerprint,
      command: AddCatTokenCommand(assetId: assetId, name: name),
      parseResponse: AddCatTokenResponse.fromJson,
    );
  }

  Future<T> request<T>({
    required int fingerprint,
    required WalletConnectCommand command,
    required T Function(Map<String, dynamic> json) parseResponse,
  }) async {
    // fingerprint must be a string since that is the type the Chia lite wallet expects
    final request = SessionRequestParams(
      method: command.type.commandName,
      params: <String, dynamic>{
        'fingerprint': fingerprint.toString(),
        ...command.paramsToJson(),
      },
    );

    late final dynamic response;
    try {
      response = await _web3App.request(
        topic: _topic,
        chainId: walletConnectChainId,
        request: request,
      );
    } on JsonRpcError catch (e) {
      throw JsonRpcErrorWalletResponseException(e.message);
    } on Exception catch (e) {
      if (e.toString().contains('User rejected')) {
        throw RejectedRequestException();
      }

      throw GeneralWalletResponseException(e.toString());
    }

    final json = response as Map<String, dynamic>;
    try {
      final parsedResponse = parseResponse(json);

      return parsedResponse;
    } on Exception catch (e) {
      late final WalletConnectCommandErrorResponse? errorResponse;
      try {
        errorResponse = WalletConnectCommandErrorResponse.fromJson(json);
      } catch (_) {
        errorResponse = null;
        print(e);
        throw FailedResponseParsingException(response.toString());
      }

      throw ErrorResponseException(errorResponse);
    }
  }

  Future<void> disconnectSession() async {
    try {
      await _web3App.disconnectSession(
        topic: _topic,
        reason: Errors.getInternalError(Errors.EXPIRED),
      );
    } on NotConnectedException {
      // pass
    }
  }

  Future<void> disconnectPairing(String topic) async {
    await _web3App.core.pairing.disconnect(topic: topic);
  }
}

extension Fingerprints on SessionData {
  List<int> get fingerprints => namespaces['chia']!
      .accounts
      .map((account) => int.parse(account.split(':').last))
      .toList();
}

class NotConnectedException implements Exception {
  @override
  String toString() => 'WalletConnectAppClient is not connected yet';
}

class RejectedRequestException implements Exception {
  @override
  String toString() => 'WalletConnectAppClient request was rejected';
}

class RejectedSessionProposalException implements Exception {
  @override
  String toString() => 'WalletConnectAppClient session proposal was rejected';
}

class JsonRpcErrorWalletResponseException implements Exception {
  const JsonRpcErrorWalletResponseException(this.message);

  final String? message;

  @override
  String toString() =>
      'Wallet responded with JsonRpcError: $message. This may be due to user rejection or a request with the incorrect format or parameters';
}

class GeneralWalletResponseException implements Exception {
  const GeneralWalletResponseException(this.error);

  final String error;

  @override
  String toString() => 'Wallet responded with error: $error';
}

class ErrorResponseException implements Exception {
  const ErrorResponseException(this.response);

  final WalletConnectCommandErrorResponse response;

  @override
  String toString() {
    return 'Wallet responded with error: ${response.toJson()}';
  }
}

class FailedResponseParsingException implements Exception {
  const FailedResponseParsingException(this.response);

  final String response;

  @override
  String toString() => 'Failed to parse wallet response: $response';
}
