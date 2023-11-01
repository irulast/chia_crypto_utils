import 'package:chia_crypto_utils/src/utils/spawn_and_wait_for_isolate/models/isolate_message_type.dart';

class ProgressUpdateMessage {
  ProgressUpdateMessage(this.progress);
  ProgressUpdateMessage.fromJson(Map<String, dynamic> json)
      : progress = json['progress'] as double;

  final double progress;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': IsolateMessageType.progressUpdate.name,
        'progress': progress,
      };
}
