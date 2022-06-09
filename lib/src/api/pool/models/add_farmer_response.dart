class AddFarmerResponse {
  final String welcomeMessage;

  AddFarmerResponse({required this.welcomeMessage});

  factory AddFarmerResponse.fromJson(Map<String, dynamic> json) {
    return AddFarmerResponse(
      welcomeMessage: json['welcome_message'] as String,
    );
  }

  @override
  String toString() => 'AddFarmerResponse(welcomeMessage: $welcomeMessage)';
}
