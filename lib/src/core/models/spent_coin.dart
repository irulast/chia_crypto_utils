import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class SpentCoin extends Coin {
  const SpentCoin({
    required super.confirmedBlockIndex,
    required super.spentBlockIndex,
    required super.coinbase,
    required super.timestamp,
    required super.parentCoinInfo,
    required super.puzzlehash,
    required super.amount,
    required Program puzzleReveal,
    required Program solution,
  })  : _puzzleReveal = puzzleReveal,
        _solution = solution,
        assert(spentBlockIndex > 0, 'coin must be spent');

  factory SpentCoin.fromJson(Map<String, dynamic> json) {
    return SpentCoin(
      confirmedBlockIndex: json['confirmed_block_index'] as int,
      spentBlockIndex: json['spent_block_index'] as int,
      coinbase: json['coinbase'] as bool,
      timestamp: json['timestamp'] as int,
      parentCoinInfo: Bytes.fromHex(json['parent_coin_info'] as String),
      puzzlehash: Puzzlehash.fromHex(json['puzzle_hash'] as String),
      amount: json['amount'] as int,
      puzzleReveal: Program.deserializeHex(json['puzzle_reveal'] as String),
      solution: Program.deserializeHex(json['solution'] as String),
    );
  }

  factory SpentCoin.fromCoinSpend(Coin coin, CoinSpend coinSpend) {
    if (coin.id != coinSpend.coin.id) {
      ArgumentError('Coin spend is not for this coin');
    }
    return SpentCoin(
      confirmedBlockIndex: coin.confirmedBlockIndex,
      spentBlockIndex: coin.spentBlockIndex,
      coinbase: coin.coinbase,
      timestamp: coin.timestamp,
      parentCoinInfo: coin.parentCoinInfo,
      puzzlehash: coin.puzzlehash,
      amount: coin.amount,
      puzzleReveal: coinSpend.puzzleReveal,
      solution: coinSpend.solution,
    );
  }

  final Program _puzzleReveal;
  final Program _solution;

  CoinSpend get coinSpend => CoinSpend(
        coin: this,
        puzzleReveal: _puzzleReveal,
        solution: _solution,
      );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['confirmed_block_index'] = confirmedBlockIndex;
    json['spent_block_index'] = spentBlockIndex;
    json['coinbase'] = coinbase;
    json['timestamp'] = timestamp;
    json['puzzle_reveal'] = _puzzleReveal.serializeHex();
    json['solution'] = _solution.serializeHex();
    return json;
  }
}
