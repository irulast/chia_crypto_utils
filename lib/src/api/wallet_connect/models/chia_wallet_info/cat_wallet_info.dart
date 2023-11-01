import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CatWalletInfo with WalletInfoDecorator implements ChiaWalletInfo {
  CatWalletInfo({required this.id, this.name, required this.assetId})
      : delegate = ChiaWalletInfoImp(
          id: id,
          name: name,
          type: ChiaWalletType.cat,
          data: assetId.toHex(),
          meta: <String, dynamic>{
            'assetId': assetId.toHex(),
            'name': name,
          },
        );

  @override
  final ChiaWalletInfo delegate;
  @override
  final String? name;
  @override
  final int id;
  final Puzzlehash assetId;
}
