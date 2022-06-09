import 'dart:convert';

import 'package:chia_crypto_utils/src/api/pool/models/add_farmer_response.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final addFarmerResponse = AddFarmerResponse.fromJson(
    jsonDecode(
      '{"welcome_message":"Welcome to Flexpool.io, the world\'s most secure and scalable mining pool!"}',
    ) as Map<String, dynamic>,
  );

  test('should create from json response', () {
    expect(
      addFarmerResponse.welcomeMessage,
      "Welcome to Flexpool.io, the world's most secure and scalable mining pool!",
    );
  });

  test('should return the desired string form', () {
    expect(
      addFarmerResponse.toString(),
      'AddFarmerResponse(welcomeMessage: ${addFarmerResponse.welcomeMessage})',
    );
  });
}
