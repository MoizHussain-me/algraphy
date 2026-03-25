import '../../data/models/chat_message.dart';
import '../../data/models/chat_room.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatRoomsLoaded extends ChatState {
  final List<ChatRoom> rooms;
  ChatRoomsLoaded(this.rooms);
}

class ChatMessagesLoaded extends ChatState {
  final List<ChatMessage> messages;
  final ChatMessage? replyTo;
  ChatMessagesLoaded(this.messages, {this.replyTo});
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}

class ChatMessageSent extends ChatState {
  final ChatMessage message;
  ChatMessageSent(this.message);
}

class ChatStarted extends ChatState {
  final int roomId;
  ChatStarted(this.roomId);
}
