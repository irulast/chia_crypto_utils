import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  test('Should correctly decode send transaction response JSON', () {
    final json = jsonDecode(
            '{"data":{"success":true,"transaction":{"additions":[{"amount":50,"parentCoinInfo":"0xab5fe9043963a611087701e58d11c1096981960aafd343e0446ea4167c646a43","puzzleHash":"0x4012fa8181a987fba0cd3e0e5afe3a4354e663c5ad656d8e1c1182438a8b01c9"},{"amount":9993659469,"parentCoinInfo":"0xab5fe9043963a611087701e58d11c1096981960aafd343e0446ea4167c646a43","puzzleHash":"0x9b9d826c1df3dfe01e75adf5fc70c50c08f87cea30641530127f27f19f0aed3a"}],"amount":50,"confirmed":false,"confirmedAtHeight":0,"createdAtTime":1687382575,"feeAmount":50,"memos":{},"name":"0x84259c3a4ff83db27e24c94d66516d618fa02af53c324eabce9f2eaad40cf3bf","removals":[{"amount":9993659569,"parentCoinInfo":"0xc25ea896c38e7cde7d1b320ca4102d82a8ec7ad1090abc1e74e3f4c12ed75d5a","puzzleHash":"0x33b7e842a68e7a5f3cb339a909e7b347f5c6d1e5395fc348b3bcf8b6e9fe39f8"}],"sent":0,"sentTo":[],"spendBundle":{"aggregatedSignature":"0xa9f636e60870e665ff05c30c4f9060a157bd17cfded947c21c00695b6c6f5bc1cf882ea9b58bed8682433c7b90059dae06e1ee3842aca32548d86985727af0c44681e5d0a60bac6f3618f70152020c010e85d6aa1a624cc571f338d98a17c8a2","coinSpends":[{"coin":{"amount":9993659569,"parentCoinInfo":"0xc25ea896c38e7cde7d1b320ca4102d82a8ec7ad1090abc1e74e3f4c12ed75d5a","puzzleHash":"0x33b7e842a68e7a5f3cb339a909e7b347f5c6d1e5395fc348b3bcf8b6e9fe39f8"},"puzzleReveal":"0xff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b088e568d099358396a59345ac1706dfd3fe50464fd5a11ce56b84935e7acc51feed7ee903db9e23778f3a631190c11afaff018080","solution":"0xff80ffff01ffff33ffa04012fa8181a987fba0cd3e0e5afe3a4354e663c5ad656d8e1c1182438a8b01c9ff3280ffff33ffa09b9d826c1df3dfe01e75adf5fc70c50c08f87cea30641530127f27f19f0aed3aff850253ab244d80ffff34ff3280ffff3cffa0dd47d6eb8d7dc1acf499d3be42b587823822c87a022274b2454873d8d23e89278080ff8080"}]},"toAddress":"xch1gqf04qvp4xrlhgxd8c894l36gd2wvc7944jkmrsuzxpy8z5tq8ys62j3n5","toPuzzleHash":"0x4012fa8181a987fba0cd3e0e5afe3a4354e663c5ad656d8e1c1182438a8b01c9","tradeId":null,"type":1,"walletId":1},"transactionId":"0x84259c3a4ff83db27e24c94d66516d618fa02af53c324eabce9f2eaad40cf3bf"}}')
        as Map<String, dynamic>;

    final res = SendTransactionResponse.fromJson(json);
    print(res.sentTransactionData.transaction.spendBundle);
  });
}
