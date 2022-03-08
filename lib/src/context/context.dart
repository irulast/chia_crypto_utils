import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/factory_builder.dart';
import 'package:injector/injector.dart';
export 'configuration_provider.dart';
export 'context.dart';
export 'factory_builder.dart';

class Context {
  Injector abstractSingletonFactory = Injector();
  ConfigurationProvider configurationProvider;

  Context(this.configurationProvider);

  T get<T>() {
    return abstractSingletonFactory.get<T>();
  }

  void registerFactory<T>(ConfigurableFactory<T> factory) {
    factory.configurationProvider = configurationProvider;
    abstractSingletonFactory.register(factory);
  }
}
