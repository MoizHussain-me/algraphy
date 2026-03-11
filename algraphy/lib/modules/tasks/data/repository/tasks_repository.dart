import 'package:algraphy/core/api/api_client.dart';
import 'package:algraphy/core/services/session_service.dart';
import 'package:algraphy/modules/tasks/data/models/task_model.dart';

class TasksRepository {
  final ApiClient _api = ApiClient();

  Future<List<TaskModel>> getTasks() async {
    final token = await SessionService.getToken();
    final response = await _api.get('get_tasks', token: token);
    
    if (response['status'] == 'success') {
      return (response['data'] as List).map((x) => TaskModel.fromMap(x)).toList();
    }
    return [];
  }

  Future<void> createTask(Map<String, dynamic> taskData) async {
    final token = await SessionService.getToken();
    final response = await _api.post('create_task', taskData, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to create task');
    }
  }

  Future<void> toggleTaskStatus(String taskId, bool isCompleted) async {
    final token = await SessionService.getToken();
    final response = await _api.post('update_task_status', {
      'task_id': taskId,
      'status': isCompleted ? 'completed' : 'pending',
    }, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to update task');
    }
  }
}
