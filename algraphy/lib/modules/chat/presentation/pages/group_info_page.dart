import 'package:flutter/material.dart';
import '../../../../config/di/injector.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/image_helper.dart';
import '../../data/repositories/chat_repository.dart';
import '../widgets/user_selection_sheet.dart';

class GroupInfoPage extends StatefulWidget {
  final int roomId;
  final String groupName;

  const GroupInfoPage({
    super.key,
    required this.roomId,
    required this.groupName,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final ChatRepository _repository = getIt<ChatRepository>();
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final participants = await _repository.getParticipants(widget.roomId);
      setState(() {
        _participants = participants;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addMember() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UserSelectionSheet(),
    );

    if (result != null && mounted) {
      final userId = int.tryParse(result['user_id']?.toString() ?? result['id']?.toString() ?? '0') ?? 0;
      if (userId > 0) {
        try {
          await _repository.addMember(widget.roomId, userId);
          _loadParticipants();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding member: $e')));
          }
        }
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group? This will remove all messages and members.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _repository.deleteGroup(widget.roomId);
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting group: $e')));
        }
      }
    }
  }

  Future<void> _removeMember(int userId) async {
    try {
      await _repository.removeMember(widget.roomId, userId);
      _loadParticipants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing member: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                  child: Text(
                    widget.groupName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: AppColors.primaryRed, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.groupName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_participants.length} Participants',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Participants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person_add, color: AppColors.primaryRed),
                            onPressed: _addMember,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: _deleteGroup,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _participants.length,
                    itemBuilder: (context, index) {
                      final p = _participants[index];
                      final name = "${p['first_name']} ${p['last_name']}".trim();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: ImageHelper.getProvider(p['profile_picture']),
                          child: p['profile_picture'] == null ? Text(name[0].toUpperCase()) : null,
                        ),
                        title: Text(name),
                        subtitle: Text(p['designation'] ?? 'Member'),
                        trailing: p['role'] == 'admin'
                            ? const Text('Admin', style: TextStyle(color: AppColors.primaryRed, fontSize: 12))
                            : IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                onPressed: () => _removeMember(int.parse(p['user_id'].toString())),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
