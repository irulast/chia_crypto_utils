import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class DependentCoin with CoinPrototypeDecoratorMixin {
  DependentCoin({
    required this.delegate,
    required this.primaryCoinId,
    required this.primaryCoinMessage,
  });

  factory DependentCoin.fromJson(Map<String, dynamic> json) {
    final delegate = CoinPrototype.fromJson(json);
    return DependentCoin(
      delegate: delegate,
      primaryCoinId:
          pick(json, 'primary_coin_id').letStringOrThrow(Bytes.fromHex),
      primaryCoinMessage:
          pick(json, 'primary_coin_message').letStringOrThrow(Bytes.fromHex),
    );
  }

  @override
  final CoinPrototype delegate;
  final Bytes primaryCoinId;
  final Bytes primaryCoinMessage;

  Program get fullPuzzle => DependentCoinWalletService.makeFullPuzzle(
        primaryCoinId: primaryCoinId,
        primaryCoinMessage: primaryCoinMessage,
      );

  Map<String, dynamic> dependentCoinToJson() => {
        ...toJson(),
        'primary_coin_id': primaryCoinId.toHex(),
        'primary_coin_message': primaryCoinMessage.toHex(),
      };
}
