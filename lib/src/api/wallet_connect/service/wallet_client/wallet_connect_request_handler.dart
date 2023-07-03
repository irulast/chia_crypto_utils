import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/wallet_connect/models/commands/wallet_connect_command_error_response.dart';

/// Handles request received from apps, allowing user to approve or reject, and executing the requested
/// command if approved.
abstract class WalletConnectRequestHandler {
  Map<int, ChiaWalletInfo>? get walletMap;

  /// Creates a mapping of walletId to [ChiaWalletInfo] for the sake of comforming to Chia's standard.
  Future<void> indexWalletMap();

  Future<void> refreshWalletMap();

  /// Displays request information to user and allows them to reject or approve the request.
  FutureOr<bool> handleRequest(String topic, WalletConnectCommand command);

  FutureOr<CheckOfferValidityResponse> checkOfferValidity(CheckOfferValidityCommand command);

  FutureOr<GetAddressResponse> getCurrentAddress(GetCurrentAddressCommand command);

  FutureOr<GetAddressResponse> getNextAddress(GetNextAddressCommand command);

  FutureOr<GetNftCountResponse> getNftsCount(GetNftsCountCommand command);

  FutureOr<GetNftInfoResponse> getNftInfo(GetNftInfoCommand command);

  FutureOr<GetNftsResponse> getNfts(GetNftsCommand command);

  FutureOr<GetSyncStatusResponse> getSyncStatus();

  FutureOr<GetTransactionResponse> getTransaction(GetTransactionCommand command);

  FutureOr<GetWalletBalanceResponse> getWalletBalance(GetWalletBalanceCommand command);

  FutureOr<GetWalletsResponse> getWallets(GetWalletsCommand command);

  FutureOr<SendTransactionResponse> sendTransaction(SendTransactionCommand command);

  FutureOr<SignMessageByAddressResponse> signMessageByAddress(SignMessageByAddressCommand command);

  FutureOr<SignMessageByIdResponse> signMessageById(SignMessageByIdCommand command);

  FutureOr<SendTransactionResponse> spendCat(SpendCatCommand command);

  FutureOr<TakeOfferResponse> takeOffer(TakeOfferCommand command);

  FutureOr<TransferNftResponse> transferNft(TransferNftCommand command);

  FutureOr<VerifySignatureResponse> verifySignature(VerifySignatureCommand command);

  FutureOr<LogInResponse> logIn(LogInCommand command);
}

extension ProcessRequest on WalletConnectRequestHandler {
  Future<ToJsonMixin> processRequest(
    WalletConnectCommandType type,
    String topic,
    dynamic params,
  ) async {
    try {
      final command = WalletConnectCommand.fromParams(type, params as Map<String, dynamic>);

      final approved = await handleRequest(topic, command);

      if (!approved) {
        throw UserRejectedRequestException();
      }

      try {
        late final ToJsonMixin response;
        switch (type) {
          case WalletConnectCommandType.getTransaction:
            response = await getTransaction(command as GetTransactionCommand);
            break;
          case WalletConnectCommandType.getWalletBalance:
            response = await getWalletBalance(command as GetWalletBalanceCommand);
            break;
          case WalletConnectCommandType.getNFTs:
            response = await getNfts(command as GetNftsCommand);
            break;
          case WalletConnectCommandType.getNFTInfo:
            response = await getNftInfo(command as GetNftInfoCommand);
            break;
          case WalletConnectCommandType.getNFTsCount:
            response = await getNftsCount(command as GetNftsCountCommand);
            break;
          case WalletConnectCommandType.signMessageById:
            response = await signMessageById(command as SignMessageByIdCommand);
            break;
          case WalletConnectCommandType.signMessageByAddress:
            response = await signMessageByAddress(command as SignMessageByAddressCommand);
            break;
          case WalletConnectCommandType.verifySignature:
            response = await verifySignature(command as VerifySignatureCommand);
            break;
          case WalletConnectCommandType.checkOfferValidity:
            response = await checkOfferValidity(command as CheckOfferValidityCommand);
            break;
          case WalletConnectCommandType.transferNFT:
            response = await transferNft(command as TransferNftCommand);
            break;
          case WalletConnectCommandType.sendTransaction:
            response = await sendTransaction(command as SendTransactionCommand);
            break;
          case WalletConnectCommandType.takeOffer:
            response = await takeOffer(command as TakeOfferCommand);
            break;
          case WalletConnectCommandType.getWallets:
            response = await getWallets(command as GetWalletsCommand);
            break;
          case WalletConnectCommandType.spendCAT:
            response = await spendCat(command as SpendCatCommand);
            break;
          case WalletConnectCommandType.getCurrentAddress:
            response = await getCurrentAddress(command as GetCurrentAddressCommand);
            break;
          case WalletConnectCommandType.getNextAddress:
            response = await getNextAddress(command as GetNextAddressCommand);
            break;
          case WalletConnectCommandType.getSyncStatus:
            response = await getSyncStatus();
            break;
          case WalletConnectCommandType.logIn:
            response = await logIn(command as LogInCommand);
            break;
        }

        return response;
      } catch (e, st) {
        print('Error processing request: $e');
        print(st);
        throw ErrorProcessingRequestException(e.toString());
      }
    } catch (e) {
      return WalletConnectCommandErrorResponse(
        WalletConnectCommandBaseResponseImp.error(
          endpointName: type,
          originalArgs: params as Map<String, dynamic>,
          startedTimeStamp: DateTime.now().unixTimeStamp,
        ),
        e.toString(),
      );
    }
  }
}

class ErrorProcessingRequestException implements Exception {
  const ErrorProcessingRequestException(this.error);

  final String error;

  @override
  String toString() {
    return 'Error processing WalletConnect app request: $error';
  }
}

class UserRejectedRequestException implements Exception {
  @override
  String toString() {
    return 'User rejected request.';
  }
}
