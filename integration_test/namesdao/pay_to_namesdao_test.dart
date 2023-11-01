import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/namesdao/exceptions/invalid_namesdao_name.dart';
import 'package:test/test.dart';

Future<void> main() async {
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

  final xchService = XchService(fullNode: fullNodeSimulator, keychain: meera.keychain);
  final namesdaoApi = NamesdaoApi();

  const ccuNamesdao = 'ChiaCryptoUtils.xch';
  const ccuNamesdaoAddress =
      Address('xch1zdys84nucxx93r923ha4xe4tg9tyqhw8f7xe677n0u8mz29343usmuqurt');
  final ccuNamesdaoPuzzlehash = ccuNamesdaoAddress.toPuzzlehash();

  await meera.farmCoins();
  await meera.refreshCoins();

  test('should send XCH to Namesdao name', () async {
    final startingBalance = await fullNodeSimulator.getBalance([ccuNamesdaoPuzzlehash]);

    final coinToSend = meera.standardCoins[0];

    await xchService.sendXchToNamesdao(
      coins: [coinToSend],
      amount: coinToSend.amount,
      namesdaoName: ccuNamesdao,
      namesdaoApi: namesdaoApi,
    );

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();

    final endingBalance = await fullNodeSimulator.getBalance([ccuNamesdaoPuzzlehash]);

    expect(endingBalance - startingBalance, equals(coinToSend.amount));
  });

  test('should throw exception when sending XCH to invalid Namesdao name', () async {
    expect(
      () async {
        await xchService.sendXchToNamesdao(
          coins: meera.standardCoins,
          amount: meera.standardCoins.totalValue,
          namesdaoName: '_namesdao.xchh',
          namesdaoApi: namesdaoApi,
        );
      },
      throwsA(isA<InvalidNamesdaoName>()),
    );
  });
}
