abstract class ChatEvent {}

class LoadChatRooms extends ChatEvent {}

class LoadMessages extends ChatEvent {
  final int roomId;
  LoadMessages(this.roomId);
}

class SendMessage extends ChatEvent {
  final int roomId;
  final String message;
  SendMessage(this.roomId, this.message);
}

class StartChatWithUser extends ChatEvent {
  final int userId;
  StartChatWithUser(this.userId);
}
