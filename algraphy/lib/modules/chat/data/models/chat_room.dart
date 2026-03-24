import 'package:intl/intl.dart';

class ChatRoom {
  final int id;
  final String? name;
  final String type;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? participantName;
  final String? participantImage;

  ChatRoom({
    required this.id,
    this.name,
    required this.type,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.participantName,
    this.participantImage,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      name: map['name'],
      type: map['type'] ?? 'peer',
      lastMessage: map['last_message'],
      lastMessageTime: DateTime.tryParse(map['last_message_time'] ?? '')?.toLocal(),
      unreadCount: int.tryParse(map['unread_count']?.toString() ?? '0') ?? 0,
      participantName: "${map['first_name'] ?? ''} ${map['last_name'] ?? ''}".trim(),
      participantImage: map['profile_picture'],
    );
  }

  String get formattedLastTime {
    if (lastMessageTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(lastMessageTime!);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yy').format(lastMessageTime!);
    }
  }
}
