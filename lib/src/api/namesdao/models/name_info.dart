import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NameInfo {
  NameInfo({
    //required this.name,
    required this.address,
    //required this.nftCoinId,
    //required this.uris,
    //required this.metaUris,
  });

  //final String name;
  final Address address;
  //final Bytes nftCoinId;
  //final List<String> uris;
  //final List<String> metaUris;

  NameInfo.fromJson(Map<String, dynamic> json)
      : //name = json['name'] as String,
        address = Address(json['address'] as String);
        //nftCoinId = Bytes.fromHex(json['nft_coin_id'] as String),
}
