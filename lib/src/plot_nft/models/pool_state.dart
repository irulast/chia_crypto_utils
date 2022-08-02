import 'dart:convert';
import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/plot_nft/models/exceptions/invalid_plot_nft_exception.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';

class PoolState with ToBytesMixin {
  PoolState({
    this.version = 1,
    required this.poolSingletonState,
    required this.targetPuzzlehash,
    required this.ownerPublicKey,
    this.poolUrl,
    required this.relativeLockHeight,
  });

  final int version;
  final PoolSingletonState poolSingletonState;
  final Puzzlehash targetPuzzlehash;
  final JacobianPoint ownerPublicKey;
  final String? poolUrl;
  final int relativeLockHeight;

  @override
  Bytes toBytes() {
    var bytes = <int>[];
    bytes += intTo8Bits(version);
    bytes += intTo8Bits(poolSingletonState.code);
    bytes += targetPuzzlehash;
    bytes += ownerPublicKey.toBytes();
    if (poolUrl != null) {
      bytes += [1, ...serializeItem(poolUrl)];
    } else {
      bytes += [0];
    }
    bytes += intTo32Bits(relativeLockHeight);
    return Bytes(bytes);
  }

  factory PoolState.fromExtraDataProgram(Program extraDataProgram) {
    final extraDataConsBoxes = extraDataProgram.toList().where(
          (p) => String.fromCharCode(p.first().toInt()) == PlotNftExtraData.poolStateIdentifier,
        );
    if (extraDataConsBoxes.isEmpty || extraDataConsBoxes.length > 1) {
      throw InvalidPlotNftException();
    }
    final poolStateConsBox = extraDataConsBoxes.single;
    return PoolState.fromBytes(poolStateConsBox.rest().atom);
  }

  factory PoolState.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    return PoolState.fromStream(iterator);
  }

  factory PoolState.fromStream(Iterator<int> iterator) {
    final versionBytes = iterator.extractBytesAndAdvance(1);
    final version = bytesToInt(versionBytes, Endian.big);

    final poolSingletonStateBytes = iterator.extractBytesAndAdvance(1);
    final poolSingletonState = codeToPoolSingletonState(
      bytesToInt(poolSingletonStateBytes, Endian.big),
    );

    final targetPuzzlehash = Puzzlehash.fromStream(iterator);
    final ownerPublicKey = JacobianPoint.fromStreamG1(iterator);

    String? poolUrl;

    final poolUrlIsPresentBytes = iterator.extractBytesAndAdvance(1);
    if (poolUrlIsPresentBytes[0] == 1) {
      final lengthBytes = iterator.extractBytesAndAdvance(4);
      final poolUrlBytes = iterator.extractBytesAndAdvance(bytesToInt(lengthBytes, Endian.big));
      poolUrl = utf8.decode(poolUrlBytes);
    } else if (poolUrlIsPresentBytes[0] != 0) {
      throw ArgumentError('invalid isPresent bytes');
    }
    final relativeLockHeightBytes = iterator.extractBytesAndAdvance(4);
    final relativeLockHeight = bytesToInt(relativeLockHeightBytes, Endian.big);

    return PoolState(
      version: version,
      poolSingletonState: poolSingletonState,
      targetPuzzlehash: targetPuzzlehash,
      ownerPublicKey: ownerPublicKey,
      poolUrl: poolUrl,
      relativeLockHeight: relativeLockHeight,
    );
  }

  @override
  String toString() {
    return 'PoolState(version: $version, poolSingletonState: $poolSingletonState, targetPuzzlehash: $targetPuzzlehash, ownerPublicKey: $ownerPublicKey, poolUrl: $poolUrl, relativeLockHeight: $relativeLockHeight)';
  }
}

enum PoolSingletonState {
  selfPooling,
  leavingPool,
  farmingToPool,
}

extension PoolSingletonStateCode on PoolSingletonState {
  int get code {
    switch (this) {
      case PoolSingletonState.selfPooling:
        return 1;
      case PoolSingletonState.leavingPool:
        return 2;
      case PoolSingletonState.farmingToPool:
        return 3;
    }
  }
}

PoolSingletonState codeToPoolSingletonState(int code) {
  switch (code) {
    case 1:
      return PoolSingletonState.selfPooling;
    case 2:
      return PoolSingletonState.leavingPool;
    case 3:
      return PoolSingletonState.farmingToPool;
    default:
      throw ArgumentError('Invalid PoolSingletonState Code');
  }
}
