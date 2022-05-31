import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/pool_interface.dart';

class PoolService {
  const PoolService(this.poolUrl, this.fullNode);
  final String poolUrl;
  final ChiaFullNodeInterface fullNode;
  PoolInterface get poolInterface => PoolInterface(poolUrl);
}
