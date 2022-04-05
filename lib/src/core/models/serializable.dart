import 'package:chia_utils/chia_crypto_utils.dart';

abstract class Serializable {
  Bytes toBytes();
}

Bytes serializeList(List<Serializable> items) {
  // 32 bytes indicating length of serialized list. 
  // from https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/util/streamable.py#L241
  var bytes = Bytes(intTo32Bytes(items.length));
  for(final item in items) {
    bytes += item.toBytes();
  }
  return bytes;
}
