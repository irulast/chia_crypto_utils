import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:equatable/equatable.dart';

class FullBlock extends Equatable with ToJsonMixin {
  const FullBlock(this.transactionGenerator, this.transactionGeneratorRefList);

  factory FullBlock.fromJson(Map<String, dynamic> json) {
    return FullBlock(
      pick(json, 'transactions_generator')
          .letStringOrNull(Program.deserializeHex),
      pick(json, 'transactions_generator_ref_list')
              .asListOrNull((p0) => p0.asIntOrThrow()) ??
          [],
    );
  }

  final Program? transactionGenerator;
  final List<int> transactionGeneratorRefList;

  @override
  List<Object?> get props =>
      [transactionGenerator, transactionGeneratorRefList];

  @override
  Map<String, dynamic> toJson() => {
        'transactions_generator': transactionGenerator?.toHex(),
        'transactions_generator_ref_list': transactionGeneratorRefList,
      };
}
