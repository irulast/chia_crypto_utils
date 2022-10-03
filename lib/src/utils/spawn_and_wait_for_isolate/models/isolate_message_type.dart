enum IsolateMessageType {
  result,
  progressUpdate,
}

IsolateMessageType getIsolateMessageTypeFromJson(Map<String, dynamic> json) {
  return isolateMessageTypeFromString(json['type'] as String);
}

IsolateMessageType isolateMessageTypeFromString(String typeString) {
  if (typeString == IsolateMessageType.progressUpdate.name) {
    return IsolateMessageType.progressUpdate;
  }
  if (typeString == IsolateMessageType.result.name) {
    return IsolateMessageType.result;
  }
  throw Exception('invalid IsolateMessageType: $typeString');
}
