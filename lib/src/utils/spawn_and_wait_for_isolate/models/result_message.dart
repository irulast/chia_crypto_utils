import 'package:chia_crypto_utils/src/utils/spawn_and_wait_for_isolate/models/isolate_message_type.dart';

class ResultMessage {
  ResultMessage(this.body);

  ResultMessage.fromJson(Map<String, dynamic> json)
      : body = json['body'] as Map<String, dynamic>;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': IsolateMessageType.result.name,
        'body': body,
      };

  final Map<String, dynamic> body;
}
