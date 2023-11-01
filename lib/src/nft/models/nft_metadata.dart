import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

/// On chain NFT metadata
@immutable
class NftMetadata with ToBytesMixin {
  NftMetadata({
    required this.dataUris,
    required Bytes dataHash,
    this.metaUris,
    Bytes? metaHash,
    this.licenseUris,
    Bytes? licenseHash,
    this.editionNumber,
    this.editionTotal,
  })  : _dataHashProgram = Program.fromAtom(dataHash),
        _metaHashProgram = Program.maybeFromBytes(metaHash),
        _licenseHashProgram = Program.maybeFromBytes(licenseHash),
        _program = null;
  factory NftMetadata.fromBytes(Bytes bytes) {
    final program = Program.deserialize(bytes);
    return NftMetadata.fromProgram(program);
  }

  factory NftMetadata.fromProgram(Program program) {
    var dataUrisProgram = Program.list([]);
    var dataHashProgram = Program.fromInt(0);
    Program? metaUrisProgram;
    Program? metaHashProgram;
    Program? licenseUrisProgram;
    Program? licenseHashProgram;
    Program? editionNumberProgram;
    Program? editionTotalProgram;

    for (final keyValuePairProgram in program.toList()) {
      final key = utf8.decode(keyValuePairProgram.first().atom);
      final value = keyValuePairProgram.rest();

      switch (key) {
        case dataUrisKey:
          dataUrisProgram = value;
          break;
        case dataHashKey:
          dataHashProgram = value;
          break;
        case metaUrisKey:
          metaUrisProgram = value;
          break;
        case metaHashKey:
          metaHashProgram = value;
          break;
        case licenseUrisKey:
          licenseUrisProgram = value;
          break;
        case licenseHashKey:
          licenseHashProgram = value;
          break;
        case editionNumberKey:
          editionNumberProgram = value;
          break;
        case editionTotalKey:
          editionTotalProgram = value;
          break;
      }
    }
    return NftMetadata._(
      dataUris: dataUrisProgram.toList().map((e) => e.string).toList(),
      dataHashProgram: dataHashProgram,
      metaUris: metaUrisProgram?.toList().map((e) => e.string).toList(),
      metaHashProgram: metaHashProgram,
      licenseUris: licenseUrisProgram?.toList().map((e) => e.string).toList(),
      licenseHashProgram: licenseHashProgram,
      editionNumber: editionNumberProgram?.toInt(),
      editionTotal: editionTotalProgram?.toInt(),
      program: program,
    );
  }

  NftMetadata._({
    required this.dataUris,
    required Program dataHashProgram,
    required Program program,
    this.metaUris,
    Program? metaHashProgram,
    this.licenseUris,
    Program? licenseHashProgram,
    this.editionNumber,
    this.editionTotal,
  })  : _dataHashProgram = dataHashProgram,
        _metaHashProgram = metaHashProgram,
        _licenseHashProgram = licenseHashProgram,
        _program = program;

  static const dataUrisKey = 'u';
  static const dataHashKey = 'h';
  static const metaUrisKey = 'mu';
  static const metaHashKey = 'mh';
  static const licenseUrisKey = 'lu';
  static const licenseHashKey = 'lh';
  static const editionNumberKey = 'sn';
  static const editionTotalKey = 'st';

  Program toProgram() {
    if (_program != null) {
      return _program!;
    }
    return Program.list([
      Program.cons(
        Program.fromString(dataUrisKey),
        Program.list(dataUris.map(Program.fromString).toList()),
      ),
      Program.cons(
        Program.fromString(dataHashKey),
        _dataHashProgram,
      ),
      Program.cons(
        Program.fromString(metaUrisKey),
        Program.list(metaUris?.map(Program.fromString).toList() ?? []),
      ),
      Program.cons(
        Program.fromString(licenseUrisKey),
        Program.list(licenseUris?.map(Program.fromString).toList() ?? []),
      ),
      if (editionNumber != null)
        Program.cons(
          Program.fromString(editionNumberKey),
          Program.fromInt(editionNumber!),
        ),
      if (editionTotal != null)
        Program.cons(
          Program.fromString(editionTotalKey),
          Program.fromInt(editionTotal!),
        ),
      if (metaHash != null)
        Program.cons(
          Program.fromString(metaHashKey),
          _metaHashProgram!,
        ),
      if (licenseHash != null)
        Program.cons(
          Program.fromString(licenseHashKey),
          _licenseHashProgram!,
        ),
    ]);
  }

  // keep original program in case of parse for correct puzzle reveal
  final Program? _program;

  final List<String> dataUris;

  // store hashes as programs because someone could conceivably construct the nft puzzle with them as a hex string or as bytes
  // as demonstrated in chia tests
  // https://github.com/Chia-Network/chia-blockchain/blob/c26902a6ece013cf0a22fc5e5ff8131b9a1ef28a/tests/wallet/nft_wallet/test_nft_wallet.py#L129
  final Program _dataHashProgram;

  Bytes get dataHash => getBytesFromTypeAmbiguousProgram(_dataHashProgram)!;

  final List<String>? metaUris;
  final Program? _metaHashProgram;
  Bytes? get metaHash => getBytesFromTypeAmbiguousProgram(_metaHashProgram);

  final List<String>? licenseUris;
  final Program? _licenseHashProgram;
  Bytes? get licenseHash => getBytesFromTypeAmbiguousProgram(_licenseHashProgram);

  final int? editionNumber;

  final int? editionTotal;

  @override
  bool operator ==(Object other) =>
      other is NftMetadata && other.toProgram().hash() == toProgram().hash();

  @override
  int get hashCode => toProgram().hash().toHex().hashCode;

  @override
  Bytes toBytes() {
    return toProgram().toBytes();
  }

  static Bytes? getBytesFromTypeAmbiguousProgram(Program? program) =>
      (program != null && program != Program.nil) ? Bytes.fromHex(program.string) : null;
}

class NftMintingDataWithHashes extends NftMintingData with ToJsonMixin {
  const NftMintingDataWithHashes({
    required super.dataUri,
    required this.dataHash,
    required super.metaUri,
    required this.metaHash,
    required super.licenseUri,
    required this.licenseHash,
    required super.mintNumber,
    required super.isEditioned,
    super.targetPuzzlehash,
  });

  static Future<List<NftMintingDataWithHashes>> makeUniformBulkMintData({
    required UriHashProvider uriHashProvider,
    required String dataUri,
    required String metadataUri,
    required int editionTotal,
    required int totalNftsToMint,
    int editionMintStart = 1,
  }) async {
    final dataHash = await uriHashProvider.getHashForUri(dataUri);
    final metaHash = await uriHashProvider.getHashForUri(metadataUri);
    return NftMintingData.makeUniformBulkMintData(
      dataUri: dataUri,
      metadataUri: metadataUri,
      editionTotal: editionTotal,
      totalNftsToMint: totalNftsToMint,
    )
        .map(
          (e) => NftMintingDataWithHashes(
            dataUri: dataUri,
            dataHash: dataHash,
            metaUri: metadataUri,
            metaHash: metaHash,
            licenseUri: null,
            licenseHash: null,
            mintNumber: e.mintNumber,
            isEditioned: e.isEditioned,
          ),
        )
        .toList();
  }

  final Bytes dataHash;

  final Bytes? metaHash;

  final Bytes? licenseHash;

  NftMetadata toNftMetadata({
    required int? editionTotal,
  }) {
    return NftMetadata(
      dataUris: [dataUri],
      dataHash: dataHash,
      metaUris: metaUri == null ? null : [metaUri!],
      metaHash: metaHash,
      editionNumber: editionNumber,
      editionTotal: editionTotal,
      licenseUris: licenseUri == null ? null : [licenseUri!],
      licenseHash: licenseHash,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'data_hash': dataHash.toHex(),
      'meta_hash': metaHash?.toHex(),
      'license_hash': licenseHash?.toHex(),
    };
  }
}

class NftMintingData with ToJsonMixin {
  const NftMintingData({
    required this.dataUri,
    required this.metaUri,
    this.licenseUri,
    required this.mintNumber,
    required this.isEditioned,
    this.targetPuzzlehash,
  });

  const NftMintingData.editioned({
    required this.dataUri,
    required this.metaUri,
    this.licenseUri,
    required int editionNumber,
    this.targetPuzzlehash,
  })  : isEditioned = true,
        mintNumber = editionNumber;

  const NftMintingData.unEditioned({
    required this.dataUri,
    required this.metaUri,
    this.licenseUri,
    required this.mintNumber,
    this.targetPuzzlehash,
  }) : isEditioned = false;

  static List<NftMintingData> makeUniformBulkMintData({
    required String dataUri,
    required String metadataUri,
    required int editionTotal,
    required int totalNftsToMint,
    int editionMintStart = 1,
  }) {
    final editionMintEnd = editionMintStart + totalNftsToMint;

    final nftMintData = [
      for (var editionNumber = editionMintStart; editionNumber < editionMintEnd; editionNumber++)
        NftMintingData.editioned(
          dataUri: dataUri,
          metaUri: metadataUri,
          editionNumber: editionNumber,
        ),
    ];
    return nftMintData;
  }

  final String dataUri;

  final String? metaUri;

  final String? licenseUri;

  /// unique mint number of the nft. Represents edition number if [isEditioned] is true, otherwise it is used to maintain intermediate coin id uniqueness when bulk minting
  final int mintNumber;

  final bool isEditioned;

  int? get editionNumber => isEditioned ? mintNumber : null;

  final Puzzlehash? targetPuzzlehash;

  Bytes get id => Program.list([
        Program.fromString(dataUri),
        if (metaUri != null) Program.fromString(metaUri!),
        if (licenseUri != null) Program.fromString(licenseUri!),
        Program.fromInt(mintNumber),
      ]).hash();

  Future<NftMintingDataWithHashes> attachHashes(UriHashProvider hashProvider) async {
    return NftMintingDataWithHashes(
      dataUri: dataUri,
      dataHash: await hashProvider.getHashForUri(dataUri),
      metaUri: metaUri,
      mintNumber: mintNumber,
      metaHash: (metaUri != null) ? await hashProvider.getHashForUri(metaUri!) : null,
      licenseUri: licenseUri,
      licenseHash: licenseUri == null ? null : await hashProvider.getHashForUri(licenseUri!),
      isEditioned: isEditioned,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'data_uri': dataUri,
      'meta_uri': metaUri,
      if (licenseUri != null) 'license_uri': licenseUri,
      'edition_number': editionNumber,
      if (targetPuzzlehash != null) 'target_puzzlehash': targetPuzzlehash?.toHex(),
    };
  }
}

class InvalidNftDataException implements Exception {
  InvalidNftDataException(this.message);

  final String message;

  @override
  String toString() {
    return 'InvalidNftDataException: $message';
  }
}
