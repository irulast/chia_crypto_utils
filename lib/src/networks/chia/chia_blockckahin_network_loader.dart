import 'package:chia_utils/src/core/models/blockchain_network.dart';
import 'package:chia_utils/src/core/models/blockchain_network_loader.dart';
import 'package:chia_utils/src/utils/yaml_loading.dart';

class ChiaBlockchainNetworkLoader implements BlockchainNetworkLoader {
  @override
  BlockchainNetwork loadfromLocalFileSystem(String filePath) {
    final yaml = loadYamlFromLocalFileSystem(filePath);

    final selectedNetwork = yaml['full_node']['selected_network']!;
    return BlockchainNetwork(
      name: selectedNetwork,
      addressPrefix: yaml['farmer']['network_overrides']['config'][selectedNetwork]['address_prefix']!,
      aggSigMeExtraData: yaml['farmer']['network_overrides']['constants'][selectedNetwork]['GENESIS_CHALLENGE']!,
      networkConfig: yaml
    );
  }

  @override
  BlockchainNetwork loadfromApplicationLib(String path) {
    throw UnimplementedError();
  }

}