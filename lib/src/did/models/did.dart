// ignore_for_file: hash_and_equals, lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

/// Decorator on [DidRecord] that has an inner puzzle and can be spent
@immutable
class DidInfo implements DidRecord {
  DidInfo({
    required this.delegate,
    required this.innerPuzzle,

    // p2Puzzle is first curried argument of did inner puzzle
  }) : p2Puzzle = innerPuzzle.uncurry().arguments[0] {
    if (coin.puzzlehash != fullPuzzle.hash()) {
      throw InvalidDidException(
        message: 'Provided inner puzzle does not match did coin puzzlehash',
      );
    }
  }

  final DidRecord delegate;
  final Program p2Puzzle;
  final Program innerPuzzle;

  JacobianPoint get syntheticPublicKey =>
      JacobianPoint.fromBytesG1(p2Puzzle.uncurry().arguments[0].atom);

  LineageProof get recoveryInfo => LineageProof(
        parentCoinInfo: coin.parentCoinInfo,
        innerPuzzlehash: innerPuzzle.hash(),
        amount: coin.amount,
      );

  Program get fullPuzzle => DIDWalletService.makeFullPuzzle(innerPuzzle, did);

  static Bytes parseDidFromEitherFormat(String serializedDid) {
    if (serializedDid.startsWith(didPrefix)) {
      return Address(serializedDid).toPuzzlehash();
    }

    return Bytes.fromHex(serializedDid);
  }

  // conforms to Chia's DidInfo JSON format
  Map<String, dynamic> toChiaJson(CoinPrototype originCoin) {
    return <String, dynamic>{
      'origin_coin': originCoin.toJson(),
      'backup_ids': backupIds?.map((id) => id.toHex()).toList(),
      'num_of_backup_ids_needed': backupIds?.length ?? 0,
      'parent_info': [
        Tuple2(coin.id.toHex(), lineageProof.toJson()).toList(),
      ],
      'current_inner': innerPuzzle.toBytes().toHex(),
      'temp_coin': null,
      'temp_puzhash': null,
      'temp_pubkey': null,
      'sent_recovery_transaction': false,
      'metadata': metadata.map.toString(),
    };
  }

  @override
  CoinPrototype get coin => delegate.coin;

  @override
  Bytes get did => delegate.did;

  @override
  List<Puzzlehash> get hints => delegate.hints;

  @override
  LineageProof get lineageProof => delegate.lineageProof;

  @override
  Puzzlehash get backUpIdsHash => delegate.backUpIdsHash;

  @override
  DidMetadata get metadata => delegate.metadata;

  @override
  int get nVerificationsRequired => delegate.nVerificationsRequired;

  @override
  Program get singletonStructure => delegate.singletonStructure;

  @override
  List<Bytes>? get backupIds => delegate.backupIds;

  @override
  CoinSpend get parentSpend => delegate.parentSpend;

  @override
  DidInfo toDidInfoForPk(JacobianPoint publicKey) {
    return this;
  }

  @override
  DidInfo toDidInfoFromParentInfo() {
    return this;
  }
}

const didPrefix = 'did:chia:';
