import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class ParsedOffer with ToJsonMixin {
  ParsedOffer({
    required this.offeredAmounts,
    required this.requestedAmounts,
  });

  factory ParsedOffer.fromJson(Map<String, dynamic> json) {
    return ParsedOffer(
      offeredAmounts: pick(json, 'offeredAmounts').letJsonOrThrow(ParsedMixedAmounts.fromJson),
      requestedAmounts: pick(json, 'requestedAmounts').letJsonOrThrow(ParsedMixedAmounts.fromJson),
    );
  }
  final ParsedMixedAmounts offeredAmounts;
  final ParsedMixedAmounts requestedAmounts;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'offeredAmounts': offeredAmounts.toJson(),
      'requestedAmounts': requestedAmounts.toJson(),
    };
  }

  Map<String, dynamic> toJsonLists() => <String, dynamic>{
        'requestedAmounts': _getAmountsJson(requestedAmounts),
        'offeredAmounts': _getAmountsJson(offeredAmounts),
      };

  List<Map<String, dynamic>> _getAmountsJson(ParsedMixedAmounts pma) {
    final amounts = <Map<String, dynamic>>[];
    for (final pci in pma.cats) {
      amounts.add(pci.toJson());
    }
    for (final pni in pma.nfts) {
      amounts.add(pni.toJson());
    }
    if (pma.standard > 0) {
      amounts.add(<String, dynamic>{'type': 'xch', 'amount': pma.standard});
    }

    return amounts;
  }
}
