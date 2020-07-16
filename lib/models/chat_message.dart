enum ChatMessageType { sent, received }

class ChatMessage {
  final String name;
  String text;
  final ChatMessageType type;

  ChatMessage({
    this.name,
    this.text,
    this.type = ChatMessageType.sent,
  });
}