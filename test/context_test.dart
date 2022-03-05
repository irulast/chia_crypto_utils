import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/context.dart';
import 'package:chia_utils/src/core/models/blockchain_network.dart';
import 'package:chia_utils/src/networks/network_factory.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {

  test('should save context correctly', () {
    final configurationProvider = ConfigurationProvider();
    configurationProvider.setConfig(NetworkFactory.configId, {
        'name': 'TestNet10',
        'address_prefix': 'txch',
        'agg_sig_me_extra_data': 'ae83525ba8d1dd3f09b277de18ca3e43fc0af20d20c4b3e92ef2a48bd291ccb2'
    });

    final context = Context(configurationProvider);
    context.registerFactory(NetworkFactory());

    BlockchainNetwork blockchainNetwork = context.get<BlockchainNetwork>();

    expect(blockchainNetwork.addressPrefix, 'txch');

    configurationProvider.setConfig(NetworkFactory.configId, {
        'name': 'Mainnet',
        'address_prefix': 'xch',
        'agg_sig_me_extra_data': 'ccd5bb71183532bff220ba46c268991a3ff07eb358e8255a65c30a2dce0e5fbb'
    });

    blockchainNetwork = context.get<BlockchainNetwork>();

    expect(blockchainNetwork.addressPrefix, 'xch');
  });

}