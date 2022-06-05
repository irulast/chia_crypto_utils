import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class PostFarmerRequest {
  const PostFarmerRequest(this.payload, this.signature);
  final PostFarmerPayload payload;
  final JacobianPoint signature;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'payload': payload.toJson(),
      'signature': signature.toHexWithPrefix(),
    };
  }
}
