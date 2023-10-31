import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NftId extends Address {
  const NftId(super.address);
  factory NftId.fromLauncherId(Bytes launcherId) {
    return NftId(Address.fromPuzzlehash(Puzzlehash(launcherId), 'nft').address);
  }

  Puzzlehash toLauncherId() {
    return toPuzzlehash();
  }

  String get mintGardenLink => 'https://mintgarden.io/nfts/$address';
}
