enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.time,
  });

  factory ChatMessage.user(String text, DateTime time) => ChatMessage(
        id: 'u${time.microsecondsSinceEpoch}',
        role: ChatRole.user,
        text: text,
        time: time,
      );

  factory ChatMessage.assistant(String text, DateTime time) => ChatMessage(
        id: 'a${time.microsecondsSinceEpoch}',
        role: ChatRole.assistant,
        text: text,
        time: time,
      );

  final String id;
  final ChatRole role;
  final String text;
  final DateTime time;

  bool get isUser => role == ChatRole.user;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'r': role.name,
        't': text,
        'at': time.millisecondsSinceEpoch,
      };

  static ChatMessage? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final r = json['r'];
    final t = json['t'];
    final at = json['at'];
    if (id is! String || t is! String || at is! num) return null;
    final role = r == 'assistant' ? ChatRole.assistant : ChatRole.user;
    return ChatMessage(
      id: id,
      role: role,
      text: t,
      time: DateTime.fromMillisecondsSinceEpoch(at.toInt()),
    );
  }
}
