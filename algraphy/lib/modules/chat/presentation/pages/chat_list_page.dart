import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/injector.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/image_helper.dart';
import '../../data/repositories/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/user_selection_sheet.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(getIt<ChatRepository>())..add(LoadChatRooms()),
      child: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatStarted) {
            // Navigate to detail page with a clean title (needs participant info)
            // For now, reload rooms to get the full info or pass it from selection
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
                    if (state is ChatLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ChatRoomsLoaded) {
                      if (state.rooms.isEmpty) {
                        return _buildEmptyState();
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.rooms.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 80,
                          color: Colors.white10,
                        ),
                        itemBuilder: (context, index) {
                          final room = state.rooms[index];
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
          floatingActionButton: Builder(
            builder: (blocContext) => FloatingActionButton(
              onPressed: () => _startNewConversation(blocContext),
              backgroundColor: AppColors.primaryRed,
              child: const Icon(Icons.message, color: Colors.white),
            ),
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

    if (result != null && context.mounted) {
      final int otherUserId = int.tryParse(result['userId']?.toString() ?? result['user_id']?.toString() ?? '0') ?? 0;
      if (otherUserId > 0) {
        try {
          final repo = getIt<ChatRepository>();
          final roomId = await repo.startChat(otherUserId);
          
          if (context.mounted) {
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
              context.read<ChatBloc>().add(LoadChatRooms());
            });
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error starting chat: $e')),
            );
          }
        }
      }
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
          // Refresh rooms when coming back
          context.read<ChatBloc>().add(LoadChatRooms());
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
