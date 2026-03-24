enum TaskPriority { low, medium, high, critical }

// ─────────────────────────────────────────────────────────────────────────────
// Subtask
// ─────────────────────────────────────────────────────────────────────────────
class Subtask {
  final String id;
  final String taskId;
  final String title;
  final String status; // pending, completed

  Subtask({required this.id, required this.taskId, required this.title, this.status = 'pending'});

  bool get isCompleted => status == 'completed';

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['subtask_id']?.toString() ?? '',
      taskId: map['task_id']?.toString() ?? '',
      title: map['title'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subtask_id': id,
      'task_id': taskId,
      'title': title,
      'status': status,
    };
  }

  Subtask copyWith({String? id, String? taskId, String? title, String? status}) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      status: status ?? this.status,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TaskAttachment
// ─────────────────────────────────────────────────────────────────────────────
class TaskAttachment {
  final String id;
  final String fileName;
  final String url;
  final DateTime uploadedAt;

  TaskAttachment({
    required this.id, 
    required this.fileName, 
    required this.url, 
    required this.uploadedAt,
  });

  factory TaskAttachment.fromMap(Map<String, dynamic> map) {
    return TaskAttachment(
      id: map['id']?.toString() ?? '',
      fileName: map['file_name'] ?? '',
      url: map['url'] ?? '',
      uploadedAt: DateTime.tryParse(map['uploaded_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_name': fileName,
      'url': url,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TaskModel
// ─────────────────────────────────────────────────────────────────────────────
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String? creatorName;
  final List<String> assignedTo;
  final List<Map<String, dynamic>> collaborators; // [{employee_id, first_name, last_name}]
  final String status;
  final DateTime? startDate;
  final DateTime? deadline;
  final TaskPriority priority;
  final List<Subtask> subtasks;
  final List<TaskAttachment> attachments;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    this.creatorName,
    required this.assignedTo,
    this.collaborators = const [],
    required this.status,
    this.startDate,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.subtasks = const [],
    this.attachments = const [],
  });

  bool get isCompleted => status == 'completed';

  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;

  double get progress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    return completedSubtasksCount / subtasks.length;
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['task_id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['created_by']?.toString() ?? '',
      creatorName: map['creator_name']?.toString(),
      assignedTo: map['assigned_to'] is List
          ? List<String>.from(map['assigned_to'].map((x) => x.toString()))
          : (map['assigned_to'] as String?)
                  ?.split(',')
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              [],
      collaborators: map['collaborators'] is List
          ? List<Map<String, dynamic>>.from(
              (map['collaborators'] as List).map((x) => Map<String, dynamic>.from(x)),
            )
          : [],
      status: map['status']?.toString() ?? 'pending',
      startDate: DateTime.tryParse(map['start_date'] ?? ''),
      deadline: DateTime.tryParse(map['deadline'] ?? ''),
      priority: _parsePriority(map['priority']),
      subtasks: map['subtasks'] is List
          ? (map['subtasks'] as List).map((x) => Subtask.fromMap(x)).toList()
          : [],
      attachments: map['attachments'] is List
          ? (map['attachments'] as List).map((x) => TaskAttachment.fromMap(x)).toList()
          : [],
    );
  }

  static TaskPriority _parsePriority(dynamic p) {
    if (p == null) return TaskPriority.medium;
    final s = p.toString().toLowerCase();
    if (s == 'low') return TaskPriority.low;
    if (s == 'high') return TaskPriority.high;
    if (s == 'critical') return TaskPriority.critical;
    return TaskPriority.medium;
  }

  Map<String, dynamic> toMap() {
    return {
      'task_id': id,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'creator_name': creatorName,
      'assigned_to': assignedTo.join(','),
      'collaborators': collaborators,
      'status': status,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'deadline': deadline?.toIso8601String().split('T')[0],
      'priority': priority.name,
      'subtasks': subtasks.map((x) => x.toMap()).toList(),
      'attachments': attachments.map((x) => x.toMap()).toList(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    List<String>? assignedTo,
    List<Map<String, dynamic>>? collaborators,
    String? status,
    DateTime? startDate,
    DateTime? deadline,
    TaskPriority? priority,
    List<Subtask>? subtasks,
    List<TaskAttachment>? attachments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      assignedTo: assignedTo ?? this.assignedTo,
      collaborators: collaborators ?? this.collaborators,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      subtasks: subtasks ?? this.subtasks,
      attachments: attachments ?? this.attachments,
    );
  }
}
