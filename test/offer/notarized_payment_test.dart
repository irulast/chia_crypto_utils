import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../util/test_data.dart';

void main() {
  test('should return the desired string form using a CAT1 coin', () {
    expect(
      TestData.cat1NotarizedPayment.toString(),
      'NotarizedPayment('
      'amount: ${TestData.cat1NotarizedPayment.amount}, '
      'puzzlehash: ${TestData.cat1NotarizedPayment.puzzlehash}, '
      'nonce: ${TestData.cat1NotarizedPayment.nonce}, '
      'memos: ${TestData.cat1NotarizedPayment.memos})',
    );
  });

  test('should return the desired string form using a CAT2 coin', () {
    expect(
      TestData.catNotarizedPayment.toString(),
      'NotarizedPayment('
      'amount: ${TestData.catNotarizedPayment.amount}, '
      'puzzlehash: ${TestData.catNotarizedPayment.puzzlehash}, '
      'nonce: ${TestData.catNotarizedPayment.nonce}, '
      'memos: ${TestData.catNotarizedPayment.memos})',
    );
  });
}
