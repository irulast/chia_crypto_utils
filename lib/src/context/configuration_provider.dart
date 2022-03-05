class ConfigurationProvider {
  Map<String, Object> configs = {
    'testnet10' : {
      ''
    },
    'mainnet': {
      ''
    }
  };

  void setConfigs(Map<String, Object> configMap) {
    configs = configMap;
  }

  Map<String, Object> getConfigs() {
    return configs;
  }

  Object getConfig(String configKey) {
    return configs[configKey]!;
  }

  void setConfig(String configKey, Object config) {
    configs[configKey] = config;
  }
}