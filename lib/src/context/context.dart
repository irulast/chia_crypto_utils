import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:injector/injector.dart';

Context fun createNewContext(ConfigurationProvider configurationProvider) {

}

class Context {
  // for each object type
  Map<String, Builder> builders;

  Injector abstractSingletonFactory;

  ConfigurationProvider configurationProvider;

  // refreshes configuration context
  refresh();

  register(Factory factory) {
    abstractSingletonFactory.register(factory);
  }

  get<T>() // calls injector built by builders
  // returns proxy object: // has referance to BlockchainNetwork object
  //              -delegate :instance of BlockchainNetwork
  {
    return abstractSingletonFactory.get<T>();
  }

  // for now, just call injector factory
}
