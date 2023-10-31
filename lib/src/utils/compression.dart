import 'dart:io';
import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/puzzles/p2_delegated_puzzle_or_hidden_puzzle/p2_delegated_puzzle_or_hidden_puzzle.clvm.hex.dart';

// cribbed from https://github.com/Chia-Network/chia-blockchain/blob/main/chia/wallet/util/puzzle_compression.py#L26
final zDict = [
  p2DelegatedPuzzleOrHiddenPuzzleProgram.toBytes() + cat1Program.toBytes(),
  settlementPaymentsProgramOld.toBytes(),
  singletonTopLayerV1Program.toBytes() +
      nftStateLayer.toBytes() +
      nftOwnershipLayerProgram.toBytes() +
      nftMetadataUpdaterDefault.toBytes() +
      nftTransferDefaultProgram.toBytes(),
  cat2Program.toBytes(),
  settlementPaymentsProgram.toBytes(),
  Bytes.empty,
];

Bytes zdictforVersion(int version) {
  var summedDictionary = Bytes.empty;
  for (final versionDictionary in zDict.sublist(0, version)) {
    summedDictionary += versionDictionary;
  }
  return summedDictionary;
}

Bytes compressWithZdict(Bytes blob, Bytes zDict) {
  final compressor = ZLibEncoder(dictionary: zDict);
  final compressedBlob = compressor.convert(blob);
  return Bytes(compressedBlob);
}

Bytes decompressWithZdict(Bytes blob, Bytes zDict) {
  final decompressor = ZLibDecoder(dictionary: zDict);
  final decompressedBlob = decompressor.convert(blob);
  return Bytes(decompressedBlob);
}

Bytes decompressObjectWithPuzzles(Bytes compressedObjectBlob) {
  final version = bytesToInt(compressedObjectBlob.sublist(0, 2), Endian.big);
  if (version > zDict.length) {
    throw ArgumentError('compression version is invalid');
  }
  final zdict = zdictforVersion(version);
  return decompressWithZdict(compressedObjectBlob.sublist(2), zdict);
}

Bytes compressObjectWithPuzzles(Bytes objectBytes, int version) {
  final versionBlob = intToBytes(version, 2, Endian.big);
  final zdict = zdictforVersion(version);
  final compressedObjectBlob = compressWithZdict(objectBytes, zdict);
  return versionBlob + compressedObjectBlob;
}

Bytes compressObjectWithPuzzlesOptimized(Bytes objectBytes) {
  Bytes? smallestCompression;

  for (var version = 0; version < zDict.length; version++) {
    final compressedBytes = compressObjectWithPuzzles(objectBytes, version);
    if (smallestCompression == null || compressedBytes.length < smallestCompression.length) {
      smallestCompression = compressedBytes;
    }
  }

  return smallestCompression!;
}
