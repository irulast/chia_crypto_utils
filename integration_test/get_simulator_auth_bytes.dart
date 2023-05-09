import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  print('cert bytes:\n${SimulatorUtils.certBytes}');
  print('\n----------------------------------\n');
  print('key bytes:\n${SimulatorUtils.certBytes}');
}
