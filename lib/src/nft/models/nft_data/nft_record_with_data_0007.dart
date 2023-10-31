import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class HydratedNftRecord with NftRecordDecoratorMixin implements NftRecord {
  HydratedNftRecord({
    required this.delegate,
    required this.data,
    required this.mintInfo,
  });
  @override
  final NftRecord delegate;

  final NftData0007 data;
  final NftMintInfo? mintInfo;

  HydratedNftRecord withMintInfo(NftMintInfo info) {
    return HydratedNftRecord(
      delegate: delegate,
      mintInfo: info,
      data: data,
    );
  }
}

class NftRecordWithMintInfo with NftRecordDecoratorMixin implements NftRecord {
  NftRecordWithMintInfo({
    required this.delegate,
    required this.mintInfo,
  });
  @override
  final NftRecord delegate;

  final NftMintInfo mintInfo;
}
