// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:path/path.dart' as path;

class SimulatorUtils {
  static String simulatorUrlEnvironmentVariableName = 'FULL_NODE_SIMULATOR_URL';
  static String defaultUrl = 'https://localhost:5000';

  // if you are using this class outside of chia-crypto-utils you must set FULL_NODE_SIMULATOR_GEN_PATH
  static String simulatorGeneratedFilesPathVariableName = 'FULL_NODE_SIMULATOR_GEN_PATH';
  static String get defaultgeneratedFilesPath =>
      path.join(path.current, 'lib/src/api/full_node/simulator/run');

  static String get generatedFilesPath {
    final env = Platform.environment;
    return env[simulatorGeneratedFilesPathVariableName] ?? defaultgeneratedFilesPath;
  }

  static String get simulatorUrl {
    final env = Platform.environment;
    return env[simulatorUrlEnvironmentVariableName] ?? defaultUrl;
  }

  static String get simulatorNotRunningWarning =>
      'Full node simulator is not running at $simulatorUrl so this test was skipped.';

  static Bytes get certBytes {
    return _getAuthFileBytes(
      '$generatedFilesPath/temp/config/ssl/full_node/private_full_node.crt',
    );
  }

  static Bytes get keyBytes {
    return _getAuthFileBytes(
      '$generatedFilesPath/temp/config/ssl/full_node/private_full_node.key',
    );
  }

  static Bytes _getAuthFileBytes(String pathToFile) {
    try {
      LoggingContext().info(null, highLog: 'auth file loaded: $pathToFile');

      return Bytes(File(pathToFile).readAsBytesSync());
    } on FileSystemException {
      throw SimulatorAuthFilesNotFoundException();
    }
  }

  static Future<bool> checkIfSimulatorIsRunning() async {
    final simulatorRpc = SimulatorHttpRpc(
      simulatorUrl,
      certBytes: certBytes,
      keyBytes: keyBytes,
    );

    final simulator = SimulatorFullNodeInterface(simulatorRpc);
    try {
      await simulator.getBlockchainState();
    } on NotRunningException {
      return false;
    }
    return true;
  }
}
