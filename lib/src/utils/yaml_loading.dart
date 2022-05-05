import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

dynamic loadYamlFromLocalFileSystem(String filePath) {
  var yamlFilePath = path.join(path.current, filePath);
  yamlFilePath = path.normalize(yamlFilePath);
  final yamlData = File(yamlFilePath).readAsStringSync();
  return loadYaml(yamlData);
}

dynamic loadYamlFromApplicationLib(String filePath) {
  throw UnimplementedError();
}
