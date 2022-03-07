import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/factory_builder.dart';
import 'package:chia_utils/src/core/models/blockchain_network.dart';
import 'package:injector/injector.dart';

typedef LoadFunction = BlockchainNetwork Function(String path);
class NetworkFactory implements ConfigurableFactory<BlockchainNetwork> {
  static final configId = "blockchainNetwork";
  @override
  late ConfigurationProvider configurationProvider;
  LoadFunction load;

  NetworkFactory(this.load);
  
  BlockchainNetwork _getBlockchainNetwork() {
    final config = configurationProvider.getConfig(configId);
    var yamlFilePath = config['yaml_file_path']!;

    return load(yamlFilePath);
  }

  @override
  Builder<BlockchainNetwork> get builder => (
    () => _getBlockchainNetwork()
  );

  @override
  get instance => _getBlockchainNetwork();
}
