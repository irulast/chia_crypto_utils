import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:equatable/equatable.dart';

class NameRegistrationPrice extends Equatable {
  const NameRegistrationPrice({
    required this.xch,
    required this.catPrices,
  });

  factory NameRegistrationPrice.fromJson(Map<String, dynamic> json) {
    final catPrices = <Puzzlehash, num>{};

    for (final entry in json.entries) {
      if (entry.key == _xchKey) {
        continue;
      }
      final assetId = Puzzlehash.maybeFromHex(entry.key);

      if (assetId != null) {
        catPrices[assetId] = pick(entry.value).asDoubleOrThrow();
      }
    }

    return NameRegistrationPrice(
      xch: pick(json, _xchKey).asDoubleOrThrow(),
      catPrices: catPrices,
    );
  }

  static const _xchKey = 'XCH';

  final double xch;

  final Map<Puzzlehash, num> catPrices;

  @override
  List<Object?> get props => [xch, catPrices];
}
