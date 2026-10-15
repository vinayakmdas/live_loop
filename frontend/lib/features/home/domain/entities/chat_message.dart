class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    try {
      final rawTime = json['timestamp'];
      if (rawTime is String) {
        parsedTime = DateTime.parse(rawTime).toLocal();
      } else if (rawTime is int) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTime).toLocal();
      } else {
        parsedTime = DateTime.now();
      }
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return ChatMessage(
      id: json['id']?.toString() ??
          '${DateTime.now().millisecondsSinceEpoch}_${json['senderId'] ?? ''}',
      roomId: json['roomId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? 'anonymous',
      senderName: json['senderName']?.toString() ?? 'Participant',
      text: json['text']?.toString() ?? '',
      timestamp: parsedTime,
      isSystem: json['isSystem'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isSystem': isSystem,
    };
  }

  bool isFromUser(String? currentUserId, String? currentUserName) {
    if (currentUserId != null &&
        currentUserId.isNotEmpty &&
        currentUserId == senderId) {
      return true;
    }
    if (currentUserName != null &&
        currentUserName.isNotEmpty &&
        currentUserName.toLowerCase() == senderName.toLowerCase()) {
      return true;
    }
    return false;
  }

  String get formattedTime {
    final hour24 = timestamp.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }
}
