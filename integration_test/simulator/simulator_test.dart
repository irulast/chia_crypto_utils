@Skip('modifies simulator config')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  LoggingContext().setLogTypes(api: true);

  LoggingContext().setLogLevel(LogLevel.low);
  test('should parse responses', () async {
    final isAutofarming = await fullNodeSimulator.getIsAutofarming();

    final newIsAutofarming = await fullNodeSimulator.setShouldAutofarm(
      shouldAutofarm: !isAutofarming,
    );

    expect(newIsAutofarming, !isAutofarming);
  });
}
