import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:walletconnect_dart_v2_i/apis/sign_api/models/session_models.dart';

/// Handles request received from apps, allowing user to approve or reject, and executing the requested
/// command if approved.
abstract class WalletConnectRequestHandler {
  /// The fingerprint that the request handler is registered for. A request handler can only be
  /// registered for one fingerprint.
  int get fingerprint;

  /// Displays request information to user, allows them to reject or approve the request, then executes
  /// request upon approval.
  FutureOr<WalletConnectCommandBaseResponse> handleRequest({
    required SessionData sessionData,
    required WalletConnectCommandType type,
    required dynamic params,
  });

  FutureOr<CheckOfferValidityResponse> checkOfferValidity(
    CheckOfferValidityCommand command,
    SessionData sessionData,
  );

  FutureOr<GetAddressResponse> getCurrentAddress(
    GetCurrentAddressCommand command,
    SessionData sessionData,
  );

  FutureOr<GetAddressResponse> getNextAddress(
    GetNextAddressCommand command,
    SessionData sessionData,
  );

  FutureOr<GetNftCountResponse> getNftsCount(
    GetNftsCountCommand command,
    SessionData sessionData,
  );

  FutureOr<GetNftInfoResponse> getNftInfo(
    GetNftInfoCommand command,
    SessionData sessionData,
  );

  FutureOr<GetNftsResponse> getNfts(
    GetNftsCommand command,
    SessionData sessionData,
  );

  FutureOr<GetSyncStatusResponse> getSyncStatus(SessionData sessionData);

  FutureOr<GetTransactionResponse> getTransaction(
    GetTransactionCommand command,
    SessionData sessionData,
  );

  FutureOr<GetWalletBalanceResponse> getWalletBalance(
    GetWalletBalanceCommand command,
    SessionData sessionData,
  );

  FutureOr<GetWalletsResponse> getWallets(
    GetWalletsCommand command,
    SessionData sessionData,
  );

  FutureOr<SendTransactionResponse> sendTransaction(
    SendTransactionCommand command,
    SessionData sessionData,
  );

  FutureOr<SignMessageByAddressResponse> signMessageByAddress(
    SignMessageByAddressCommand command,
    SessionData sessionData,
  );

  FutureOr<SignMessageByIdResponse> signMessageById(
    SignMessageByIdCommand command,
    SessionData sessionData,
  );

  FutureOr<SendTransactionResponse> spendCat(
    SpendCatCommand command,
    SessionData sessionData,
  );

  FutureOr<TakeOfferResponse> takeOffer(
    TakeOfferCommand command,
    SessionData sessionData,
  );

  FutureOr<TransferNftResponse> transferNft(
    TransferNftCommand command,
    SessionData sessionData,
  );

  FutureOr<VerifySignatureResponse> verifySignature(
    VerifySignatureCommand command,
    SessionData sessionData,
  );

  FutureOr<LogInResponse> logIn(LogInCommand command, SessionData sessionData);

  FutureOr<SignSpendBundleResponse> signSpendBundle(
    SignSpendBundleCommand command,
    SessionData sessionData,
  );
  FutureOr<CreateOfferForIdsResponse> createOfferForIds(
    CreateOfferForIdsCommand command,
    SessionData sessionData,
  );
  FutureOr<AddCatTokenResponse> addCatToken(
    AddCatTokenCommand command,
    SessionData sessionData,
  );
}

extension CommandMethods on WalletConnectRequestHandler {
  WalletConnectCommand parseCommand(
    WalletConnectCommandType type,
    dynamic params,
  ) {
    try {
      return WalletConnectCommand.fromParams(
        type,
        params as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorParsingWalletConnectCommand();
    }
  }

  Future<WalletConnectCommandBaseResponse> executeCommand(
    WalletConnectCommand command,
    SessionData sessionData,
  ) async {
    try {
      late final WalletConnectCommandBaseResponse response;
      switch (command.type) {
        case WalletConnectCommandType.getTransaction:
          response = await getTransaction(
            command as GetTransactionCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.getWalletBalance:
          response = await getWalletBalance(
            command as GetWalletBalanceCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.getNFTs:
          response = await getNfts(command as GetNftsCommand, sessionData);
          break;
        case WalletConnectCommandType.getNFTInfo:
          response =
              await getNftInfo(command as GetNftInfoCommand, sessionData);
          break;
        case WalletConnectCommandType.getNFTsCount:
          response =
              await getNftsCount(command as GetNftsCountCommand, sessionData);
          break;
        case WalletConnectCommandType.signMessageById:
          response = await signMessageById(
            command as SignMessageByIdCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.signMessageByAddress:
          response = await signMessageByAddress(
            command as SignMessageByAddressCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.verifySignature:
          response = await verifySignature(
            command as VerifySignatureCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.checkOfferValidity:
          response = await checkOfferValidity(
            command as CheckOfferValidityCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.transferNFT:
          response =
              await transferNft(command as TransferNftCommand, sessionData);
          break;
        case WalletConnectCommandType.sendTransaction:
          response = await sendTransaction(
            command as SendTransactionCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.takeOffer:
          response = await takeOffer(command as TakeOfferCommand, sessionData);
          break;
        case WalletConnectCommandType.getWallets:
          response =
              await getWallets(command as GetWalletsCommand, sessionData);
          break;
        case WalletConnectCommandType.spendCAT:
          response = await spendCat(command as SpendCatCommand, sessionData);
          break;
        case WalletConnectCommandType.getCurrentAddress:
          response = await getCurrentAddress(
            command as GetCurrentAddressCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.getNextAddress:
          response = await getNextAddress(
            command as GetNextAddressCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.getSyncStatus:
          response = await getSyncStatus(sessionData);
          break;
        case WalletConnectCommandType.logIn:
          response = await logIn(command as LogInCommand, sessionData);
          break;
        case WalletConnectCommandType.createOfferForIds:
          response = await createOfferForIds(
            command as CreateOfferForIdsCommand,
            sessionData,
          );
          break;

        case WalletConnectCommandType.signSpendBundle:
          response = await signSpendBundle(
            command as SignSpendBundleCommand,
            sessionData,
          );
          break;
        case WalletConnectCommandType.addCATToken:
          response =
              await addCatToken(command as AddCatTokenCommand, sessionData);
          break;
      }

      return response;
    } catch (e, st) {
      LoggingContext().error('$e $st');
      throw ErrorProcessingRequestException(e.toString());
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
    return "The full node implementation of the WalletConnectWalletClient doesn't support command ${commandType.commandName}";
  }
}

class InvalidNftCoinIdsException implements Exception {
  @override
  String toString() {
    return 'Invalid NFT coin IDs';
  }
}

class RequestedNftAlreadyOwnedException implements Exception {
  @override
  String toString() {
    return "You can't request an NFT you already own.";
  }
}

class UnsupportedWalletTypeException implements Exception {
  const UnsupportedWalletTypeException(this.type);

  final ChiaWalletType type;

  @override
  String toString() {
    return 'This command cannot be executd with wallet type ${type.name}';
  }
}

class InvalidDIDException implements Exception {
  @override
  String toString() {
    return 'Could not find DID on keychain';
  }
}

class ErrorParsingWalletConnectCommand implements Exception {
  @override
  String toString() {
    return 'Failed to parse WalletConnect command from request.';
  }
}
