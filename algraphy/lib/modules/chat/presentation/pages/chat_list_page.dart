import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/injector.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/image_helper.dart';
import '../../data/repositories/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/create_group_sheet.dart';
import '../widgets/user_selection_sheet.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  Timer? _timer;
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(getIt<ChatRepository>());
    _chatBloc.add(LoadChatRooms());
    
    // Polling rooms every 5 seconds for real-time updates
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _chatBloc.add(LoadChatRooms());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatStarted) {
            // Navigate to detail page logic
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              _buildSearchField(context),
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state is ChatLoading && _chatBloc.state is! ChatRoomsLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ChatRoomsLoaded || _chatBloc.state is ChatRoomsLoaded) {
                      final rooms = state is ChatRoomsLoaded ? state.rooms : (_chatBloc.state as ChatRoomsLoaded).rooms;
                      if (rooms.isEmpty) {
                        return _buildEmptyState();
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: rooms.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 80,
                          color: Colors.white10,
                        ),
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return _buildChatTile(context, room);
                        },
                      );
                    } else if (state is ChatError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                onPressed: () => _createNewGroup(context),
                backgroundColor: Colors.white24,
                heroTag: 'new_group',
                child: const Icon(Icons.group_add, color: Colors.white),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                onPressed: () => _startNewConversation(context),
                backgroundColor: AppColors.primaryRed,
                heroTag: 'new_chat',
                child: const Icon(Icons.message, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startNewConversation(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UserSelectionSheet(),
    );

    if (result != null && mounted) {
      final int otherUserId = int.tryParse(result['userId']?.toString() ?? result['user_id']?.toString() ?? '0') ?? 0;
      if (otherUserId > 0) {
        try {
          final repo = getIt<ChatRepository>();
          final roomId = await repo.startChat(otherUserId);
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  roomId: roomId,
                  participantName: "${result['first_name'] ?? ''} ${result['last_name'] ?? ''}".trim(),
                  participantImage: result['profile_picture'],
                ),
              ),
            ).then((_) {
              _chatBloc.add(LoadChatRooms());
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error starting chat: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _createNewGroup(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupSheet(),
    );

    if (result != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            roomId: result['roomId'],
            participantName: result['name'],
          ),
        ),
      ).then((_) {
        _chatBloc.add(LoadChatRooms());
      });
    }
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search messages...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, dynamic room) {
    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primaryRed.withOpacity(0.1),
        backgroundImage: ImageHelper.getProvider(room.participantImage),
        child: room.participantImage == null
            ? Text(
                room.participantName?.isNotEmpty == true
                    ? room.participantName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        room.participantName ?? 'Unknown User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        room.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: room.unreadCount > 0 ? Colors.white : Colors.grey,
          fontWeight: room.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            room.formattedLastTime,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (room.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${room.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              roomId: room.id,
              participantName: room.participantName ?? 'Chat',
              participantImage: room.participantImage,
            ),
          ),
        ).then((_) {
          _chatBloc.add(LoadChatRooms());
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a new chat to begin.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
