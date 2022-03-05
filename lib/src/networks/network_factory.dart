import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/factory_builder.dart';
import 'package:chia_utils/src/core/models/blockchain_network.dart';
import 'package:injector/injector.dart';

class NetworkFactory implements ConfigurableFactory<BlockchainNetwork> {

  Factory<BlockchainNetwork> build<BlockchainNetwork>() {
    configurationProvider.getConfig("BlockchainNetwork");
    return BlockchainNetwork()
  }

  ConfigurationProvider configurationProvider;

}