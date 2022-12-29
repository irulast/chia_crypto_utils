import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/namesdao/exceptions/invalid_namesdao_name.dart';
import 'package:chia_crypto_utils/src/api/namesdao/models/name_info.dart';
import 'package:chia_crypto_utils/src/api/namesdao/namesdao_api.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const nTests = 2;

  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final simulatorHttpRpc = SimulatorHttpRpc(
    SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );

  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final meera = ChiaEnthusiast(fullNodeSimulator);
  final nathan = ChiaEnthusiast(fullNodeSimulator);

  final namesMap = {'nathan.xch': NameInfo(address: nathan.address)};

  final mockNamesdaoApi = MockNamesdaoApi(namesMap: namesMap);

  final xchService = XchService(fullNode: fullNodeSimulator, keychain: meera.keychain);

  for (var i = 0; i < nTests; i++) {
    await meera.farmCoins();
  }
  await meera.refreshCoins();

  test('should send XCH to Namesdao name', () async {
    final nathanStartingBalance =
        await fullNodeSimulator.getBalance([nathan.address.toPuzzlehash()]);

    final coinToSend = meera.standardCoins[0];

    await xchService.sendXchToNamesdao(
      coins: [coinToSend],
      amount: coinToSend.amount,
      namesdaoName: 'nathan.xch',
      namesdaoApi: mockNamesdaoApi,
    );

    await fullNodeSimulator.moveToNextBlock();

    final nathanEndingbalance = await fullNodeSimulator.getBalance([nathan.address.toPuzzlehash()]);

    expect(nathanEndingbalance - nathanStartingBalance, equals(coinToSend.amount));
  });

  test('should throw exception when sending XCH to invalid Namesdao name', () async {
    expect(
      () async {
        await xchService.sendXchToNamesdao(
          coins: meera.standardCoins,
          amount: meera.standardCoins.totalValue,
          namesdaoName: 'nathann.xch',
          namesdaoApi: mockNamesdaoApi,
        );
      },
      throwsA(isA<InvalidNamesdaoName>()),
    );
  });
}
