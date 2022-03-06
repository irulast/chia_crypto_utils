import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/factory_builder.dart';
import 'package:chia_utils/src/core/models/blockchain_network.dart';
import 'package:injector/injector.dart';

class NetworkFactory implements ConfigurableFactory<BlockchainNetwork> {
  static final configId = "blockchainNetwork";
  @override
  late ConfigurationProvider configurationProvider;

  BlockchainNetwork _getBlockchainNetwork() {
    final config = configurationProvider.getConfig(configId);
    return BlockchainNetwork(
        name: config['name']!,
        addressPrefix: config['address_prefix']!,
        aggSigMeExtraData: config['agg_sig_me_extra_data']!
        );
  }

  @override
  Builder<BlockchainNetwork> get builder => (() => _getBlockchainNetwork());

  @override
  get instance => _getBlockchainNetwork();
}
