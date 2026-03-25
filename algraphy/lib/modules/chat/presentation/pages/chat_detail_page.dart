import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/injector.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import 'group_info_page.dart';

class ChatDetailPage extends StatefulWidget {
  final int roomId;
  final String participantName;
  final String? participantImage;

  const ChatDetailPage({
    super.key,
    required this.roomId,
    required this.participantName,
    this.participantImage,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatBloc _chatBloc;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(getIt<ChatRepository>())..add(LoadMessages(widget.roomId));
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _chatBloc.add(LoadMessages(widget.roomId, isBackground: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int currentUserId = int.tryParse(
      (context.read<AuthBloc>().state as AuthAuthenticated).user.id
    ) ?? 0;

    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: ImageHelper.getProvider(widget.participantImage),
                child: widget.participantImage == null
                    ? Text(widget.participantName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Text(widget.participantName),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline), 
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupInfoPage(
                      roomId: widget.roomId,
                      groupName: widget.participantName,
                    ),
                  ),
                );
              }
            ),
          ],
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatMessagesLoaded) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: _buildMessagesList(context, state, currentUserId),
                ),
                _buildInputArea(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, ChatState state, int currentUserId) {
    if (state is ChatLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ChatMessagesLoaded) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final msg = state.messages[index];
          final isMe = msg.isMe(currentUserId);
          return _buildMessageBubble(msg, isMe);
        },
      );
    } else if (state is ChatError) {
      return Center(child: Text(state.message));
    }
    return const SizedBox();
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return GestureDetector(
      onLongPress: () {
        _chatBloc.add(SelectReplyMessage(msg));
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe 
                ? AppColors.primaryRed 
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
            ),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.replyMessage != null) ...[
                _buildReplyBubble(msg),
              ],
              if (msg.messageType == 'image') ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    msg.message,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                    },
                  ),
                ),
                const SizedBox(height: 4),
              ] else if (msg.messageType == 'file') ...[
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(msg.message.split('/').last, style: const TextStyle(color: Colors.white, fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 4),
              ] else ...[
                Text(
                  msg.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.formattedTime,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.id == -1 ? Icons.access_time : Icons.done_all,
                      size: 12,
                      color: msg.isRead ? Colors.blue : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, ChatState state) {
    ChatMessage? replyTo;
    if (state is ChatMessagesLoaded) {
      replyTo = state.replyTo;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (replyTo != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(replyTo.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(replyTo.message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => _chatBloc.add(SelectReplyMessage(null)),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: _pickAndSendMedia,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final message = _messageController.text.trim();
                    if (message.isNotEmpty) {
                      _chatBloc.add(
                        SendMessage(widget.roomId, message, replyToId: replyTo?.id),
                      );
                      _messageController.clear();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBubble(ChatMessage msg) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Colors.white, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.replyUserName ?? "Reply",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white70),
          ),
          Text(
            msg.replyMessage!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.bytes != null) {
      try {
        final fileName = result.files.single.name;
        final bytes = result.files.single.bytes!.toList();
        final type = (['jpg', 'jpeg', 'png'].contains(result.files.single.extension?.toLowerCase())) ? 'image' : 'file';
        
        // Use repository directly or add event to Bloc
        final url = await getIt<ChatRepository>().uploadMedia(bytes, fileName);
        _chatBloc.add(SendMessage(widget.roomId, url, type: type));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
        }
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
