import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class GetFarmerResponse {
  const GetFarmerResponse({
    required this.authenticationPublicKey,
    required this.payoutInstructions,
    required this.currentDifficulty,
    required this.currentPoints,
  });
  factory GetFarmerResponse.fromJson(Map<String, dynamic> json) {
    return GetFarmerResponse(
      authenticationPublicKey: JacobianPoint.fromHexG1(json['authentication_public_key'] as String),
      payoutInstructions: json['payout_instructions'] as String,
      currentDifficulty: json['current_difficulty'] as int,
      currentPoints: json['current_points'] as int,
    );
  }
  final JacobianPoint authenticationPublicKey;
  final String payoutInstructions;
  final int currentDifficulty;
  final int currentPoints;
}

typedef Farmer = GetFarmerResponse;
