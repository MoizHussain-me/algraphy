import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(ChatLoading());
      try {
        final messages = await _repository.getMessages(event.roomId);
        emit(ChatMessagesLoaded(messages));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    });

    on<SendMessage>((event, emit) async {
      try {
        final message = await _repository.sendMessage(event.roomId, event.message);
        emit(ChatMessageSent(message));
        // Reload messages after sending
        add(LoadMessages(event.roomId));
      } catch (e) {
        emit(ChatError(e.toString()));
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
