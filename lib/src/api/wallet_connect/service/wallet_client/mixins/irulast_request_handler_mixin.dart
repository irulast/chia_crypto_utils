import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Creates a mapping of walletId to [ChiaWalletInfo] in order to conform to Chia's standard and holds
/// functionality for command execution methods that is shared between implementations of [WalletConnectRequestHandler].
mixin IrulastWalletConnectRequestHandlerMixin implements WalletConnectRequestHandler {
  Wallet get wallet;
  ChiaFullNodeInterface get fullNode;

  FutureOr<ChiaWalletInfo?> getWalletInfoForId(int walletId);

  Future<SignMessageByAddressResponse> executeSignMessageByAddress(
    SignMessageByAddressCommand command,
  ) async {
    final startedTimestamp = DateTime.now().unixTimestamp;
    final puzzlehash = command.address.toPuzzlehash();

    final keychain = await wallet.getKeychain();

    final walletVector = keychain.getWalletVector(puzzlehash);

    final syntheticSecretKey = calculateSyntheticPrivateKey(walletVector!.childPrivateKey);

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

    final syntheticSecretKey = calculateSyntheticPrivateKey(walletVector!.childPrivateKey);

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

  Future<VerifySignatureResponse> executeVerifySignature(VerifySignatureCommand command) async {
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
}
