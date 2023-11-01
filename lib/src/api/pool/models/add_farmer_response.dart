class AddFarmerResponse {
  AddFarmerResponse({required this.welcomeMessage});

  factory AddFarmerResponse.fromJson(Map<String, dynamic> json) {
    return AddFarmerResponse(
      welcomeMessage: json['welcome_message'] as String,
    );
  }
  final String welcomeMessage;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'welcome_message': welcomeMessage,
      };

  @override
  String toString() => 'AddFarmerResponse(welcomeMessage: $welcomeMessage)';
}
