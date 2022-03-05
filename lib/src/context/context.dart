import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/factory_builder.dart';
import 'package:injector/injector.dart';

class Context {
  // for each object type
  Injector abstractSingletonFactory = Injector();
  ConfigurationProvider configurationProvider;

  Context(this.configurationProvider);

  T get<T>() // calls injector built by builders
  // returns proxy object: // has referance to BlockchainNetwork object
  //              -delegate :instance of BlockchainNetwork
  {
    return abstractSingletonFactory.get<T>();
  }

  void registerFactory<T>(ConfigurableFactory<T> factory) {
    factory.configurationProvider = configurationProvider;
    abstractSingletonFactory.register(factory);
  }
}
