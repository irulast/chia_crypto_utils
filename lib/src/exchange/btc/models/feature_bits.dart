import 'package:chia_crypto_utils/src/exchange/btc/models/feature.dart';

class FeatureBits {
  FeatureBits({
    required this.wordLength,
    required this.optionDataLossProtect,
    required this.initialRoutingSync,
    required this.optionUpfrontShutdownScript,
    required this.gossipQueries,
    required this.varOnionOptin,
    required this.gossipQueriesEx,
    required this.paymentSecret,
    required this.basicMpp,
    required this.optionSupportLargeChannel,
    required this.optionAnchorOutputs,
    required this.optionAnchorsZeroFeeHtlcTx,
    required this.optionShutdownAnySegwit,
    required this.optionChannelType,
    required this.optionPaymentMetadata,
  });

  int wordLength;
  Feature optionDataLossProtect;
  Feature initialRoutingSync;
  Feature optionUpfrontShutdownScript;
  Feature gossipQueries;
  Feature varOnionOptin;
  Feature gossipQueriesEx;
  Feature paymentSecret;
  Feature basicMpp;
  Feature optionSupportLargeChannel;
  Feature optionAnchorOutputs;
  Feature optionAnchorsZeroFeeHtlcTx;
  Feature optionShutdownAnySegwit;
  Feature optionChannelType;
  Feature optionPaymentMetadata;
}
