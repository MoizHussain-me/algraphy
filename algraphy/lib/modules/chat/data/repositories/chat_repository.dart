import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/utils/constants.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';

class ChatRepository {
  final ApiClient _api;

  ChatRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<List<ChatRoom>> getChatRooms() async {
    final token = await _getToken();
    final response = await _api.get('get_chat_rooms', token: token);

    if (response['status'] == 'success') {
      final List<dynamic> data = response['data'] ?? [];
      return data.map((m) => ChatRoom.fromMap(m)).toList();
    } else {
      throw Exception(response['message'] ?? 'Failed to load chat rooms');
    }
  }

  Future<List<ChatMessage>> getMessages(int roomId) async {
    final token = await _getToken();
    final response = await _api.post('get_messages', {'room_id': roomId}, token: token);

    if (response['status'] == 'success') {
      final List<dynamic> data = response['data'] ?? [];
      return data.map((m) => ChatMessage.fromMap(m)).toList();
    } else {
      throw Exception(response['message'] ?? 'Failed to load messages');
    }
  }

  Future<ChatMessage> sendMessage(int roomId, String message, {String type = 'text'}) async {
    final token = await _getToken();
    final response = await _api.post('send_message', {
      'room_id': roomId,
      'message': message,
      'message_type': type,
    }, token: token);

    if (response['status'] == 'success') {
      return ChatMessage.fromMap(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Failed to send message');
    }
  }

  Future<int> startChat(int userId) async {
    final token = await _getToken();
    final response = await _api.post('start_chat', {'user_id': userId}, token: token);

    if (response['status'] == 'success') {
      return int.tryParse(response['room_id']?.toString() ?? '0') ?? 0;
    } else {
      throw Exception(response['message'] ?? 'Failed to start chat');
    }
  }
}
