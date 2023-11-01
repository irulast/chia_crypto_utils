import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  test('should parse tibet swap cat solution correctly', () {
    final solution = Program.parse(
      '(() (0x0bdc8bf623102aff163d59e8eef87fa2148167ca82a2f351b627bb477100a425 0x46fbfc323424945f9668c2688c19fb2a2a42ce04925a7032445e78444a70df46 0x05f5e100) 0xee555b0273f7cae7bf7196a4087eb8b484000d8368cc11ce04a6fde8848b3e7a (0x1535144d3e1337a60e249eaa88cac595618895cabd1b6c32a4c6a62b895a8415 0x1787ae726f6e5d4a9b128dfe03548b08ab60ec8fba3228fa5d45648585f33484 0x00989680) (0x5eea91688d21b0bf943426f989601eb3d1b29f342f5290cd960dcf697a14eb90 0x67a7f82634ec56ba4af0bb4c8bb0c5187f0be77c4d5efcce14b3a9558319f52d 0x277cec6cc8) () ())',
    );

    final parsed = CatSolution.fromProgram(solution);

    expect(parsed.extraDelta, 0);
    expect(parsed.previousSubtotal, 0);

    expect(parsed.innerPuzzleSolution, Program.nil);

    expect(
      parsed.lineageProof,
      Program.parse(
        '(0x0bdc8bf623102aff163d59e8eef87fa2148167ca82a2f351b627bb477100a425 0x46fbfc323424945f9668c2688c19fb2a2a42ce04925a7032445e78444a70df46 0x05f5e100)',
      ),
    );

    expect(
      parsed.previousCoinId,
      Bytes.fromHex(
          '0xee555b0273f7cae7bf7196a4087eb8b484000d8368cc11ce04a6fde8848b3e7a'),
    );

    expect(
      parsed.thisCoinInfo,
      CoinPrototype(
        parentCoinInfo: Bytes.fromHex(
            '0x1535144d3e1337a60e249eaa88cac595618895cabd1b6c32a4c6a62b895a8415'),
        puzzlehash: Puzzlehash.fromHex(
          '0x1787ae726f6e5d4a9b128dfe03548b08ab60ec8fba3228fa5d45648585f33484',
        ),
        amount: 10000000,
      ),
    );

    expect(
      parsed.nextCoinProof,
      CoinPrototype(
        parentCoinInfo: Bytes.fromHex(
            '0x5eea91688d21b0bf943426f989601eb3d1b29f342f5290cd960dcf697a14eb90'),
        puzzlehash: Puzzlehash.fromHex(
          '0x67a7f82634ec56ba4af0bb4c8bb0c5187f0be77c4d5efcce14b3a9558319f52d',
        ),
        amount: 169599593672,
      ),
    );
  });
}
