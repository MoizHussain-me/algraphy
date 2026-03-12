import 'package:flutter/material.dart';
import '../views/create_task_view.dart';
import '../views/tasks_view.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  Key _tasksViewKey = UniqueKey();

  Future<void> _openCreateTask() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateTaskView(),
    );
    if (result == true) {
      setState(() {
        _tasksViewKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTask,
        backgroundColor: const Color(0xFFDC2726),
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text(
          'Create Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: TasksView(key: _tasksViewKey),
    );
  }
}
