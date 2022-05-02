// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class WalletVector with ToBytesMixin {
  WalletVector({
    required this.childPrivateKey,
    required this.childPublicKey,
    required this.puzzlehash,
    Map<Puzzlehash, Puzzlehash>? assetIdtoOuterPuzzlehash,
  }) {
    this.assetIdtoOuterPuzzlehash = assetIdtoOuterPuzzlehash ?? {};
  }
  late final Map<Puzzlehash, Puzzlehash> assetIdtoOuterPuzzlehash;

  factory WalletVector.fromBytes(Bytes bytes) {
    var length = bytes[0];
    var left = 1;
    var right = left + length;

    final childPrivateKey = PrivateKey.fromBytes(bytes.sublist(left, right));

    length = bytes[right];
    left = right + 1;
    right = left + length;
    final childPublicKey = JacobianPoint.fromBytes(
      bytes.sublist(left, right),
      bytes[right] == 1,
    );

    length = bytes[right + 1];
    left = right + 2;
    right = left + length;

    final puzzlehash = Puzzlehash(bytes.sublist(left, right));

    return WalletVector(
      childPrivateKey: childPrivateKey,
      childPublicKey: childPublicKey,
      puzzlehash: puzzlehash,
    );
  }

  factory WalletVector.fromPrivateKey(
    PrivateKey masterPrivateKey,
    int derivationIndex,
  ) {
    final childPrivateKeyHardened =
        masterSkToWalletSk(masterPrivateKey, derivationIndex);
    final childPublicKeyHardened = childPrivateKeyHardened.getG1();

    final puzzleHardened = getPuzzleFromPk(childPublicKeyHardened);
    final puzzlehashHardened = Puzzlehash(puzzleHardened.hash());

    return WalletVector(
      childPrivateKey: childPrivateKeyHardened,
      childPublicKey: childPublicKeyHardened,
      puzzlehash: puzzlehashHardened,
    );
  }

  final PrivateKey childPrivateKey;
  final JacobianPoint childPublicKey;
  final Puzzlehash puzzlehash;

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      childPrivateKey.hashCode ^
      childPublicKey.hashCode ^
      puzzlehash.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WalletVector &&
            runtimeType == other.runtimeType &&
            childPrivateKey == other.childPrivateKey &&
            childPublicKey == other.childPublicKey &&
            puzzlehash == other.puzzlehash;
  }

  @override
  Bytes toBytes() {
    final childPrivateKeyBytes = childPrivateKey.toBytes();
    final childPublicKeyBytes = childPublicKey.toBytes();
    final puzzlehashBytes = puzzlehash;

    return Bytes([
      childPrivateKeyBytes.length,
      ...childPrivateKeyBytes,
      childPublicKeyBytes.length,
      ...childPublicKeyBytes,
      if (childPublicKey.isExtension) 1 else 0,
      puzzlehashBytes.length,
      ...puzzlehashBytes,
    ]);
  }

  Map<String, dynamic> toMap() {
    final assetIdtoOuterPuzzlehashMap = <String, String>{};
    assetIdtoOuterPuzzlehash.forEach((key, value) {
      assetIdtoOuterPuzzlehashMap[key.toHex()] = value.toHex();
    });

    final map = <String, dynamic>{};
    map['childPrivateKey'] = childPrivateKey.toHex();
    map['childPublicKey'] = childPublicKey.toHex();
    map['puzzlehash'] = puzzlehash.toHex();
    map['assetIdtoOuterPuzzlehash'] = assetIdtoOuterPuzzlehashMap;

    return map;
  }

  factory WalletVector.fromMap(Map<String, dynamic> map) {
    final childPrivateKey =
        PrivateKey.fromHex(map['childPrivateKey'] as String);
    final childPublicKey = childPrivateKey.getG1();
    final puzzlehash = Puzzlehash.fromHex(map['puzzlehash'] as String);

    final assetIdtoOuterPuzzlehashMap = <Puzzlehash, Puzzlehash>{};
    final assetIdtoOuterPuzzlehash = Map<String, String>.from(
      map['assetIdtoOuterPuzzlehash'] as Map<String, dynamic>,
    );

    // ignore: cascade_invocations
    assetIdtoOuterPuzzlehash.forEach((key, value) {
      assetIdtoOuterPuzzlehashMap[Puzzlehash.fromHex(key)] =
          Puzzlehash.fromHex(value);
    });

    return WalletVector(
      childPrivateKey: childPrivateKey,
      childPublicKey: childPublicKey,
      puzzlehash: puzzlehash,
      assetIdtoOuterPuzzlehash: assetIdtoOuterPuzzlehashMap,
    );
  }
}

class UnhardenedWalletVector extends WalletVector {
  UnhardenedWalletVector({
    required PrivateKey childPrivateKey,
    required JacobianPoint childPublicKey,
    required Puzzlehash puzzlehash,
    Map<Puzzlehash, Puzzlehash>? assetIdtoOuterPuzzlehash,
  })  : assetIdtoOuterPuzzlehash =
            assetIdtoOuterPuzzlehash ?? <Puzzlehash, Puzzlehash>{},
        super(
          childPrivateKey: childPrivateKey,
          childPublicKey: childPublicKey,
          puzzlehash: puzzlehash,
        );

  factory UnhardenedWalletVector.fromPrivateKey(
    PrivateKey masterPrivateKey,
    int derivationIndex,
  ) {
    final childPrivateKeyUnhardened =
        masterSkToWalletSkUnhardened(masterPrivateKey, derivationIndex);
    final childPublicKeyUnhardened = childPrivateKeyUnhardened.getG1();

    final puzzleUnhardened = getPuzzleFromPk(childPublicKeyUnhardened);
    final puzzlehashUnhardened = Puzzlehash(puzzleUnhardened.hash());

    return UnhardenedWalletVector(
      childPrivateKey: childPrivateKeyUnhardened,
      childPublicKey: childPublicKeyUnhardened,
      puzzlehash: puzzlehashUnhardened,
    );
  }

  @override
  Bytes toBytes() {
    final childPrivateKeyBytes = childPrivateKey.toBytes();
    final childPublicKeyBytes = childPublicKey.toBytes();
    final puzzlehashBytes = puzzlehash;

    final assetIdMapBytes = <int>[];
    assetIdtoOuterPuzzlehash.forEach((assetId, outerPuzzlehash) {
      assetIdMapBytes
        ..addAll(assetId)
        ..addAll(outerPuzzlehash);
    });

    return Bytes([
      childPrivateKeyBytes.length,
      ...childPrivateKeyBytes,
      childPublicKeyBytes.length,
      ...childPublicKeyBytes,
      if (childPublicKey.isExtension) 1 else 0,
      puzzlehashBytes.length,
      ...puzzlehashBytes,
      assetIdtoOuterPuzzlehash.length,
      ...assetIdMapBytes,
    ]);
  }

  factory UnhardenedWalletVector.fromBytes(Bytes bytes) {
    var length = bytes[0];
    var left = 1;
    var right = left + length;

    final childPrivateKey = PrivateKey.fromBytes(bytes.sublist(left, right));

    length = bytes[right];
    left = right + 1;
    right = left + length;
    final childPublicKey = JacobianPoint.fromBytes(
      bytes.sublist(left, right),
      bytes[right] == 1,
    );

    length = bytes[right + 1];
    left = right + 2;
    right = left + length;

    final puzzlehash = Puzzlehash(bytes.sublist(left, right));

    length = bytes[right];
    final assetIdToOuterPuzzlehashMap = <Puzzlehash, Puzzlehash>{};

    var assetIdLeft = right + 1;
    var assetIdRight = assetIdLeft + Puzzlehash.bytesLength;
    var outerPuzzlehashLeft = assetIdRight;
    var outerPuzzlehashRight = outerPuzzlehashLeft + Puzzlehash.bytesLength;
    for (var i = 0; i < length; i++) {
      final assetId = Puzzlehash(bytes.sublist(assetIdLeft, assetIdRight));
      final outerPuzzlehash =
          Puzzlehash(bytes.sublist(outerPuzzlehashLeft, outerPuzzlehashRight));
      assetIdToOuterPuzzlehashMap[assetId] = outerPuzzlehash;

      assetIdLeft = outerPuzzlehashRight;
      assetIdRight = assetIdLeft + Puzzlehash.bytesLength;
      outerPuzzlehashLeft = assetIdRight;
      outerPuzzlehashRight = outerPuzzlehashLeft + Puzzlehash.bytesLength;
    }

    return UnhardenedWalletVector(
      childPrivateKey: childPrivateKey,
      childPublicKey: childPublicKey,
      puzzlehash: puzzlehash,
      assetIdtoOuterPuzzlehash: assetIdToOuterPuzzlehashMap,
    );
  }

  factory UnhardenedWalletVector.fromMap(Map<String, dynamic> map) {
    final childPrivateKey =
        PrivateKey.fromHex(map['childPrivateKey'] as String);
    final childPublicKey = childPrivateKey.getG1();
    final puzzlehash = Puzzlehash.fromHex(map['puzzlehash'] as String);

    final assetIdtoOuterPuzzlehashMap = <Puzzlehash, Puzzlehash>{};
    final assetIdtoOuterPuzzlehash = Map<String, String>.from(
      map['assetIdtoOuterPuzzlehash'] as Map<String, dynamic>,
    );

    // ignore: cascade_invocations
    assetIdtoOuterPuzzlehash.forEach((key, value) {
      assetIdtoOuterPuzzlehashMap[Puzzlehash.fromHex(key)] =
          Puzzlehash.fromHex(value);
    });

    return UnhardenedWalletVector(
      childPrivateKey: childPrivateKey,
      childPublicKey: childPublicKey,
      puzzlehash: puzzlehash,
      assetIdtoOuterPuzzlehash: assetIdtoOuterPuzzlehashMap,
    );
  }

  @override
  int get hashCode => super.hashCode ^ assetIdtoOuterPuzzlehash.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    final firstCheck = other is UnhardenedWalletVector &&
        runtimeType == other.runtimeType &&
        childPrivateKey == other.childPrivateKey &&
        childPublicKey == other.childPublicKey &&
        puzzlehash == other.puzzlehash;

    if (!firstCheck) {
      return false;
    }
    // ignore: test_types_in_equals
    final otherAsUnhardenedWalletVector = other as UnhardenedWalletVector;
    for (final assetId in assetIdtoOuterPuzzlehash.keys) {
      if (otherAsUnhardenedWalletVector.assetIdtoOuterPuzzlehash[assetId] !=
          assetIdtoOuterPuzzlehash[assetId]) {
        return false;
      }
    }
    return true;
  }

  final Map<Puzzlehash, Puzzlehash> assetIdtoOuterPuzzlehash;
}
