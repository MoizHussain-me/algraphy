import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/core/theme/colors.dart';
import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:algraphy/modules/tasks/data/models/task_model.dart';
import 'package:algraphy/modules/tasks/data/repository/tasks_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class CreateTaskView extends StatefulWidget {
  const CreateTaskView({super.key});

  @override
  State<CreateTaskView> createState() => _CreateTaskViewState();
}

class _CreateTaskViewState extends State<CreateTaskView> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _selectedCollaborators = [];
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  bool _isLoadingEmployees = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final emps = await GetIt.I<EmployeeRepository>().getEmployeeList();
      if (mounted) {
        setState(() {
          _employees = emps;
          _isLoadingEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              surface: const Color(0xFF1C1C1C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final assignedTo = _selectedCollaborators.map((e) => e['employee_id'].toString()).toList();
      
      final data = {
        "title": _titleCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "assigned_to": assignedTo.join(','),
        "priority": _selectedPriority.name,
        "deadline": _selectedDueDate?.toIso8601String().split('T')[0],
        "status": 'active',
      };

      await GetIt.I<TasksRepository>().createTask(data);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTextField(_titleCtrl, "Task Title", Icons.title, true),
              const SizedBox(height: 16),
              _buildTextField(_descCtrl, "Description (Optional)", Icons.description, false, maxLines: 3),
              const SizedBox(height: 20),
              _buildPrioritySelector(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildDatePicker()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCollaboratorTrigger()),
                ],
              ),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 20),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "New Task",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, bool required, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: required ? (v) => v!.isEmpty ? "Required" : null : null,
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Priority", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: TaskPriority.values.map((p) {
            final isSelected = _selectedPriority == p;
            final color = _getPriorityColor(p);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPriority = p),
                child: Container(
                  margin: EdgeInsets.only(right: p == TaskPriority.critical ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? color : Colors.transparent),
                  ),
                  child: Center(
                    child: Text(
                      p.name.substring(0, 1).toUpperCase() + p.name.substring(1),
                      style: TextStyle(
                        color: isSelected ? color : Colors.grey,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDueDate == null ? "Due Date" : DateFormat('MMM dd').format(_selectedDueDate!),
                style: TextStyle(color: _selectedDueDate == null ? Colors.grey : Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaboratorTrigger() {
    return InkWell(
      onTap: _showCollaboratorPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_add_outlined, color: Colors.grey, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedCollaborators.isEmpty ? "Assign" : "${_selectedCollaborators.length} Joined",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _selectedCollaborators.isEmpty ? Colors.grey : Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Create Task", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low: return Colors.blue;
      case TaskPriority.medium: return AppColors.primaryRed;
      case TaskPriority.high: return Colors.redAccent;
      case TaskPriority.critical: return Colors.purple;
    }
  }

  void _showCollaboratorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return _CollaboratorPickerModal(
          employees: _employees,
          initialSelected: _selectedCollaborators,
          onSelectionChanged: (selected) {
            setState(() {
              _selectedCollaborators = selected;
            });
          },
        );
      },
    );
  }
}

class _CollaboratorPickerModal extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> initialSelected;
  final Function(List<Map<String, dynamic>>) onSelectionChanged;

  const _CollaboratorPickerModal({
    required this.employees,
    required this.initialSelected,
    required this.onSelectionChanged,
  });

  @override
  State<_CollaboratorPickerModal> createState() => _CollaboratorPickerModalState();
}

class _CollaboratorPickerModalState extends State<_CollaboratorPickerModal> {
  final _searchCtrl = TextEditingController();
  late List<Map<String, dynamic>> _filtered;
  late List<Map<String, dynamic>> _selected;

  @override
  void initState() {
    super.initState();
    _filtered = widget.employees;
    _selected = List.from(widget.initialSelected);
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
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
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
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final emp = _filtered[index];
                final id = emp['employee_id'].toString();
                final isSelected = _selected.any((e) => e['employee_id'].toString() == id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryRed.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2C2C2C),
                      child: Text(emp['first_name'][0], style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text("${emp['first_name']} ${emp['last_name']}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                    trailing: isSelected ? const Icon(Icons.check_box, color: AppColors.primaryRed) : null,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selected.removeWhere((e) => e['employee_id'].toString() == id);
                        } else {
                          _selected.add(emp);
                        }
                        widget.onSelectionChanged(_selected);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Confirm Selection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
