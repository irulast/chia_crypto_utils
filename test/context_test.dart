// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('should save context correctly', () {
    final configurationProvider = ConfigurationProvider()
      ..setConfig(NetworkFactory.configId, {
        'yaml_file_path': 'lib/src/networks/chia/mainnet/config.yaml'
      }
    );

    final context = Context(configurationProvider);
    final blockchainLoader = ChiaBlockchainNetworkLoader();
    context.registerFactory(NetworkFactory(blockchainLoader.loadfromLocalFileSystem));

    var blockchainNetwork = context.get<BlockchainNetwork>();

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
