import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:get_it/get_it.dart';

class PoolContext {
  GetIt get getIt => GetIt.I;
  static const poolUrlInstanceName = 'PoolContext.poolUrl';
  static const certificateBytesInstanceName = 'PoolContext.certificateBytes';

  String get poolUrl {
    if (!getIt.isRegistered<String>(instanceName: poolUrlInstanceName)) {
      throw ContextNotSetException(poolUrlInstanceName);
    }
    return getIt.get<String>(instanceName: poolUrlInstanceName);
  }

  void setPoolUrl(String poolUrl) {
    getIt
      ..registerSingleton<String>(poolUrl, instanceName: poolUrlInstanceName)
      ..allowReassignment = true;
  }

  Bytes? get certificateBytes {
    if (!getIt.isRegistered<Bytes>(instanceName: certificateBytesInstanceName)) {
      return null;
    }
    return getIt.get<Bytes>(instanceName: certificateBytesInstanceName);
  }

  void setCertificateBytes(Bytes certificateBytes) {
    getIt
      ..registerSingleton<Bytes>(certificateBytes, instanceName: certificateBytesInstanceName)
      ..allowReassignment = true;
  }
}
