import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/context.dart';
import 'package:chia_utils/src/core/models/blockchain_network.dart';
import 'package:chia_utils/src/networks/chia/chia_blockckahin_network_loader.dart';
import 'package:chia_utils/src/networks/network_factory.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {

  test('should save context correctly', () {
    final configurationProvider = ConfigurationProvider();
    configurationProvider.setConfig(NetworkFactory.configId, {
        'yaml_file_path': 'lib/src/networks/chia/mainnet/config.yaml'
    });

    final context = Context(configurationProvider);
    final blockchainLoader = ChiaBlockchainNetworkLoader();
    context.registerFactory(NetworkFactory(blockchainLoader.loadfromLocalFileSystem));

    BlockchainNetwork blockchainNetwork = context.get<BlockchainNetwork>();

    expect(blockchainNetwork.name, 'mainnet');
    expect(blockchainNetwork.addressPrefix, 'xch');
    expect(blockchainNetwork.aggSigMeExtraData, 'ccd5bb71183532bff220ba46c268991a3ff07eb358e8255a65c30a2dce0e5fbb');

    configurationProvider.setConfig(NetworkFactory.configId, {
        'yaml_file_path': 'lib/src/networks/chia/testnet10/config.yaml'
    });

    blockchainNetwork = context.get<BlockchainNetwork>();

    expect(blockchainNetwork.name, 'testnet10');
    expect(blockchainNetwork.addressPrefix, 'txch');
    expect(blockchainNetwork.aggSigMeExtraData, 'ae83525ba8d1dd3f09b277de18ca3e43fc0af20d20c4b3e92ef2a48bd291ccb2');
  });

}