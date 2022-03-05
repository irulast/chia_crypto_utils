import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:injector/injector.dart';
abstract class ConfigurableFactory<T> implements Factory<T> {
  ConfigurationProvider configurationProvider;

  ConfigurableFactory(this.configurationProvider);
}