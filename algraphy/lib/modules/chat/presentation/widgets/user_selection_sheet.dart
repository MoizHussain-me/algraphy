import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../employee/data/employee_repository.dart';
import '../../../../config/di/injector.dart';

class UserSelectionSheet extends StatefulWidget {
  const UserSelectionSheet({super.key});

  @override
  State<UserSelectionSheet> createState() => _UserSelectionSheetState();
}

class _UserSelectionSheetState extends State<UserSelectionSheet> {
  final EmployeeRepository _employeeRepository = getIt<EmployeeRepository>();
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        Navigator.pop(context);
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
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchField(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];
                      return _buildUserTile(emp);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'New Conversation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
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
          hintText: 'Search employees...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> emp) {
    final String fullName = "${emp['first_name'] ?? 'Unknown'} ${emp['last_name'] ?? ''}".trim();
    final String? profilePic = emp['profile_picture'];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
        backgroundImage: ImageHelper.getProvider(profilePic),
        child: profilePic == null 
            ? Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U') 
            : null,
      ),
      title: Text(fullName),
      subtitle: Text(emp['designation'] ?? 'Employee'),
      onTap: () {
        Navigator.pop(context, emp);
      },
    );
  }
}
