import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NftRequestedPayment extends NftPayment {
  NftRequestedPayment(super.puzzlehash, this.nftRecord);
  final NftRecord nftRecord;
}

class NftPayment extends Payment {
  NftPayment(Puzzlehash puzzlehash)
      : super(
          1,
          puzzlehash,
          memos: <Bytes>[puzzlehash, puzzlehash],
        );
}
