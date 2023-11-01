import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/clvm/exceptions/invalid_puzzle_hash_exception.dart';

class CoinWithHint extends Coin {
  const CoinWithHint({
    required super.confirmedBlockIndex,
    required super.spentBlockIndex,
    required super.coinbase,
    required super.timestamp,
    required super.parentCoinInfo,
    required super.puzzlehash,
    required super.amount,
    required this.hint,
  });

  factory CoinWithHint.fromChiaCoinRecordJson(Map<String, dynamic> json) {
    try {
      final coin = Coin.fromChiaCoinRecordJson(json);

      final hint = Bytes.maybeFromHex(json['hint'] as String?);

      return CoinWithHint(
        confirmedBlockIndex: coin.confirmedBlockIndex,
        spentBlockIndex: coin.spentBlockIndex,
        coinbase: coin.coinbase,
        timestamp: coin.timestamp,
        parentCoinInfo: coin.parentCoinInfo,
        puzzlehash: coin.puzzlehash,
        amount: coin.amount,
        hint: hint,
      );
    } on InvalidPuzzleHashException catch (e, st) {
      LoggingContext()
          .error('Invalid puzzle hash in CoinWithHint.fromChiaCoinRecordJson: $json \n$st');
      rethrow;
    }
  }

  factory CoinWithHint.fromJson(Map<String, dynamic> json) {
    try {
      final coin = Coin.fromJson(json);
      final hint = Bytes.fromHex(json['hint'] as String);
      return CoinWithHint(
        confirmedBlockIndex: coin.confirmedBlockIndex,
        spentBlockIndex: coin.spentBlockIndex,
        coinbase: coin.coinbase,
        timestamp: coin.timestamp,
        parentCoinInfo: coin.parentCoinInfo,
        puzzlehash: coin.puzzlehash,
        amount: coin.amount,
        hint: hint,
      );
    } on InvalidPuzzleHashException catch (e, st) {
      LoggingContext().error('Invalid puzzle hash in CoinWithHint.fromJson: $json \n$st');
      rethrow;
    }
  }

  @override
  Map<String, dynamic> toFullJson() => <String, dynamic>{
        ...super.toFullJson(),
        'hint': hint?.toHex(),
      };

  final Bytes? hint;
}
