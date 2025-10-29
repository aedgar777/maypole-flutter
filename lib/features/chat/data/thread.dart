// Parent class for all thread types
class Thread {
  final String id;
  final String name;
  final DateTime lastMessageTime;
  final List<dynamic>
  messages; // Will be List<Message> when Message class is created

  Thread({
    required this.id,
    required this.name,
    required this.lastMessageTime,
    required this.messages,
  });
}

// Subclass for place-based chat threads
class PlaceChatThread extends Thread {
  PlaceChatThread({
    required super.id,
    required super.name,
    required super.lastMessageTime,
    required super.messages,
  });
}

// Subclass for direct message threads
class DMThread extends Thread {
  final String partnerName;
  final String partnerId;
  final dynamic
  lastMessage; // Will be Message type when Message class is created

  DMThread({
    required super.id,
    required super.name,
    required super.lastMessageTime,
    required super.messages,
    required this.partnerName,
    required this.partnerId,
    required this.lastMessage,
  });
}