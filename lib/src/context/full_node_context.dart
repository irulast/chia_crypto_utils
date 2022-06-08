import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';
import 'package:get_it/get_it.dart';

class FullNodeContext {
  GetIt get getIt => GetIt.I;
  static const urlInstanceName = 'FullNodeContext.url';
  static const certificateBytesInstanceName = 'FullNodeContext.certificateBytes';
  static const keyBytesInstanceName = 'FullNodeContext.keyBytes';

  String get url {
    if (!getIt.isRegistered<String>(instanceName: urlInstanceName)) {
      return FullNodeUtils.defaultUrl;
    }
    return getIt.get<String>(instanceName: urlInstanceName);
  }

  void setUrl(String url) {
    getIt
      ..registerSingleton<String>(url, instanceName: urlInstanceName)
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

  Bytes? get keyBytes {
    if (!getIt.isRegistered<Bytes>(instanceName: keyBytesInstanceName)) {
      return null;
    }
    return getIt.get<Bytes>(instanceName: keyBytesInstanceName);
  }

  void setKeyBytes(Bytes keyBytes) {
    getIt
      ..registerSingleton<Bytes>(keyBytes, instanceName: keyBytesInstanceName)
      ..allowReassignment = true;
  }
}
