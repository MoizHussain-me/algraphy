import 'dart:convert';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final List<String> assignedTo; // List of employee_ids
  final bool isCompleted;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.assignedTo,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['created_by']?.toString() ?? '',
      assignedTo: map['assigned_to'] is List 
          ? List<String>.from(map['assigned_to'].map((x) => x.toString()))
          : (map['assigned_to'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      isCompleted: map['status'] == 'completed' || map['is_completed'] == 1 || map['is_completed'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'assigned_to': assignedTo.join(','),
      'is_completed': isCompleted ? 1 : 0,
      'status': isCompleted ? 'completed' : 'pending',
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    List<String>? assignedTo,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
