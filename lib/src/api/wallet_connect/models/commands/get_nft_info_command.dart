import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class GetNftInfoCommand implements WalletConnectCommand {
  const GetNftInfoCommand({
    required this.coinId,
  });
  factory GetNftInfoCommand.fromParams(Map<String, dynamic> params) {
    return GetNftInfoCommand(
      coinId: pick(params, 'coinId').asStringOrThrow().hexToBytes(),
    );
  }

  @override
  WalletConnectCommandType get type => WalletConnectCommandType.getNFTInfo;

  final Bytes coinId;

  @override
  Map<String, dynamic> paramsToJson() {
    return <String, dynamic>{'coinId': coinId.toHex()};
  }
}

class GetNftInfoResponse
    with ToJsonMixin, WalletConnectCommandResponseDecoratorMixin
    implements WalletConnectCommandBaseResponse {
  const GetNftInfoResponse(this.delegate, this.nftInfo);
  factory GetNftInfoResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = WalletConnectCommandBaseResponseImp.fromJson(json);

    final nftInfo = NftInfo.fromJson(pick(json, 'data').letJsonOrThrow((json) => json));
    return GetNftInfoResponse(baseResponse, nftInfo);
  }

  @override
  final WalletConnectCommandBaseResponse delegate;
  final NftInfo nftInfo;

  @override
  Map<String, dynamic> toJson() {
    return {
      ...delegate.toJson(),
      'data': nftInfo.toJson(),
    };
  }
}

class NftInfo {
  const NftInfo({
    required this.launcherId,
    required this.launcherPuzzlehash,
    required this.nftCoinId,
    required this.dataHash,
    required this.dataUris,
    required this.chainInfo,
    required this.licenseHash,
    required this.licenseUris,
    required this.metadataHash,
    required this.metadataUris,
    required this.mintHeight,
    this.ownerDid,
    required this.editionNumber,
    required this.editionTotal,
    required this.supportsDid,
    required this.updaterPuzzlehash,
    this.pendingTransaction = false,
    this.royaltyPercentage,
    this.royaltyPuzzlehash,
  });

  factory NftInfo.fromJson(Map<String, dynamic> json) {
    return NftInfo(
      launcherId: pick(json, 'launcherId').asStringOrThrow().hexToBytes(),
      launcherPuzzlehash: Puzzlehash.fromHex(pick(json, 'launcherPuzhash').asStringOrThrow()),
      nftCoinId: pick(json, 'nftCoinId').asStringOrThrow().hexToBytes(),
      dataHash: pick(json, 'dataHash').asStringOrThrow().hexToBytes(),
      dataUris: pick(json, 'dataUris').letStringListOrThrow((string) => string),
      chainInfo: pick(json, 'chainInfo').asStringOrThrow(),
      licenseHash: pick(json, 'licenseHash').asStringOrThrow().hexToBytes(),
      licenseUris: pick(json, 'licenseUris').letStringListOrThrow((string) => string),
      metadataHash: pick(json, 'metadataHash').asStringOrThrow().hexToBytes(),
      metadataUris: pick(json, 'metadataUris').letStringListOrThrow((string) => string),
      mintHeight: pick(json, 'mintHeight').asIntOrThrow(),
      ownerDid: pick(json, 'ownerDid').asStringOrNull()?.hexToBytes(),
      editionNumber: pick(json, 'editionNumber').asIntOrThrow(),
      editionTotal: pick(json, 'editionTotal').asIntOrThrow(),
      supportsDid: pick(json, 'supportsDid').asBoolOrThrow(),
      updaterPuzzlehash: Puzzlehash.fromHex(pick(json, 'updaterPuzhash').asStringOrThrow()),
      royaltyPercentage: pick(json, 'royaltyPercentage').asIntOrNull(),
      royaltyPuzzlehash: json['royaltyPuzzleHash'] != null
          ? Puzzlehash.fromHex(pick(json, 'royaltyPuzzleHash').asStringOrThrow())
          : null,
    );
  }

  factory NftInfo.fromNftRecordWithMintInfo(NftRecordWithMintInfo nftRecord) {
    final dataHash = nftRecord.metadata.dataHash;
    final dataUris = nftRecord.metadata.dataUris;
    final metadataHash = nftRecord.metadata.metaHash ?? Bytes.empty;
    final metadataUris = nftRecord.metadata.metaUris ?? [];
    final licenseHash = nftRecord.metadata.licenseHash ?? Bytes.empty;
    final licenseUris = nftRecord.metadata.licenseUris ?? [];

    return NftInfo(
      launcherId: nftRecord.launcherId,
      launcherPuzzlehash: nftRecord.singletonModHash,
      nftCoinId: nftRecord.coin.id,
      dataHash: dataHash,
      dataUris: dataUris,
      chainInfo: ChainInfo(
        dataUris: dataUris,
        dataHash: dataHash,
        metadataUris: metadataUris,
        licenseUris: licenseUris,
        metadataHash: metadataHash,
        licenseHash: licenseHash,
      ).toString(),
      licenseHash: licenseHash,
      licenseUris: licenseUris,
      metadataHash: metadataHash,
      metadataUris: metadataUris,
      mintHeight: nftRecord.mintInfo.mintHeight,
      editionNumber: nftRecord.metadata.editionNumber ?? 0,
      editionTotal: nftRecord.metadata.editionTotal ?? 0,
      supportsDid: nftRecord.doesSupportDid,
      updaterPuzzlehash: nftRecord.metadataUpdaterHash,
      ownerDid: nftRecord.ownershipLayerInfo?.currentDid,
      royaltyPercentage: nftRecord.ownershipLayerInfo?.royaltyPercentagePoints,
      royaltyPuzzlehash: nftRecord.ownershipLayerInfo?.royaltyPuzzleHash,
    );
  }
  final Bytes launcherId;
  final Puzzlehash launcherPuzzlehash;
  final Bytes nftCoinId;
  final Bytes dataHash;
  final List<String> dataUris;
  final String chainInfo;
  final Bytes licenseHash;
  final List<String> licenseUris;
  final Bytes metadataHash;
  final List<String> metadataUris;
  final int mintHeight;
  final bool pendingTransaction;
  final int editionNumber;
  final int editionTotal;
  final bool supportsDid;
  final Puzzlehash updaterPuzzlehash;
  final Bytes? ownerDid;
  final int? royaltyPercentage;
  final Puzzlehash? royaltyPuzzlehash;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'launcherId': launcherId.toHex(),
      'launcherPuzhash': launcherPuzzlehash.toHex(),
      'nftCoinId': nftCoinId.toHex(),
      'dataHash': dataHash.toHex(),
      'dataUris': dataUris,
      'chainInfo': chainInfo,
      'licenseHash': licenseHash.toHex(),
      'licenseUris': licenseUris,
      'metadataHash': metadataHash.toHex(),
      'metadataUris': metadataUris,
      'mintHeight': mintHeight,
      'ownerDid': ownerDid?.toHex(),
      'editionNumber': editionNumber,
      'editionTotal': editionTotal,
      'supportsDid': supportsDid,
      'updaterPuzhash': updaterPuzzlehash.toHex(),
      'royaltyPercentage': royaltyPercentage,
      'royaltyPuzzleHash': royaltyPuzzlehash?.toHex(),
    };
  }
}

class ChainInfo {
  const ChainInfo({
    required this.dataUris,
    required this.dataHash,
    required this.metadataUris,
    required this.licenseUris,
    required this.metadataHash,
    required this.licenseHash,
  });

  final List<String> dataUris;
  final Bytes dataHash;
  final List<String> metadataUris;
  final List<String> licenseUris;
  final Bytes metadataHash;
  final Bytes licenseHash;

  Program toProgram() {
    return Program.list(
      [
        Program.cons(Program.fromString('u'), Program.fromString(dataUris.toString())),
        Program.cons(Program.fromString('h'), Program.fromString(dataHash.toHex())),
        Program.cons(Program.fromString('mu'), Program.fromString(metadataUris.toString())),
        Program.cons(Program.fromString('lu'), Program.fromString(licenseUris.toString())),
        Program.cons(Program.fromString('sn'), Program.fromString(metadataHash.toHex())),
        Program.cons(Program.fromString('st'), Program.fromString(licenseHash.toHex())),
      ],
    );
  }

  @override
  String toString() => toProgram().toString();
}
