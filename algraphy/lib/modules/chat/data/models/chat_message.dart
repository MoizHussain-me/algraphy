import 'package:intl/intl.dart';

class ChatMessage {
  final int id;
  final int roomId;
  final int senderId;
  final String senderName;
  final String message;
  final String messageType;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.messageType = 'text',
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      roomId: int.tryParse(map['room_id']?.toString() ?? '0') ?? 0,
      senderId: int.tryParse(map['sender_id']?.toString() ?? '0') ?? 0,
      senderName: "${map['first_name'] ?? ''} ${map['last_name'] ?? ''}".trim(),
      message: map['message'] ?? '',
      messageType: map['message_type'] ?? 'text',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedTime => DateFormat('hh:mm a').format(createdAt);
  
  bool isMe(int currentUserId) => senderId == currentUserId;
}
