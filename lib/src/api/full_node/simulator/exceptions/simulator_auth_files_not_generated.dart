class SimulatorAuthFilesNotFoundException implements Exception {
  SimulatorAuthFilesNotFoundException(this.path);

  final String path;

  @override
  String toString() =>
      'Simulator cert/keys not found at $path. To generate them, start the simulator.';
}
