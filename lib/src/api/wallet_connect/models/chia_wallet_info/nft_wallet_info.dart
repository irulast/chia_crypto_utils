import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NftWalletInfo with WalletInfoDecorator implements ChiaWalletInfo {
  NftWalletInfo({
    required this.id,
    this.name,
    required this.did,
  }) : delegate = ChiaWalletInfoImp(
          id: id,
          name: name,
          type: ChiaWalletType.nft,
          data: jsonEncode(<String, dynamic>{'did_info': did?.toHex()}),
          meta: <String, dynamic>{
            'did': did != null
                ? Address.fromPuzzlehash(Puzzlehash(did), didPrefix).address
                : '',
          },
        );

  @override
  final ChiaWalletInfo delegate;
  @override
  final int id;
  @override
  final String? name;
  final Bytes? did;
}

class NftWalletInfoWithNftInfos extends NftWalletInfo {
  NftWalletInfoWithNftInfos({
    required super.id,
    super.name,
    required super.did,
    required this.nftInfos,
  });

  final List<NftInfo> nftInfos;
}
