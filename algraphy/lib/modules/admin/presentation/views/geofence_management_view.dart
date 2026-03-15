import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:algraphy/modules/admin/data/repositories/admin_data_repository.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';

class GeofenceManagementView extends StatefulWidget {
  const GeofenceManagementView({super.key});

  @override
  State<GeofenceManagementView> createState() => _GeofenceManagementViewState();
}

class _GeofenceManagementViewState extends State<GeofenceManagementView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _offices = [];
  List<UserModel> _allEmployees = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = GetIt.I<AdminRepository>();
      final results = await Future.wait([
        repo.getOffices(),
        repo.getAllEmployees(),
      ]);
      setState(() {
        _offices = results[0] as List<Map<String, dynamic>>;
        _allEmployees = results[1] as List<UserModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  void _showOfficeDialog([Map<String, dynamic>? office]) {
    final nameController = TextEditingController(text: office?['name']?.toString() ?? '');
    final latController = TextEditingController(text: office?['latitude']?.toString() ?? '');
    final lngController = TextEditingController(text: office?['longitude']?.toString() ?? '');
    final radiusController = TextEditingController(text: office?['radius']?.toString() ?? '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(office == null ? "Add Office Location" : "Edit Office Location"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Office Name", prefixIcon: Icon(Icons.business))),
              TextField(controller: latController, decoration: const InputDecoration(labelText: "Latitude", prefixIcon: Icon(Icons.location_on)), keyboardType: TextInputType.number),
              TextField(controller: lngController, decoration: const InputDecoration(labelText: "Longitude", prefixIcon: Icon(Icons.location_on)), keyboardType: TextInputType.number),
              TextField(controller: radiusController, decoration: const InputDecoration(labelText: "Radius (Meters)", prefixIcon: Icon(Icons.radar)), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final data = {
                if (office != null) 'id': office['id'],
                'name': nameController.text,
                'latitude': double.tryParse(latController.text) ?? 0,
                'longitude': double.tryParse(lngController.text) ?? 0,
                'radius': double.tryParse(radiusController.text) ?? 100,
              };
              try {
                await GetIt.I<AdminRepository>().saveOffice(data);
                if (mounted) Navigator.pop(context);
                
                // If it was a new office, ask if they want to assign employees now
                if (office == null && mounted) {
                  _loadData().then((_) {
                    final newOffice = _offices.firstWhere((o) => o['name'] == data['name'], orElse: () => {});
                    if (newOffice.isNotEmpty) {
                      _showAssignmentSheet(newOffice);
                    }
                  });
                } else {
                  _loadData();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }, 
            child: const Text("Save")
          ),
        ],
      ),
    );
  }

  void _showAssignmentSheet(Map<String, dynamic> office) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => _AssignEmployeesSheet(
          office: office,
          employees: _allEmployees,
          onComplete: () {
            Navigator.pop(context);
            _loadData(); // Refresh to see updated office info
          },
        ),
      ),
    );
  }

  Future<void> _deleteOffice(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this office?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await GetIt.I<AdminRepository>().deleteOffice(id);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _offices.isEmpty 
        ? const Center(child: Text("No office locations defined."))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _offices.length,
            itemBuilder: (context, index) {
              final office = _offices[index];
              return Card(
                elevation: 0,
                color: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.business_outlined, color: Colors.blue)
                        ),
                        title: Text(office['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        subtitle: Text("Lat: ${office['latitude']}, Lng: ${office['longitude']}\nRadius: ${office['radius']}m"),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') _showOfficeDialog(office);
                            if (val == 'delete') _deleteOffice(office['id'].toString());
                            if (val == 'assign') _showAssignmentSheet(office);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'assign', child: ListTile(leading: Icon(Icons.group_add_outlined), title: Text("Assign Employees"), contentPadding: EdgeInsets.zero)),
                            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text("Edit Location"), contentPadding: EdgeInsets.zero)),
                            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text("Delete", style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      TextButton.icon(
                        onPressed: () => _showAssignmentSheet(office),
                        icon: const Icon(Icons.group_outlined, size: 18), 
                        label: const Text("Manage Assigned Employees"),
                        style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 40))
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOfficeDialog(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text("New Location"),
      ),
    );
  }
}

class _AssignEmployeesSheet extends StatefulWidget {
  final Map<String, dynamic> office;
  final List<UserModel> employees;
  final VoidCallback onComplete;

  const _AssignEmployeesSheet({required this.office, required this.employees, required this.onComplete});

  @override
  State<_AssignEmployeesSheet> createState() => _AssignEmployeesSheetState();
}

class _AssignEmployeesSheetState extends State<_AssignEmployeesSheet> {
  final Set<String> _selectedIds = {};
  String _searchQuery = "";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-select employees already assigned to this office
    for (var emp in widget.employees) {
      if (emp.officeId == widget.office['id'].toString()) {
        _selectedIds.add(emp.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.employees.where((e) => 
      e.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (e.employeeId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text("Assign to ${widget.office['name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Search employees...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final emp = filtered[index];
                final isCurrentOffice = emp.officeId == widget.office['id'].toString();
                final isOtherOffice = emp.officeId != null && emp.officeId != widget.office['id'].toString();
                
                return CheckboxListTile(
                  value: _selectedIds.contains(emp.id),
                  title: Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    isOtherOffice 
                      ? "Currently at: ${emp.officeName}" 
                      : (isCurrentOffice ? "Already assigned" : "Not assigned"),
                    style: TextStyle(fontSize: 12, color: isOtherOffice ? Colors.orange : (isCurrentOffice ? Colors.green : Colors.grey)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) _selectedIds.add(emp.id);
                      else _selectedIds.remove(emp.id);
                    });
                  },
                );
              },
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isSaving ? null : () async {
                setState(() => _isSaving = true);
                try {
                  await GetIt.I<AdminRepository>().bulkAssignOffice(
                    widget.office['id'].toString(), 
                    _selectedIds.toList()
                  );
                  widget.onComplete();
                } catch (e) {
                  setState(() => _isSaving = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text("Save Assignments (${_selectedIds.length})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
