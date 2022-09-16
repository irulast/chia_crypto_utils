import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() async{
  LoggingContext().setLogTypes(api: true);
    LoggingContext().setLogLevel(LogLevel.low);

  final fullNode = ChiaFullNodeInterface.fromURL('https://chia.irulast-prod.com');

  final mempoolItems =  await fullNode.getAllMempoolItems();

  print(mempoolItems);

// print(Program.deserializeHex('829fb06da6e48fd84ec1217f9985767b3b7ed1b4bc151c77bd1e8dab27708aa2'));
}