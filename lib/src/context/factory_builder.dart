import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:injector/injector.dart';
abstract class ConfigurableFactory<T> {
  ConfigurationProvider configurationProvider;

  ConfigurableFactory(this.configurationProvider);

  // ignore: avoid_shadowing_type_parameters
  Factory<T> build<T>();
}