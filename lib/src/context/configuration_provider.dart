class ConfigurationProvider {
  Map<String, Map<String, String>> configs = {};

  void setConfigs(Map<String, Map<String, String>> configMap) {
    configs = configMap;
  }

  Map<String, Map<String, String>> getConfigs() {
    return configs;
  }

  Map<String, String> getConfig(String configKey) {
    return configs[configKey]!;
  }

  void setConfig(String configKey, Map<String, String> config) {
    configs[configKey] = config;
  }
}
