import 'package:algraphy/modules/tasks/data/models/task_model.dart';
import 'package:algraphy/modules/tasks/data/repository/tasks_repository.dart';
import 'package:algraphy/modules/tasks/presentation/views/tasks_board_view.dart';
import 'package:algraphy/modules/tasks/presentation/views/task_details_view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> with SingleTickerProviderStateMixin {
  final TasksRepository _repo = GetIt.I<TasksRepository>();
  late TabController _tabController;
  List<TaskModel> _allTasks = [];
  bool _isLoading = true;
  bool _isBoardView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      final tasks = await _repo.getTasks();
      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<TaskModel> _filterTasks(int index) {
    switch (index) {
      case 0: // All
        return _allTasks;
      case 1: // My Tasks (Assumed - logic would need current user ID)
        return _allTasks; 
      case 2: // Pending
        return _allTasks.where((t) => !t.isCompleted).toList();
      case 3: // Completed
        return _allTasks.where((t) => t.isCompleted).toList();
      default:
        return _allTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        _buildTabBar(),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2726)))
            : TabBarView(
                controller: _tabController,
                children: List.generate(4, (index) {
                  final tasks = _filterTasks(index);
                  return _isBoardView 
                    ? TasksBoardView(tasks: tasks, onRefresh: _fetchTasks)
                    : _TaskList(tasks: tasks, onRefresh: _fetchTasks);
                }),
              ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text("Tasks", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _isBoardView = false),
                  icon: Icon(Icons.list, color: !_isBoardView ? const Color(0xFFDC2726) : Colors.grey),
                ),
                Container(width: 1, height: 20, color: Colors.white10),
                IconButton(
                  onPressed: () => setState(() => _isBoardView = true),
                  icon: Icon(Icons.grid_view, color: _isBoardView ? const Color(0xFFDC2726) : Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFDC2726),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "All"),
          Tab(text: "My"),
          Tab(text: "Active"),
          Tab(text: "Done"),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final Future<void> Function() onRefresh;

  const _TaskList({required this.tasks, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text("No tasks found", style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFDC2726),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) => _TaskCard(task: tasks[index], onUpdate: onRefresh),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onUpdate;

  const _TaskCard({required this.task, required this.onUpdate});

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.low: return Colors.blue;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.high: return Colors.redAccent;
      case TaskPriority.critical: return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C1C1C),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PriorityBadge(priority: task.priority, color: _getPriorityColor()),
                const Spacer(),
                if (task.deadline != null)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: task.deadline!.isBefore(DateTime.now()) && !task.isCompleted ? Colors.redAccent : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd').format(task.deadline!),
                          style: TextStyle(
                            color: task.deadline!.isBefore(DateTime.now()) && !task.isCompleted ? Colors.redAccent : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    await GetIt.I<TasksRepository>().updateTaskStatus(task.id, !task.isCompleted ? 'completed' : 'pending');
                    onUpdate();
                  },
                  child: Icon(
                    task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: task.isCompleted ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${task.assignedTo.length} Assigned",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final Color color;
  const _PriorityBadge({required this.priority, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
