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

  Future<void> updateTask(TaskModel task) async {
    final token = await SessionService.getToken();
    final response = await _api.post('update_task', task.toMap(), token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to update task');
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    final token = await SessionService.getToken();
    final response = await _api.post('update_task_status', {
      'task_id': taskId,
      'status': status,
    }, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to update task status');
    }
  }

  Future<void> createSubtask(String taskId, String title) async {
    final token = await SessionService.getToken();
    final response = await _api.post('create_subtask', {
      'task_id': taskId,
      'title': title,
    }, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to create subtask');
    }
  }

  Future<void> toggleSubtaskStatus(String subtaskId, bool isCompleted) async {
    final token = await SessionService.getToken();
    final response = await _api.post('update_subtask_status', {
      'subtask_id': subtaskId,
      'status': isCompleted ? 'completed' : 'pending',
    }, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to update subtask');
    }
  }

  Future<void> addComment(String taskId, String content, {String? subtaskId}) async {
    final token = await SessionService.getToken();
    final response = await _api.post('add_task_comment', {
      'task_id': taskId,
      'subtask_id': subtaskId,
      'content': content,
    }, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to add comment');
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String taskId) async {
    final token = await SessionService.getToken();
    final response = await _api.get('get_task_comments&task_id=$taskId', token: token);
    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    return [];
  }

  Future<void> addCollaborator(String taskId, String employeeId) async {
    final token = await SessionService.getToken();
    final response = await _api.post('add_collaborator', {
      'task_id': taskId,
      'employee_id': employeeId,
    }, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to add collaborator');
    }
  }

  Future<void> removeCollaborator(String taskId, String employeeId) async {
    final token = await SessionService.getToken();
    final response = await _api.post('remove_collaborator', {
      'task_id': taskId,
      'employee_id': employeeId,
    }, token: token);
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to remove collaborator');
    }
  }

  Future<void> uploadAttachment(String taskId, {String? filePath, List<int>? bytes, String? fileName}) async {
    final token = await SessionService.getToken();
    final response = await _api.postMultipart(
      'upload_attachment',
      {'task_id': taskId},
      filePaths: filePath != null ? {'file': filePath} : null,
      fileBytes: bytes != null ? {'file': bytes} : null,
      fileNames: fileName != null ? {'file': fileName} : null,
      token: token,
    );
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to upload attachment');
    }
  }

  Future<void> removeAttachment(String attachmentId) async {
    final token = await SessionService.getToken();
    final response = await _api.post(
      'remove_attachment',
      {'attachment_id': attachmentId},
      token: token,
    );
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Failed to remove attachment');
    }
  }
}
