import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node_http_rpc.dart';

Future<void> main() async {
  const fullNodeRpc = FullNodeHttpRpc('http://localhost:4000');
  final res = await fullNodeRpc.getCoinByName(Puzzlehash.fromHex('5b3411074ffcb230e29871abdad2f7c996b67737f3277f178a6bec42cc8a0a5e'));
  print(res.error);
  // await fullNodeRpc.(Puzzlehash.fromHex('6b3411074ffcb230e29871abdad2f7c996b67737f3277f178a6bec42cc8a0a5e'), 10000);
}
