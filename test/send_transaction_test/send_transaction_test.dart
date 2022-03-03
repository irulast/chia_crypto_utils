import 'dart:convert';
import 'dart:developer';

import 'package:bech32m/bech32m.dart';
import 'package:bip39/bip39.dart';
import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/models/coin.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;

import 'models/balance_response.dart';
import 'models/record_response.dart';
import 'models/records_response.dart';

void main() async{
  const baseURL = 'http://localhost:8080/api';
  Future<int> fetchWalletBalance(List<String> walletAddresses) async {
    try {
      final balanceData = await http.post(
        Uri.parse('$baseURL/v3/coin_records/get_balance'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, List<String>>{
          'addresses': walletAddresses,
        }),
      );

      if (balanceData.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        BalanceResponse balanceResponse =
            BalanceResponse.fromJson(jsonDecode(balanceData.body));

        return balanceResponse.balance;
      } else {
        // If the server did not return a 200 OK response,
        // var baseResponse = BaseResponse.fromJson(jsonDecode(balanceData.body));
        throw Exception('ERROR: bad balance fetch');
      }
    } on Exception catch (e) {
      throw Exception('${e.toString()}.');
    }
  }
  //transaction info
  const address = 'txch1pdar6hnj8c9sgm74r72u40ed8cnpduzan5vr86qkvpftg0v52jksxp6hy3';
  const amount = 10000;
  const fee = 0;
  var totalAmount = amount + fee;

  var hardMnemonic = 'guilt rail green junior loud track cupboard citizen begin play west adapt myself panda eye finger nuclear someone update light dance exotic expect layer';
  var seed = mnemonicToSeed(hardMnemonic);
  var masterSk = PrivateKey.fromSeed(seed);
  List<WalletSet> walletsSetList = [];
  for(var i = 0; i < 50; i++) {
      final set1 = WalletSet.fromPrivateKey(masterSk, i, testnet: true);
      walletsSetList.add(set1);
  }
  log('generated wallet sets');

  final walletKeychain = WalletKeychain(walletsSetList);

  final unhardenedAdresses = walletKeychain.unhardenedMap.values.map((vec) => vec.address).toList();

  // // get balance
  var balance = await fetchWalletBalance(unhardenedAdresses);
  print(balance.toString());

  // return;

  
  final responseData = await http.post(Uri.parse('$baseURL/v3/coin_records/get_coin_records'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'addresses': unhardenedAdresses,
  }));

  if (responseData.statusCode != 200) {
    throw Exception('bad coin record fetch');
  }
  log('fetched coin records');

  List<RecordResponse> spendRecords = [];
  var spendAmount = 0;

  RecordsResponse recordsResponse =
      RecordsResponse.fromJson(jsonDecode(responseData.body));
  var records = recordsResponse.records;
  records = records.where((element) => element.spentBlockIndex == 0).toList();
  records.sort((a, b) => b.coin.amount - a.coin.amount);
  
  
  calculator:
  while (records.isNotEmpty && spendAmount < totalAmount) {
    for (var i = 0; i < records.length; i++) {
      if (spendAmount + records[i].coin.amount <= totalAmount) {
        var record = records.removeAt(i--);
        spendRecords.add(record);
        spendAmount += record.coin.amount;
        continue calculator;
      }
    }
    var record = records.removeAt(0);
    spendRecords.add(record);
    spendAmount += record.coin.amount;
  }

  if (spendAmount < totalAmount) {
    log('Insufficient funds.');
  }
  assert(spendRecords.length == 1);
  final record = spendRecords[0];

  print(record.spentBlockIndex);

  final originalCoin = Coin(Puzzlehash.fromHex(record.coin.parentCoinInfo), Puzzlehash.fromHex(record.coin.puzzleHash), record.coin.amount);

  final walletVector = walletKeychain.getWalletVector(originalCoin.puzzlehash);

  var change = spendAmount - amount - fee;
  
  var privateKey = walletVector!.childPrivateKey;
  var publicKey = privateKey.getG1();

  var destinationHash = segwit.decode(address).program;
  var changeHash = walletVector.puzzleHash;
  final sendCoin = Coin(originalCoin.puzzlehash, Puzzlehash(destinationHash), amount).id.bytes;

  final changeCoin = Coin(originalCoin.puzzlehash, changeHash, change).id.bytes;

  var createCoinAnnouncementMessage = sha256.convert(originalCoin.id.bytes + sendCoin + changeCoin).bytes;
  var solutionConditions = Program.list(
            [
              Program.fromBigInt(BigInt.from(0x01)), // q
              Program.list([
                Program.fromInt(51),
                Program.fromBytes(destinationHash),
                Program.fromInt(amount)
              ])
            ] + 
            (
              change > 0 
                ? 
                  [
                    Program.list([
                      Program.fromInt(51),
                      Program.fromBytes(changeHash.bytes),
                      Program.fromInt(change)
                    ])
                  ] 
                : 
                  []
            ) +
            [
              Program.list([
                Program.fromInt(60),
                Program.fromBytes(createCoinAnnouncementMessage),
              ])
            ]
          );
  var solution = Program.list([Program.nil, solutionConditions, Program.nil]);

  final puzzle = getPuzzleFromPk(publicKey);
  // pk: [160, 97, 17, 193, 104, 65, 127, 101, 41, 213, 151, 159, 219, 65, 179, 199, 204, 43, 36, 32, 165, 37, 226, 235, 142, 110, 224, 80, 95, 38, 127, 55, 142, 200, 205, 106, 233, 157, 232, 12, 86, 152, 200, 250, 101, 216, 38, 149]



  
  var result = puzzle.run(solution);

  var addsigm = result.program.toList()[0].toList()[2].atom + originalCoin.id.bytes + const HexDecoder().convert('ae83525ba8d1dd3f09b277de18ca3e43fc0af20d20c4b3e92ef2a48bd291ccb2');
  var syntheticPublicKey = JacobianPoint.fromBytesG1(result.program.toList()[0].toList()[1].atom);

  // pk: [160, 97, 17, 193, 104, 65, 127, 101, 41, 213, 151, 159, 219, 65, 179, 199, 204, 43, 36, 32, 165, 37, 226, 235, 142, 110, 224, 80, 95, 38, 127, 55, 142, 200, 205, 106, 233, 157, 232, 12, 86, 152, 200, 250, 101, 216, 38, 149]
  // 
  var synthSecretKey = calculateSyntheticPrivateKey(privateKey);
  final syntheticPublicKeyFromSecretKey = synthSecretKey.getG1();
  // [175, 62, 253, 46, 191, 236, 125, 29, 198, 184, 51, 5, 61, 201, 81, 151, 54, 48, 149, 73, 203, 117, 89, 106, 1, 232, 209, 204, 54, 3, 71, 164, 225, 17, 235, 170, 35, 56, 127, 153, 141, 146, 77, 151, 193, 95, 65, 164]
  final signature = AugSchemeMPL.sign(synthSecretKey, addsigm);
  assert(AugSchemeMPL.verify(syntheticPublicKey, addsigm, signature));

  var aggregate = AugSchemeMPL.aggregate([signature]);
  var aggBytes = aggregate.toBytes();
  // e2ebed61b70c0541d447f0b80ce356024f110939bb3ee8aa34a38af360987d06
  // recieved = [171, 50, 187, 91, 134, 213, 233, 96, 24, 145, 14, 245, 177, 235, 161, 157, 38, 117, 31, 145, 39, 159, 237, 210, 22, 173, 184, 118, 42, 240, 48, 254, 248, 186, 236, 76, 146, 168, 95, 66, 13, 236, 215, 241, 17, 41, 165, 127, 5, 57, 249, 13, 55, 82, 233, 157, 196, 49, 96, 154, 44, 26, 151, 216, 52, 113, 228, 118, 157, 22, 216, 77, 154, 154, 172, 78, 191, 205, 19, 2, 167, 17, 213, 47, 213, 98, 171, 44, 118, 147, 142, 255, 195, 114, 23, 133]

  //sent =      [171, 50, 187, 91, 134, 213, 233, 96, 24, 145, 14, 245, 177, 235, 161, 157, 38, 117, 31, 145, 39, 159, 237, 210, 22, 173, 184, 118, 42, 240, 48, 254, 248, 186, 236, 76, 146, 168, 95, 66, 13, 236, 215, 241, 17, 41, 165, 127, 5, 57, 249, 13, 55, 82, 233, 157, 196, 49, 96, 154, 44, 26, 151, 216, 52, 113, 228, 118, 157, 22, 216, 77, 154, 154, 172, 78, 191, 205, 19, 2, 167, 17, 213, 47, 213, 98, 171, 44, 118, 147, 142, 255, 195, 114, 23, 133]

  var spend = {
      'coin': record.coin.toJson(),
      'puzzle_reveal': const HexEncoder()
          .convert(puzzle.serialize()),
      'solution': const HexEncoder().convert(solution.serialize())
  };

  print('sending spendbundle');
  // final body = jsonEncode(<String, dynamic>{
  //                   'spend_bundle': {
  //                     'coin_spends': [spend],
  //                     'aggregated_signature':
  //                         const HexEncoder().convert(aggregate.toBytes())
  //                   }
  //                 });
  // print(body);
  // return;
  try {
          final responseData =
              await http.post(Uri.parse('$baseURL/v3/transactions/send_transaction'),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, dynamic>{
                    'spend_bundle': {
                      'coin_spends': [spend],
                      'aggregated_signature':
                          const HexEncoder().convert(aggregate.toBytes())
                    },
                    'blockchain': 'txch'
                  }));
          if (responseData.statusCode == 200) {
            print('success');
          } else {
            print(responseData.body);
          }
        } on Exception catch (e) {
          print(e.toString());
        }
  
}