import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class MempoolItemsResponse {
  MempoolItemsResponse(this.mempoolItemMap);

  factory MempoolItemsResponse.fromJson(Map<String, dynamic> json) {
    final mempoolItemMap = <Bytes, MempoolItem>{};
    final mempoolItemsJson = json['mempool_items'] as Map<String, dynamic>;
    for (final mempoolItemJsonEntry in mempoolItemsJson.entries) {
      mempoolItemMap[Bytes.fromHex(mempoolItemJsonEntry.key)] =
          MempoolItem.fromJson(mempoolItemJsonEntry.value as Map<String, dynamic>);
    }

    return MempoolItemsResponse(mempoolItemMap);
  }

  final Map<Bytes, MempoolItem> mempoolItemMap;
}
