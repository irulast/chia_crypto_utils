class AddFarmerResponse {
  final String welcomeMessage;

  AddFarmerResponse({required this.welcomeMessage});

  factory AddFarmerResponse.fromJson(Map<String, dynamic> json) {
    return AddFarmerResponse(
      welcomeMessage: json['welcome_message'] as String,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'welcome_message': welcomeMessage,
      };

  @override
  String toString() => 'AddFarmerResponse(welcomeMessage: $welcomeMessage)';
}
