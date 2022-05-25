class SimulatorAuthFilesNotFoundException implements Exception {
  @override
  String toString() =>
      'Simulator cert/keys have not been generated. To generate them, start the simulator.';
}
