import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class ExchangeCoinMemos {
  factory ExchangeCoinMemos({
    required Bytes initializationCoinId,
    required PrivateKey requestorPrivateKey,
  }) {
    final signature = AugSchemeMPL.sign(requestorPrivateKey, initializationCoinId);

    return ExchangeCoinMemos._(initializationCoinId: initializationCoinId, signature: signature);
  }

  ExchangeCoinMemos._({
    required this.initializationCoinId,
    required this.signature,
  });

  final Bytes initializationCoinId;
  final JacobianPoint signature;

  static ExchangeCoinMemos? maybeFromMemos(List<Bytes> memos) {
    if (memos.length != 2) {
      return null;
    }

    final initializationCoinId = memos[0];
    final signature = JacobianPoint.fromBytesG2(memos[1]);

    return ExchangeCoinMemos._(initializationCoinId: initializationCoinId, signature: signature);
  }

  bool verify(JacobianPoint publicKey) {
    return AugSchemeMPL.verify(publicKey, initializationCoinId, signature);
  }

  List<Memo> toMemos() {
    return [Memo(initializationCoinId), Memo(signature.toBytes())];
  }
}

class KeyMismatchException implements Exception {
  KeyMismatchException([this.message]);

  final String? message;

  @override
  String toString() {
    return 'Key mismatch: $message';
  }
}
