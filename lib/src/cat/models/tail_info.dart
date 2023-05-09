import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class TailRunningInfo {
  TailRunningInfo({
    required this.tail,
    required this.signature,
    required this.tailSolution,
  });

  final JacobianPoint signature;
  final Program tail;
  final Program tailSolution;

  Puzzlehash get assetId => tail.hash();
}
