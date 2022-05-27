// ignore_for_file: avoid_dynamic_calls, lines_longer_than_80_chars

import 'package:chia_crypto_utils/src/core/models/blockchain_network.dart';
import 'package:chia_crypto_utils/src/core/models/blockchain_network_loader.dart';
import 'package:chia_crypto_utils/src/utils/yaml_loading.dart';

class ChiaBlockchainNetworkLoader implements BlockchainNetworkLoader {
  @override
  BlockchainNetwork loadfromLocalFileSystem(String path) {
    final dynamic yaml = loadYamlFromLocalFileSystem(path);

    final dynamic selectedNetwork = yaml['full_node']['selected_network'];
    return BlockchainNetwork(
      name: selectedNetwork as String,
      addressPrefix: yaml['farmer']['network_overrides']['config'][selectedNetwork]
          ['address_prefix']! as String,
      aggSigMeExtraData: yaml['farmer']['network_overrides']['constants'][selectedNetwork]
          ['GENESIS_CHALLENGE']! as String,
      networkConfig: yaml,
    );
  }

  @override
  BlockchainNetwork loadfromApplicationLib(String path) {
    throw UnimplementedError();
  }
}
