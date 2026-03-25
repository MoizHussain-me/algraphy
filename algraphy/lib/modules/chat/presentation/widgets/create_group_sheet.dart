import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../employee/data/employee_repository.dart';
import '../../../../config/di/injector.dart';
import '../../data/repositories/chat_repository.dart';

class CreateGroupSheet extends StatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final EmployeeRepository _employeeRepository = getIt<EmployeeRepository>();
  final ChatRepository _chatRepository = getIt<ChatRepository>();
  final TextEditingController _groupNameController = TextEditingController();
  
  List<Map<String, dynamic>> _employees = [];
  final Set<int> _selectedUserIds = {};
  bool _isLoading = true;
  bool _isCreating = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _employeeRepository.getEmployeeList();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter group name')));
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one member')));
      return;
    }

    setState(() => _isCreating = true);
    try {
      final roomId = await _chatRepository.createGroup(name, _selectedUserIds.toList());
      if (mounted) {
        Navigator.pop(context, {'roomId': roomId, 'name': name});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _employees.where((emp) {
      final name = "${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}".toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Group Name',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          _buildSearchField(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];
                      final id = int.tryParse(emp['user_id']?.toString() ?? '0') ?? 0;
                      if (id == 0) return const SizedBox.shrink();
                      final isSelected = _selectedUserIds.contains(id);
                      return _buildUserTile(emp, id, isSelected);
                    },
                  ),
          ),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Create New Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search members...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> emp, int id, bool isSelected) {
    final String fullName = "${emp['first_name'] ?? 'Unknown'} ${emp['last_name'] ?? ''}".trim();
    return CheckboxListTile(
      value: isSelected,
      onChanged: (val) {
        setState(() {
          if (val == true) _selectedUserIds.add(id);
          else _selectedUserIds.remove(id);
        });
      },
      title: Text(fullName),
      subtitle: Text(emp['designation'] ?? 'Employee'),
      secondary: CircleAvatar(
        backgroundImage: ImageHelper.getProvider(emp['profile_picture']),
        child: emp['profile_picture'] == null ? Text(fullName[0].toUpperCase()) : null,
      ),
      activeColor: AppColors.primaryRed,
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createGroup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangle4(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isCreating 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Create Group', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class RoundedRectangle4 extends RoundedRectangleBorder {
  const RoundedRectangle4({super.borderRadius});
}
