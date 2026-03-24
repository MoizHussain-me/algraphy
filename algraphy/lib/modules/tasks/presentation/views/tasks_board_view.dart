import 'package:algraphy/modules/tasks/data/models/task_model.dart';
import 'package:algraphy/modules/tasks/data/repository/tasks_repository.dart';
import 'package:algraphy/modules/tasks/presentation/views/task_details_view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:algraphy/core/theme/colors.dart';

class TasksBoardView extends StatelessWidget {
  final List<TaskModel> tasks;
  final Future<void> Function() onRefresh;

  const TasksBoardView({super.key, required this.tasks, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // Group tasks by status
    final map = {
      'pending': tasks.where((t) => t.status == 'pending').toList(),
      'in_progress': tasks.where((t) => t.status == 'in_progress').toList(),
      'completed': tasks.where((t) => t.status == 'completed').toList(),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: map.entries.map((entry) {
          return _BoardColumn(
            statusKey: entry.key,
            tasks: entry.value,
            onRefresh: onRefresh,
          );
        }).toList(),
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  final String statusKey;
  final List<TaskModel> tasks;
  final Future<void> Function() onRefresh;

  const _BoardColumn({required this.statusKey, required this.tasks, required this.onRefresh});

  String _getStatusTitle() {
    switch (statusKey) {
      case 'pending': return "To Do";
      case 'in_progress': return "In Progress";
      case 'completed': return "Done";
      default: return statusKey.toUpperCase();
    }
  }

  Color _getColor() {
    switch (statusKey) {
      case 'pending': return Colors.grey;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(
                  _getStatusTitle(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  tasks.length.toString(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => _BoardCard(task: tasks[index], onUpdate: onRefresh),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onUpdate;

  const _BoardCard({required this.task, required this.onUpdate});

  Future<void> _moveTask(String newStatus) async {
    try {
      await GetIt.I<TasksRepository>().updateTaskStatus(task.id, newStatus);
      onUpdate();
    } catch (e) {
      // Error handled by repo or parent
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => TaskDetailsView(task: task),
          );
          onUpdate();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  _buildMoveMenu(),
                ],
              ),
              const SizedBox(height: 8),
              _buildPriorityBadge(),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11, height: 1.4),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}",
                          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (task.attachments.isNotEmpty)
                    Icon(Icons.attachment, size: 14, color: Colors.grey.withOpacity(0.5)),
                  const Spacer(),
                  _buildAvatarStack(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    final color = _getPriorityColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(
            task.priority.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.low: return Colors.blue;
      case TaskPriority.medium: return AppColors.primaryRed;
      case TaskPriority.high: return Colors.redAccent;
      case TaskPriority.critical: return Colors.purple;
    }
  }

  Widget _buildMoveMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      color: const Color(0xFF2C2C2C),
      onSelected: _moveTask,
      itemBuilder: (context) => [
        if (task.status != 'pending')
          const PopupMenuItem(value: 'pending', child: Text("Move to To Do", style: TextStyle(color: Colors.white, fontSize: 13))),
        if (task.status != 'in_progress')
          const PopupMenuItem(value: 'in_progress', child: Text("Move to In Progress", style: TextStyle(color: Colors.white, fontSize: 13))),
        if (task.status != 'completed')
          const PopupMenuItem(value: 'completed', child: Text("Move to Done", style: TextStyle(color: Colors.white, fontSize: 13))),
      ],
    );
  }

  Widget _buildAvatarStack() {
    if (task.collaborators.isEmpty) return const SizedBox();
    
    return SizedBox(
      height: 20,
      width: 48,
      child: Stack(
        children: List.generate(
          task.collaborators.length > 3 ? 3 : task.collaborators.length,
          (i) => Positioned(
            left: i * 12.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1C1C1C), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.primaryRed.withOpacity(0.2),
                child: Text(
                  (task.collaborators[i]['first_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(color: AppColors.primaryRed, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}