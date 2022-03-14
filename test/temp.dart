import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:hex/hex.dart';

void main() {
  var x = HexEncoder().convert(Program.parse('(=)').serialize());
  print(Program.deserializeHex('ff0980'));
}