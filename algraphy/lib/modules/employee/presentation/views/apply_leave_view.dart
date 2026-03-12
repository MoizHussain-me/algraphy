import 'package:algraphy/core/utils/constants.dart';
import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class ApplyLeaveView extends StatefulWidget {
  const ApplyLeaveView({super.key});

  @override
  State<ApplyLeaveView> createState() => _ApplyLeaveViewState();
}

class _ApplyLeaveViewState extends State<ApplyLeaveView> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  
  String _leaveType = "Casual Leave";
  final List<String> _leaveTypes = ["Casual Leave", "Sick Leave", "Privilege Leave", "Emergency"];
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _selectedTo;
  List<Map<String, dynamic>> _selectedCC = [];
  bool _isLoadingEmployees = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
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
      if (mounted) {
        setState(() => _isLoadingEmployees = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading employees: $e")));
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: isDark 
              ? theme.colorScheme.copyWith(
                  primary: const Color(0xFFDC2726),
                  surface: const Color(0xFF1C1C1C),
                )
              : theme.colorScheme.copyWith(
                  primary: const Color(0xFFDC2726),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showEmployeePicker(bool isTo) {
    if (_employees.isEmpty && !_isLoadingEmployees) {
      _loadEmployees();
    }
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return _EmployeePickerModal(
          isTo: isTo,
          employees: _employees,
          initialSelectedTo: _selectedTo,
          initialSelectedCC: _selectedCC,
          onSelectionChanged: (to, cc) {
            setState(() {
              if (isTo) {
                _selectedTo = to;
              } else {
                _selectedCC = cc;
              }
            });
          },
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showSnackbar("Please select both Start and End dates", Colors.orange);
      return;
    }

    if (_selectedTo == null) {
      _showSnackbar("Please select a recipient (To)", Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ccIds = _selectedCC.map((e) => e['employee_id'].toString()).join(',');
      
      final data = {
        "leave_type": _leaveType,
        "start_date": DateFormat('yyyy-MM-dd').format(_startDate!),
        "end_date": DateFormat('yyyy-MM-dd').format(_endDate!),
        "reason": _reasonCtrl.text.trim(),
        "to_employee_id": _selectedTo!['employee_id'],
        "cc_employee_ids": ccIds,
      };

      await GetIt.I<EmployeeRepository>().applyLeave(data);

      if (mounted) {
        _showSnackbar("Leave Requested Successfully", Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnackbar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Apply for Leave"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoadingEmployees 
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Recipients", theme),
              const SizedBox(height: 16),

              _buildPickerField(
                label: "To",
                icon: Icons.person,
                value: _selectedTo == null ? "Select Recipient" : "${_selectedTo!['first_name']} ${_selectedTo!['last_name']}",
                onTap: () => _showEmployeePicker(true),
                theme: theme,
              ),
              const SizedBox(height: 16),

              _buildPickerField(
                label: "CC",
                icon: Icons.people,
                value: _selectedCC.isEmpty ? "Select Employees (Optional)" : "${_selectedCC.length} selected",
                onTap: () => _showEmployeePicker(false),
                theme: theme,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("Leave Details", theme),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _leaveType,
                dropdownColor: isDark ? const Color(0xFF2C2C2C) : theme.cardColor,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: _inputDecoration("Leave Type", Icons.category, theme),
                items: _leaveTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (val) => setState(() => _leaveType = val!),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildPickerField(
                      label: "Start Date",
                      icon: Icons.calendar_today,
                      value: _startDate == null ? "Select" : DateFormat('MMM dd, yyyy').format(_startDate!),
                      onTap: () => _pickDate(true),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPickerField(
                      label: "End Date",
                      icon: Icons.event,
                      value: _endDate == null ? "Select" : DateFormat('MMM dd, yyyy').format(_endDate!),
                      onTap: () => _pickDate(false),
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("Reason", theme),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 4,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: _inputDecoration("Description", Icons.description, theme).copyWith(
                  alignLabelWithHint: true,
                ),
                validator: (val) => val!.isEmpty ? "Reason is required" : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2726),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Submit Request", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerField({required String label, required IconData icon, required String value, required VoidCallback onTap, required ThemeData theme}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(label, icon, theme),
        child: Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2C) : theme.cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDark ? BorderSide.none : BorderSide(color: theme.dividerColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDark ? BorderSide.none : BorderSide(color: theme.dividerColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2726))),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold));
  }
}

class _EmployeePickerModal extends StatefulWidget {
  final bool isTo;
  final List<Map<String, dynamic>> employees;
  final Map<String, dynamic>? initialSelectedTo;
  final List<Map<String, dynamic>> initialSelectedCC;
  final Function(Map<String, dynamic>?, List<Map<String, dynamic>>) onSelectionChanged;

  const _EmployeePickerModal({
    required this.isTo,
    required this.employees,
    required this.initialSelectedTo,
    required this.initialSelectedCC,
    required this.onSelectionChanged,
  });

  @override
  State<_EmployeePickerModal> createState() => _EmployeePickerModalState();
}

class _EmployeePickerModalState extends State<_EmployeePickerModal> {
  final _searchCtrl = TextEditingController();
  late List<Map<String, dynamic>> _filtered;
  Map<String, dynamic>? _selectedTo;
  late List<Map<String, dynamic>> _selectedCC;

  @override
  void initState() {
    super.initState();
    _filtered = widget.employees;
    _selectedTo = widget.initialSelectedTo;
    _selectedCC = List.from(widget.initialSelectedCC);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = widget.employees.where((e) {
        final fName = (e['first_name'] ?? "").toString().toLowerCase();
        final lName = (e['last_name'] ?? "").toString().toLowerCase();
        return fName.contains(q) || lName.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseUrl = AppConstants.apiBaseUrl.replaceAll('routes/api.php', '');
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[isDark ? 700 : 300], borderRadius: BorderRadius.circular(2)),
            ),
            Text(
              widget.isTo ? "Select Recipient (To)" : "Select CC Employees",
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: "Search by name...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchCtrl.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchCtrl.clear(); _filter(""); })
                  : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDark ? BorderSide.none : BorderSide(color: theme.dividerColor)),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text("No employees found", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final emp = _filtered[index];
                        final empId = emp['employee_id'].toString();
                        
                        final bool isSelected = widget.isTo 
                          ? (_selectedTo != null && _selectedTo!['employee_id'].toString() == empId)
                          : _selectedCC.any((e) => e['employee_id'].toString() == empId);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFDC2726),
                            backgroundImage: (emp['profile_picture'] != null && emp['profile_picture'].toString().isNotEmpty && emp['profile_picture'] != "null")
                              ? NetworkImage("$baseUrl${emp['profile_picture']}") 
                              : null,
                            child: (emp['profile_picture'] == null || emp['profile_picture'] == "null" || emp['profile_picture'].toString().isEmpty)
                              ? Text(
                                  emp['first_name'] != null && emp['first_name'].toString().isNotEmpty ? emp['first_name'].toString()[0].toUpperCase() : "?",
                                  style: const TextStyle(color: Colors.white)
                                ) 
                              : null,
                          ),
                          title: Text("${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFDC2726)) : null,
                          onTap: () {
                            setState(() {
                              if (widget.isTo) {
                                _selectedTo = emp;
                                widget.onSelectionChanged(_selectedTo, _selectedCC);
                                Navigator.pop(context);
                              } else {
                                if (isSelected) {
                                  _selectedCC.removeWhere((e) => e['employee_id'].toString() == empId);
                                } else {
                                  _selectedCC.add(emp);
                                }
                                widget.onSelectionChanged(_selectedTo, _selectedCC);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            if (!widget.isTo)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2726),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}