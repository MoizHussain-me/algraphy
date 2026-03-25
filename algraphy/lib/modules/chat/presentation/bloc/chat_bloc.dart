import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;

  ChatBloc(this._repository) : super(ChatInitial()) {
    on<LoadChatRooms>((event, emit) async {
      emit(ChatLoading());
      try {
        final rooms = await _repository.getChatRooms();
        emit(ChatRoomsLoaded(rooms));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    });

    on<LoadMessages>((event, emit) async {
      final currentState = state;
      if (!event.isBackground) {
        emit(ChatLoading());
      }
      try {
        final messages = await _repository.getMessages(event.roomId);
        ChatMessage? currentReplyTo;
        if (currentState is ChatMessagesLoaded) {
          currentReplyTo = currentState.replyTo;
        }
        emit(ChatMessagesLoaded(messages, replyTo: currentReplyTo));
      } catch (e) {
        if (!event.isBackground) emit(ChatError(e.toString()));
      }
    });

    on<SendMessage>((event, emit) async {
      final currentState = state;
      if (currentState is ChatMessagesLoaded) {
        // Optimistic update
        final tempMsg = ChatMessage(
          id: -1, // Temporary ID
          roomId: event.roomId,
          senderId: -1, // Will be fixed by isMe check or real ID
          senderName: "Sending...",
          message: event.message,
          messageType: event.type,
          createdAt: DateTime.now(),
          replyToId: event.replyToId,
          // We can't easily get replyMessage here without searching, 
          // but optimistic UI usually shows simple text first.
        );
        
        final updatedMessages = List<ChatMessage>.from(currentState.messages)..add(tempMsg);
        emit(ChatMessagesLoaded(updatedMessages, replyTo: null)); // Clear reply on send
      }

      try {
        await _repository.sendMessage(
          event.roomId, 
          event.message, 
          type: event.type, 
          replyToId: event.replyToId
        );
        // Reload real messages from server
        add(LoadMessages(event.roomId, isBackground: true));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    });

    on<SelectReplyMessage>((event, emit) {
      if (state is ChatMessagesLoaded) {
        final s = state as ChatMessagesLoaded;
        emit(ChatMessagesLoaded(s.messages, replyTo: event.message));
      }
    });

    on<StartChatWithUser>((event, emit) async {
      emit(ChatLoading());
      try {
        final roomId = await _repository.startChat(event.userId);
        emit(ChatStarted(roomId));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    });
  }
}
