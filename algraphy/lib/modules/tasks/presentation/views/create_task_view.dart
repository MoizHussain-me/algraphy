import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:algraphy/modules/tasks/data/repository/tasks_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final assignedTo = _selectedCollaborators.map((e) => e['employee_id'].toString()).toList();
      
      final data = {
        "title": _titleCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "assigned_to": assignedTo.join(','),
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create New Task",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Task Title", Icons.title),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Description (Optional)", Icons.description),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showCollaboratorPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_add, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCollaborators.isEmpty
                            ? "Add Collaborators"
                            : "${_selectedCollaborators.length} collaborators added",
                        style: TextStyle(color: _selectedCollaborators.isEmpty ? Colors.grey : Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2726),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            // Padding for keyboard
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Search employees...",
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final emp = _filtered[index];
                final id = emp['employee_id'].toString();
                final isSelected = _selected.any((e) => e['employee_id'].toString() == id);

                return ListTile(
                  title: Text("${emp['first_name']} ${emp['last_name']}", style: const TextStyle(color: Colors.white)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFDC2726)) : null,
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
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2726)),
              child: const Text("Done", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
