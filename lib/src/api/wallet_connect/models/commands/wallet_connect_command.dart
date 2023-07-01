import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class WalletConnectCommand {
  const WalletConnectCommand();

  factory WalletConnectCommand.fromParams(
    WalletConnectCommandType type,
    Map<String, dynamic> params,
  ) {
    switch (type) {
      case WalletConnectCommandType.getTransaction:
        return GetTransactionCommand.fromParams(params);
      case WalletConnectCommandType.getWalletBalance:
        return GetWalletBalanceCommand.fromParams(params);
      case WalletConnectCommandType.getNFTs:
        return GetNftsCommand.fromParams(params);
      case WalletConnectCommandType.getNFTInfo:
        return GetNftInfoCommand.fromParams(params);
      case WalletConnectCommandType.getNFTsCount:
        return GetNftsCountCommand.fromParams(params);
      case WalletConnectCommandType.signMessageById:
        return SignMessageByIdCommand.fromParams(params);
      case WalletConnectCommandType.signMessageByAddress:
        return SignMessageByAddressCommand.fromParams(params);
      case WalletConnectCommandType.verifySignature:
        return VerifySignatureCommand.fromParams(params);
      case WalletConnectCommandType.checkOfferValidity:
        return CheckOfferValidityCommand.fromParams(params);
      case WalletConnectCommandType.transferNFT:
        return TransferNftCommand.fromParams(params);
      case WalletConnectCommandType.sendTransaction:
        return SendTransactionCommand.fromParams(params);
      case WalletConnectCommandType.takeOffer:
        return TakeOfferCommand.fromParams(params);
      case WalletConnectCommandType.getWallets:
        return GetWalletsCommand.fromParams(params);
      case WalletConnectCommandType.spendCAT:
        return SpendCatCommand.fromParams(params);
      case WalletConnectCommandType.getCurrentAddress:
        return GetCurrentAddressCommand.fromParams(params);
      case WalletConnectCommandType.getNextAddress:
        return GetNextAddressCommand.fromParams(params);
      case WalletConnectCommandType.getSyncStatus:
        return const GetSyncStatus();
      case WalletConnectCommandType.logIn:
        return LogInCommand.fromParams(params);
    }
  }

  WalletConnectCommandType get type;

  Map<String, dynamic> paramsToJson();
}

enum WalletConnectCommandType {
  getTransaction,
  getWalletBalance,
  getNFTs,
  getNFTInfo,
  getNFTsCount,
  signMessageById,
  signMessageByAddress,
  verifySignature,
  checkOfferValidity,
  transferNFT,
  sendTransaction,
  takeOffer,
  getWallets,
  spendCAT,
  getCurrentAddress,
  getNextAddress,
  getSyncStatus,
  logIn;

  factory WalletConnectCommandType.fromString(String commandString) {
    return WalletConnectCommandType.values.where((value) => value.name == commandString).single;
  }

  factory WalletConnectCommandType.fromMethod(String method) {
    return WalletConnectCommandType.values.where((value) => value.commandName == method).single;
  }

  String get commandName => 'chia_$name';
}

extension CommandNames on List<WalletConnectCommandType> {
  List<String> get commandNames => map((command) => command.commandName).toList();
}
