class CoinResponse {
  String parentCoinInfo;
  String puzzleHash;
  int amount;

  CoinResponse(
      {required this.parentCoinInfo,
      required this.puzzleHash,
      required this.amount});

  CoinResponse.fromJson(Map<String, dynamic> json)
      : parentCoinInfo = json['parent_coin_info'],
        puzzleHash = json['puzzle_hash'],
        amount = json['amount'];

  Map<String, dynamic> toJson() => {
        'parent_coin_info': parentCoinInfo,
        'puzzle_hash': puzzleHash,
        'amount': amount
      };
}
