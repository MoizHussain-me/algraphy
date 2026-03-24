import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:algraphy/modules/tasks/data/models/task_model.dart';
import 'package:algraphy/modules/tasks/data/repository/tasks_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/core/theme/colors.dart';

class TaskDetailsView extends StatefulWidget {
  final TaskModel task;
  const TaskDetailsView({super.key, required this.task});

  @override
  State<TaskDetailsView> createState() => _TaskDetailsViewState();
}

class _TaskDetailsViewState extends State<TaskDetailsView> {
  late TaskModel _task;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _fetchComments();
  }

  Future<void> _toggleStatus() async {
    setState(() => _isUpdating = true);
    try {
      final newStatus = !_task.isCompleted ? 'completed' : 'pending';
      await GetIt.I<TasksRepository>().updateTaskStatus(_task.id, newStatus);
      setState(() {
        _task = _task.copyWith(status: newStatus);
        _isUpdating = false;
      });
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTitleAndDesc(),
                  const SizedBox(height: 32),
                  _buildDetailsGrid(),
                  const SizedBox(height: 32),
                  _buildSubtasksSection(),
                  const SizedBox(height: 32),
                  _buildCollaboratorsSection(),
                  const SizedBox(height: 32),
                  _buildAttachmentsSection(),
                  const SizedBox(height: 32),
                  _buildActivitySection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _PriorityBadge(priority: _task.priority),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.grey),
          style: IconButton.styleFrom(backgroundColor: const Color(0xFF1C1C1C)),
        ),
      ],
    );
  }

  Widget _buildTitleAndDesc() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _task.title,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          _task.description.isEmpty ? "No description provided." : _task.description,
          style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today,
            label: "Due Date",
            value: _task.deadline != null ? DateFormat('MMMM dd, yyyy').format(_task.deadline!) : "Not set",
            valueColor: _task.deadline != null && _task.deadline!.isBefore(DateTime.now()) && !_task.isCompleted ? Colors.redAccent : Colors.white,
          ),
          const Divider(color: Colors.white10, height: 32),
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: Colors.grey, size: 20),
              const SizedBox(width: 16),
              const Text("Status", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const Spacer(),
              Theme(
                data: Theme.of(context).copyWith(canvasColor: const Color(0xFF1C1C1C)),
                child: DropdownButton<String>(
                  value: _task.status,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF1C1C1C),
                    style: TextStyle(
                      color: _task.status == 'completed' ? Colors.green : (_task.status == 'in_progress' ? Colors.blue : AppColors.primaryRed),
                      fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text("PENDING")),
                    DropdownMenuItem(value: 'in_progress', child: Text("IN PROGRESS")),
                    DropdownMenuItem(value: 'completed', child: Text("COMPLETED")),
                  ],
                  onChanged: (val) {
                    if (val != null) _updateStatus(val);
                  },
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          Row(
            children: [
              const Icon(Icons.priority_high, color: Colors.grey, size: 20),
              const SizedBox(width: 16),
              const Text("Priority", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const Spacer(),
              Theme(
                data: Theme.of(context).copyWith(canvasColor: const Color(0xFF1C1C1C)),
                child: DropdownButton<TaskPriority>(
                  value: _task.priority,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF1C1C1C),
                  style: TextStyle(
                    color: _getPriorityColor(_task.priority),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  items: TaskPriority.values.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name.toUpperCase()),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) _updatePriority(val);
                  },
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          _DetailRow(
            icon: Icons.person_outline,
            label: "Created By",
            value: _task.creatorName ?? "Unknown",
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksSection() {
    final completedCount = _task.subtasks.where((s) => s.isCompleted).length;
    final totalCount = _task.subtasks.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Subtasks", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              "$completedCount/$totalCount",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (totalCount > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              minHeight: 4,
            ),
          ),
        const SizedBox(height: 16),
        ..._task.subtasks.map((s) => _SubtaskTile(
          subtask: s,
          onToggle: () => _toggleSubtask(s),
        )),
        _AddSubtaskInput(onAdd: _addSubtask),
      ],
    );
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    final updatedSubtasks = _task.subtasks.map((s) {
      if (s.id == subtask.id) {
        return s.copyWith(status: !s.isCompleted ? 'completed' : 'pending');
      }
      return s;
    }).toList();
    
    final updatedTask = _task.copyWith(subtasks: updatedSubtasks.cast<Subtask>());
    
    setState(() => _task = updatedTask);
    
    try {
      await GetIt.I<TasksRepository>().toggleSubtaskStatus(subtask.id, !subtask.isCompleted);
    } catch (e) {
      // Revert on error
      setState(() => _task = widget.task);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _addSubtask(String title) async {
    final newSubtask = Subtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: _task.id,
      title: title,
    );
    
    final updatedSubtasks = [..._task.subtasks, newSubtask];
    final updatedTask = _task.copyWith(subtasks: updatedSubtasks.cast<Subtask>());
    
    setState(() => _task = updatedTask);
    
    try {
      await GetIt.I<TasksRepository>().createSubtask(_task.id, title);
    } catch (e) {
      setState(() => _task = widget.task);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildCollaboratorsSection() {
    final collabs = _task.collaborators.isNotEmpty
        ? _task.collaborators
        : _task.assignedTo.map((id) => {'employee_id': id, 'first_name': 'Emp', 'last_name': '#$id'}).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Assigned To (${collabs.length})",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _showAddCollaboratorPicker,
              icon: const Icon(Icons.person_add_alt_1, color: AppColors.primaryRed, size: 16),
              label: const Text("Add People", style: TextStyle(color: AppColors.primaryRed, fontSize: 13)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (collabs.isEmpty)
          const Text("No one assigned yet", style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: collabs.map((collab) {
              final empId = collab['employee_id']?.toString() ?? '';
              final firstName = collab['first_name'] ?? '';
              final lastName = collab['last_name'] ?? '';
              final displayName = '$firstName $lastName'.trim();
              final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryRed.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: AppColors.primaryRed.withOpacity(0.2),
                      child: Text(
                        initial,
                        style: const TextStyle(color: AppColors.primaryRed, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      displayName.isEmpty ? 'Emp #$empId' : displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 7),
                    GestureDetector(
                      onTap: () => _removeCollaborator(empId, collab),
                      child: const Icon(Icons.close, color: Colors.grey, size: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _showAddCollaboratorPicker() async {
    try {
      final employees = await GetIt.I<EmployeeRepository>().getEmployeeList();
      if (!mounted) return;

      final currentIds = _task.assignedTo.toSet();
      final available = employees.where((e) => !currentIds.contains(e['employee_id'].toString())).toList();

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1C1C1C),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => _CollaboratorAdderSheet(
          employees: available,
          onAdd: (emp) async {
            final empId = emp['employee_id'].toString();
            try {
              await GetIt.I<TasksRepository>().addCollaborator(_task.id, empId);
              final newCollab = {
                'employee_id': empId,
                'first_name': emp['first_name'] ?? '',
                'last_name': emp['last_name'] ?? '',
              };
              setState(() {
                _task = _task.copyWith(
                  assignedTo: [..._task.assignedTo, empId],
                  collaborators: [..._task.collaborators, newCollab],
                );
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${emp['first_name']} added to task"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load employees: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeCollaborator(String empId, Map<String, dynamic> collab) async {
    try {
      await GetIt.I<TasksRepository>().removeCollaborator(_task.id, empId);
      setState(() {
        _task = _task.copyWith(
          assignedTo: _task.assignedTo.where((id) => id != empId).toList(),
          collaborators: _task.collaborators.where((c) => c['employee_id'].toString() != empId).toList(),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to remove: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Attachments", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: _pickFile,
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryRed, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_task.attachments.isEmpty)
          const Text("No attachments yet", style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _task.attachments.length,
            itemBuilder: (context, index) {
              final att = _task.attachments[index];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openFile(att.url),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(att.fileName),
                            color: _getFileColor(att.fileName),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              att.fileName,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _removeAttachment(att.id),
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png': return Icons.image;
      case 'doc':
      case 'docx': return Icons.description;
      case 'xls':
      case 'xlsx': return Icons.table_chart;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png': return Colors.green;
      case 'doc':
      case 'docx': return Colors.blue;
      case 'xls':
      case 'xlsx': return Colors.teal;
      default: return Colors.blueGrey;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null) {
        final platformFile = result.files.single;
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Uploading attachment..."), duration: Duration(seconds: 1)),
          );
        }

        await GetIt.I<TasksRepository>().uploadAttachment(
          _task.id, 
          filePath: platformFile.path,
          bytes: platformFile.bytes,
          fileName: platformFile.name,
        );
        
        // After upload, we should refresh the task list or add it locally.
        // For simplicity, let's just show a success message and tell the user to refresh.
        // Ideally we'd fetch the tasks again.
        final tasks = await GetIt.I<TasksRepository>().getTasks();
        final updatedTask = tasks.firstWhere((t) => t.id == _task.id);

        if (mounted) {
          setState(() {
            _task = updatedTask;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Attachment uploaded successfully"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeAttachment(String id) async {
    try {
      // Show confirmation dialog? For now just remove
      await GetIt.I<TasksRepository>().removeAttachment(id.toString());
      
      if (mounted) {
        setState(() {
          _task.attachments.removeWhere((a) => a.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attachment removed"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to remove attachment: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openFile(String url) async {
    // Determine full URL
    String fullUrl = url;
    if (!url.startsWith('http')) {
      fullUrl = "${AppConstants.rootUrl}$url";
    }

    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open file"), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  final _commentCtrl = TextEditingController();

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await GetIt.I<TasksRepository>().getComments(_task.id);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();

    try {
      await GetIt.I<TasksRepository>().addComment(_task.id, content);
      _fetchComments(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await GetIt.I<TasksRepository>().updateTaskStatus(_task.id, newStatus);
      setState(() {
        _task = _task.copyWith(status: newStatus);
        _isUpdating = false;
      });
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
  
  Future<void> _updatePriority(TaskPriority newPriority) async {
    setState(() => _isUpdating = true);
    try {
      await GetIt.I<TasksRepository>().updateTaskPriority(_task.id, newPriority.name);
      setState(() {
        _task = _task.copyWith(priority: newPriority);
        _isUpdating = false;
      });
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Activity", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (_isLoadingComments)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: AppColors.primaryRed, strokeWidth: 2)))
        else if (_comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text("No activity yet", style: TextStyle(color: Colors.grey, fontSize: 13))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final c = _comments[index];
              final name = "${c['first_name']} ${c['last_name']}";
              final initial = c['first_name']?[0]?.toUpperCase() ?? '?';
              final time = DateTime.tryParse(c['created_at'] ?? '');
              final timeStr = time != null ? DateFormat('MMM dd, hh:mm a').format(time) : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                      child: Text(initial, style: const TextStyle(color: AppColors.primaryRed, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(c['content'] ?? '', style: TextStyle(color: Colors.grey[300], fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Add a comment...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (_) => _addComment(),
            ),
          ),
          IconButton(
            onPressed: _addComment,
            icon: const Icon(Icons.send_rounded, color: AppColors.primaryRed, size: 20),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return AppColors.primaryRed;
      case TaskPriority.high:
        return Colors.redAccent;
      case TaskPriority.critical:
        return Colors.purple;
    }
  }
}

class _SubtaskTile extends StatelessWidget {
  final Subtask subtask;
  final VoidCallback onToggle;

  const _SubtaskTile({required this.subtask, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(
                subtask.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                color: subtask.isCompleted ? AppColors.primaryRed : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subtask.title,
                  style: TextStyle(
                    color: subtask.isCompleted ? Colors.grey : Colors.white,
                    fontSize: 14,
                    decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                    decorationThickness: subtask.isCompleted ? 2.5 : null,
                    decorationColor: subtask.isCompleted ? AppColors.primaryRed : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSubtaskInput extends StatefulWidget {
  final Function(String) onAdd;
  const _AddSubtaskInput({required this.onAdd});

  @override
  State<_AddSubtaskInput> createState() => _AddSubtaskInputState();
}

class _AddSubtaskInputState extends State<_AddSubtaskInput> {
  final _ctrl = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return TextButton.icon(
        onPressed: () => setState(() => _isEditing = true),
        icon: const Icon(Icons.add, size: 18, color: AppColors.primaryRed),
        label: const Text("Add a subtask", style: TextStyle(color: AppColors.primaryRed, fontSize: 13)),
        style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: "What needs to be done?",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: AppColors.primaryRed, size: 18),
            onPressed: () {
              if (_ctrl.text.trim().isNotEmpty) {
                widget.onAdd(_ctrl.text.trim());
                _ctrl.clear();
                setState(() => _isEditing = false);
              }
            },
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) {
            widget.onAdd(v.trim());
            _ctrl.clear();
            setState(() => _isEditing = false);
          }
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadge({required this.priority});

  Color _getColor() {
    switch (priority) {
      case TaskPriority.low: return Colors.blue;
      case TaskPriority.medium: return AppColors.primaryRed;
      case TaskPriority.high: return Colors.redAccent;
      case TaskPriority.critical: return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            priority.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collaborator Adder Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CollaboratorAdderSheet extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  final Function(Map<String, dynamic>) onAdd;

  const _CollaboratorAdderSheet({required this.employees, required this.onAdd});

  @override
  State<_CollaboratorAdderSheet> createState() => _CollaboratorAdderSheetState();
}

class _CollaboratorAdderSheetState extends State<_CollaboratorAdderSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.employees;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      _filtered = widget.employees.where((e) {
        final name = "${e['first_name']} ${e['last_name']}".toLowerCase();
        return name.contains(q.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text("Add People to Task", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search colleagues...",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filtered.isEmpty
              ? const Center(child: Text("No employees available", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final emp = _filtered[index];
                    final firstName = emp['first_name'] ?? '';
                    final lastName = emp['last_name'] ?? '';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFDC2726).withOpacity(0.15),
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Color(0xFFDC2726), fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text("$firstName $lastName", style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(emp['designation'] ?? emp['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: ElevatedButton(
                        onPressed: () {
                          widget.onAdd(emp);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2726),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text("Add", style: TextStyle(fontSize: 12)),
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
