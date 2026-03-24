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
  
  String _leaveDuration = "Full Day";
  final List<String> _durations = ["Full Day", "Half Day"];

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
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

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showSnackbar("Please select both Start and End dates", const Color(0xFFDC2726));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        "leave_type": _leaveType,
        "leave_duration": _leaveDuration,
        "start_date": DateFormat('yyyy-MM-dd').format(_startDate!),
        "end_date": DateFormat('yyyy-MM-dd').format(_endDate!),
        "reason": _reasonCtrl.text.trim(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              DropdownButtonFormField<String>(
                value: _leaveDuration,
                dropdownColor: isDark ? const Color(0xFF2C2C2C) : theme.cardColor,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: _inputDecoration("Leave Duration", Icons.timelapse, theme),
                items: _durations.map((duration) => DropdownMenuItem(
                  value: duration,
                  child: Text(duration),
                )).toList(),
                onChanged: (val) => setState(() => _leaveDuration = val!),
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