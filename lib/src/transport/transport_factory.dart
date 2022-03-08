import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/factory_builder.dart';
import 'package:chia_utils/src/transport/transport.dart';
import 'package:injector/injector.dart';

class TransportFactory implements ConfigurableFactory<Transport> {
  @override
  ConfigurationProvider configurationProvider;

  TransportFactory(this.configurationProvider);

  @override
  // TODO: implement builder
  Builder<Transport> get builder => throw UnimplementedError();

  @override
  // TODO: implement instance
  Transport get instance => throw UnimplementedError();
}
