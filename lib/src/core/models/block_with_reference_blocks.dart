import 'package:chia_crypto_utils/src/core/models/full_block.dart';

class BlockWithReferenceBlocks {
  BlockWithReferenceBlocks(this.block, this.referenceBlocks);

  final FullBlock block;

  final List<FullBlock> referenceBlocks;
}
