
// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:path/path.dart' as path;

import 'exceptions/simulator_auth_files_not_generated.dart';

class SimulatorUtils {
  static String defaultUrl = 'https://localhost:5000';
  static String envVariableName = 'FULL_NODE_SIMULATOR_URL';

  static String get simulatorUrl {
    final env = Platform.environment; 
    return env[envVariableName] ?? defaultUrl;
  }

  static String get simulatorNotRunningWarning =>
   'Full node simulator is not running at $simulatorUrl so this test was skipped.';

  static Bytes get certBytes {
    return _getAuthFileBytes('test/simulator/temp/config/ssl/full_node/private_full_node.crt');
  }

  static Bytes get keyBytes {
    return _getAuthFileBytes('test/simulator/temp/config/ssl/full_node/private_full_node.key');
  }

  static Bytes _getAuthFileBytes(String pathToFile) {
    try {
       return Bytes(File(path.join(path.current, pathToFile)).readAsBytesSync());
    } on FileSystemException {
      throw SimulatorAuthFilesNotGeneratedException();
    }
  }

  static Future<bool> checkIfSimulatorIsRunning() async {
    SimulatorHttpRpc? simulatorRpc;
    try {
      simulatorRpc = SimulatorHttpRpc(
        simulatorUrl,
        certBytes: certBytes,
        keyBytes: keyBytes,
      );
    } on SimulatorAuthFilesNotGeneratedException {
      // if cert/keys havent been generated then the simulator can't be running
      return false;
    }

    final simulator = SimulatorFullNodeInterface(simulatorRpc);
    try {
       await simulator.getBlockchainState();
    } on SocketException {
      return false;
    }
    return true;
  }
}
