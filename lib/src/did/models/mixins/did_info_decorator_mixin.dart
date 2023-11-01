import 'package:chia_crypto_utils/chia_crypto_utils.dart';

mixin DidInfoDecoratorMixin implements DidInfo {
  DidInfo get didInfo;

  @override
  DidRecord get delegate => didInfo.delegate;

  @override
  CoinPrototype get coin => didInfo.coin;

  @override
  LineageProof get lineageProof => didInfo.lineageProof;

  @override
  Program get singletonStructure => didInfo.singletonStructure;

  @override
  DidMetadata get metadata => didInfo.metadata;

  @override
  Puzzlehash get backUpIdsHash => didInfo.backUpIdsHash;

  @override
  CoinSpend get parentSpend => didInfo.parentSpend;

  @override
  int get nVerificationsRequired => didInfo.nVerificationsRequired;

  @override
  List<Puzzlehash> get hints => didInfo.hints;

  @override
  List<Puzzlehash>? get backupIds => didInfo.backupIds;

  @override
  Bytes get did => didInfo.did;

  @override
  Program get innerPuzzle => didInfo.innerPuzzle;

  @override
  JacobianPoint get syntheticPublicKey => didInfo.syntheticPublicKey;

  @override
  LineageProof get recoveryInfo => didInfo.recoveryInfo;

  @override
  Program get fullPuzzle => didInfo.fullPuzzle;

  @override
  Program get p2Puzzle => didInfo.p2Puzzle;

  @override
  DidInfo toDidInfoForPk(JacobianPoint publicKey) => didInfo.toDidInfoForPk(publicKey);

  @override
  DidInfo toDidInfoFromParentInfo() => didInfo.toDidInfoFromParentInfo();

  @override
  Future<DidInfoWithOriginCoin?> fetchOriginCoin(ChiaFullNodeInterface fullNode) =>
      didInfo.fetchOriginCoin(fullNode);
}
