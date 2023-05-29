import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/exceptions/keychain_mismatch_exception.dart';
import 'package:chia_crypto_utils/src/did/models/did_metadata.dart';
import 'package:chia_crypto_utils/src/did/models/uncurried_did_inner_puzzle.dart';

abstract class DidRecord {
  static DidRecord? fromParentCoinSpend(CoinSpend parentSpend, CoinPrototype coin) {
    return _DidRecord.fromParentCoinSpend(parentSpend, coin);
  }

  CoinPrototype get coin;
  LineageProof get lineageProof;
  Program get singletonStructure;
  DidMetadata get metadata;
  Puzzlehash get backUpIdsHash;
  CoinSpend get parentSpend;
  int get nVerificationsRequired;
  List<Puzzlehash> get hints;
  List<Bytes>? get backupIds;
  Bytes get did;
  DIDInfo? getSpendableDidForPk(JacobianPoint publicKey);
  DIDInfo? toSpendableDidFromParentInfo();
}

class _DidRecord implements DidRecord {
  _DidRecord({
    required this.did,
    required this.coin,
    required this.lineageProof,
    required this.metadata,
    required this.singletonStructure,
    required this.backUpIdsHash,
    required this.nVerificationsRequired,
    required this.backupIds,
    required this.hints,
    required this.parentSpend,
  });

  static DidRecord? fromParentCoinSpend(CoinSpend parentSpend, CoinPrototype coin) {
    final uncurriedPuzzle = parentSpend.puzzleReveal.uncurry();
    if (uncurriedPuzzle.mod != singletonTopLayerV1Program) {
      return null;
    }
    final arguments = uncurriedPuzzle.arguments;

    final singletonStructure = arguments[0];
    final parentInnerPuzzle = arguments[1];
    final did = singletonStructure.rest().first().atom;

    final uncurriedParentInnerPuzzle = parentInnerPuzzle.uncurry();
    if (uncurriedParentInnerPuzzle.mod != didInnerPuzzleProgram) {
      return null;
    }

    // check for exit spend
    final innerSolution = parentSpend.solution.rest().rest().first();
    final didExitConditions = DIDWalletService.extractP2ConditionsFromInnerSolution(
      innerSolution,
      DIDExitCondition.isThisCondition,
      DIDExitCondition.fromProgram,
    );

    if (didExitConditions.isNotEmpty) {
      return null;
    }

    // inner puzzle is second curried argument of did full puzzle

    final lineageProof = LineageProof(
      parentCoinInfo: parentSpend.coin.parentCoinInfo,
      innerPuzzlehash: parentInnerPuzzle.hash(),
      amount: parentSpend.coin.amount,
    );

    final uncurriedInnerPuzzle = UncurriedDidInnerPuzzle.fromProgram(parentInnerPuzzle);

    final backupIds = () {
      if (uncurriedInnerPuzzle.backUpIdsHash == Program.list([]).hash()) {
        return <Bytes>[];
      }
      try {
        return innerSolution
            .rest()
            .rest()
            .rest()
            .rest()
            .rest()
            .toList()
            .map((e) => e.atom)
            .toList();
      } catch (e) {
        LoggingContext().info(
          'DID $did has a recovery list hash but missing a reveal. You may need to reset the recovery info',
        );
        return null;
      }
    }();

    final createCoinConditions = BaseWalletService.extractConditionsFromProgramList(
      parentSpend.outputProgram.toList(),
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    );
    final hints = <Puzzlehash>[];

    for (final createCoinCondition in createCoinConditions) {
      final memos = createCoinCondition.memos;
      if (memos == null) {
        continue;
      }
      for (final memo in memos) {
        if (memos.length == Puzzlehash.bytesLength) {
          hints.add(Puzzlehash(memo));
        }
      }
    }

    final didRecord = _DidRecord(
      did: did,
      coin: coin,
      hints: hints,
      lineageProof: lineageProof,
      metadata: uncurriedInnerPuzzle.metadata,
      singletonStructure: uncurriedInnerPuzzle.singletonStructureProgram,
      backUpIdsHash: uncurriedInnerPuzzle.backUpIdsHash,
      nVerificationsRequired: uncurriedInnerPuzzle.nVerificationsRequired,
      backupIds: backupIds,
      parentSpend: parentSpend,
    );

    final mode = SpendMode.fromCode(innerSolution.toList()[0].toInt());

    switch (mode) {
      case SpendMode.runInnerPuzzle:
        return didRecord;
      case SpendMode.recovery:
        //puzzle has been changed: new pubkey
        final publicKeyBytes = innerSolution.toList()[4].atom;
        final uncurriedInnerPuzzle = UncurriedDidInnerPuzzle.fromProgram(parentInnerPuzzle);

        final didInnerPuzzle = DIDWalletService.createInnerPuzzleForPk(
          publicKey: JacobianPoint.fromBytesG1(publicKeyBytes),
          backupIdsHash: uncurriedInnerPuzzle.backUpIdsHash,
          launcherCoinId: did,
          nVerificationsRequired: uncurriedInnerPuzzle.nVerificationsRequired,
          metadataProgram: uncurriedInnerPuzzle.metadataProgram,
        );
        return DIDInfo(
          delegate: didRecord,
          innerPuzzle: didInnerPuzzle,
        );
    }
  }

  @override
  final CoinPrototype coin;

  @override
  final LineageProof lineageProof;
  @override
  final Puzzlehash backUpIdsHash;

  @override
  final Bytes did;

  @override
  final List<Puzzlehash> hints;

  @override
  final DidMetadata metadata;

  @override
  final Program singletonStructure;

  @override
  final int nVerificationsRequired;

  @override
  final List<Bytes>? backupIds;

  DidRecord copyWith({
    required Puzzlehash backUpIdsHash,
  }) {
    final backupIds = backUpIdsHash == Program.list([]).hash() ? <Bytes>[] : this.backupIds;
    return _DidRecord(
        did: did,
        coin: coin,
        lineageProof: lineageProof,
        metadata: metadata,
        singletonStructure: singletonStructure,
        backUpIdsHash: backUpIdsHash,
        hints: hints,
        nVerificationsRequired: nVerificationsRequired,
        backupIds: backupIds,
        parentSpend: parentSpend);
  }

  @override
  DIDInfo? getSpendableDidForPk(JacobianPoint publicKey) {
    final didInnerPuzzle = DIDWalletService.createInnerPuzzleForPk(
      publicKey: publicKey,
      backupIdsHash: backUpIdsHash,
      launcherCoinId: did,
      nVerificationsRequired: nVerificationsRequired,
      metadataProgram: metadata.toProgram(),
    );
    final fullPuzzle = DIDWalletService.makeFullPuzzle(didInnerPuzzle, did);

    if (fullPuzzle.hash() == coin.puzzlehash) {
      return DIDInfo(
        delegate: this,
        innerPuzzle: didInnerPuzzle,
      );
    }

    final emptyBackupIdsHash = Program.list([]).hash();
    final emptyBackUpIdsInnerPuzzle = DIDWalletService.createInnerPuzzleForPk(
      publicKey: publicKey,
      backupIdsHash: emptyBackupIdsHash,
      launcherCoinId: did,
      nVerificationsRequired: nVerificationsRequired,
      metadataProgram: metadata.toProgram(),
    );

    final emptyBackUpIdsFullPuzzle =
        DIDWalletService.makeFullPuzzle(emptyBackUpIdsInnerPuzzle, did);

    if (emptyBackUpIdsFullPuzzle.hash() == coin.puzzlehash) {
      return DIDInfo(
        delegate: copyWith(backUpIdsHash: emptyBackupIdsHash),
        innerPuzzle: emptyBackUpIdsInnerPuzzle,
      );
    }
    return null;
  }

  @override
  DIDInfo? toSpendableDidFromParentInfo() {
    final uncurriedPuzzle = parentSpend.puzzleReveal.uncurry();
    final arguments = uncurriedPuzzle.arguments;

    final parentInnerPuzzle = arguments[1];
    final fullPuzzle = DIDWalletService.makeFullPuzzle(parentInnerPuzzle, did);
    if (fullPuzzle.hash() == coin.puzzlehash) {
      return DIDInfo(delegate: this, innerPuzzle: parentInnerPuzzle);
    }
    return null;
  }

  @override
  final CoinSpend parentSpend;
}

extension ToSpendableDid on DidRecord {
  DIDInfo toSpendableDidForPkOrThrow(JacobianPoint publicKey) {
    final did = getSpendableDidForPk(publicKey);
    if (did != null) {
      return did;
    }
    throw KeychainMismatchException(coin.puzzlehash);
  }

  DIDInfo toSpendableDidFromParentInfoOrThrow() {
    final did = toSpendableDidFromParentInfo();
    if (did != null) {
      return did;
    }
    throw KeychainMismatchException(coin.puzzlehash);
  }

  DIDInfo? toSpendableDid(WalletKeychain keychain) {
    for (final innerPh in [
      ...hints,
      ...keychain.puzzlehashes,
    ]) {
      final walletVector = keychain.getWalletVector(innerPh);
      if (walletVector == null) {
        continue;
      }
      final did = getSpendableDidForPk(walletVector.childPublicKey);
      if (did != null) {
        return did;
      }
    }
    return null;
  }

  DIDInfo toSpendableDidOrThrow(WalletKeychain keychain) {
    final did = toSpendableDid(keychain);
    if (did != null) {
      return did;
    }
    throw KeychainMismatchException(coin.puzzlehash);
  }
}

extension HashBytesList on Iterable<Bytes> {
  Puzzlehash programHash() => Program.list(map(Program.fromBytes).toList()).hash();
}
