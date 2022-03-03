class BalanceResponse {
  int balance;

  BalanceResponse({required this.balance});

  BalanceResponse.fromJson(Map<String, dynamic> json)
      : balance = json['balance'];

  Map<String, dynamic> toJson() => {'balance': balance};
}
