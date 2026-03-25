import '../../data/models/chat_message.dart';
abstract class ChatEvent {}

class LoadChatRooms extends ChatEvent {}

class LoadMessages extends ChatEvent {
  final int roomId;
  final bool isBackground;
  LoadMessages(this.roomId, {this.isBackground = false});
}

class SendMessage extends ChatEvent {
  final int roomId;
  final String message;
  final String type;
  final int? replyToId;
  SendMessage(this.roomId, this.message, {this.type = 'text', this.replyToId});
}

class SelectReplyMessage extends ChatEvent {
  final ChatMessage? message;
  SelectReplyMessage(this.message);
}

class StartChatWithUser extends ChatEvent {
  final int userId;
  StartChatWithUser(this.userId);
}
