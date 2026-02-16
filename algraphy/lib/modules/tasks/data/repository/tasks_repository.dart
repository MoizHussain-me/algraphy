import 'package:algraphy/core/api/api_client.dart';
import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/modules/tasks/data/models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasksRepository {
  final ApiClient _api = ApiClient();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<List<TaskModel>> getTasks() async {
    final token = await _getToken();
    final response = await _api.get('get_tasks', token: token);
    
    if (response['status'] == 'success') {
      return (response['data'] as List).map((x) => TaskModel.fromMap(x)).toList();
    }
    return [];
  }

  Future<void> createTask(Map<String, dynamic> taskData) async {
    final token = await _getToken();
    final response = await _api.post('create_task', taskData, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to create task');
    }
  }

  Future<void> toggleTaskStatus(String taskId, bool isCompleted) async {
    final token = await _getToken();
    final response = await _api.post('update_task_status', {
      'task_id': taskId,
      'status': isCompleted ? 'completed' : 'pending',
    }, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to update task');
    }
  }
}
