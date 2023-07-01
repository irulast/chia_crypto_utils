import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CatWalletInfo with WalletInfoDecorator implements ChiaWalletInfo {
  const CatWalletInfo(this.delegate, this.assetId);

  factory CatWalletInfo.fromAssetId({required Puzzlehash assetId, required int id, String? name}) {
    final delegate = ChiaWalletInfoImp(
      id: id,
      name: name,
      type: ChiaWalletType.cat,
      data: assetId.toHex(),
      meta: <String, dynamic>{
        'assetId': assetId.toHex(),
        'name': name,
      },
    );

    return CatWalletInfo(delegate, assetId);
  }

  @override
  final ChiaWalletInfo delegate;
  final Puzzlehash assetId;
}
