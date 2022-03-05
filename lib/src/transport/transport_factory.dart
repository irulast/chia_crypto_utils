import 'dart:html';

import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/factory_builder.dart';
import 'package:chia_utils/src/transport/transport.dart';
import 'package:injector/src/factory/factory.dart';

class TransportFactory implements ConfigurableFactory<Transport> {
  @override
  ConfigurationProvider configurationProvider;

  @override
  Factory<Transport> build<Transport>() {
    // TODO: implement build
    configurationProvider.getConfig('transport');
    throw UnimplementedError();
  }



}


class _LocalTransport implements Transport {
  
}

