import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';

class DesignationsPage extends StatefulWidget {
  const DesignationsPage({super.key});

  @override
  State<DesignationsPage> createState() => _DesignationsPageState();
}

class _DesignationsPageState extends State<DesignationsPage> {
  final AdminRepository _repo = AdminRepository();
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getDesignations();
      if (mounted) {
        setState(() {
          _data = data;
          _applySearch(_searchQuery);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySearch(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredData = List.from(_data);
    } else {
      _filteredData = _data.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  Future<void> _showAddEditDialog([Map<String, dynamic>? item]) async {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: isEdit ? item['name'] : '');

    await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text(
            isEdit ? "Edit Designation" : "Add Designation",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: const InputDecoration(labelText: "Designation Name"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
                try {
                  await _repo.saveDesignation({
                    'id': isEdit ? item['id'] : null,
                    'name': nameCtrl.text.trim(),
                  });
                  _fetchData();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this designation?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.deleteDesignation(id);
        _fetchData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width > 800;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Designations',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: _applySearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchData,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_filteredData.isEmpty)
              const Expanded(child: Center(child: Text("No designations found. Tap + to add one.")))
            else
              Expanded(
                child: isWeb
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredData.length,
                            itemBuilder: (ctx, i) => _buildCard(_filteredData[i]),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredData.length,
                        itemBuilder: (ctx, i) => _buildCard(_filteredData[i]),
                      ),
              ),
          ],
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            heroTag: 'desig_fab',
            onPressed: () => _showAddEditDialog(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final createdAt = item['created_at'] != null ? _formatTimestamp(item['created_at']) : 'N/A';
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFDC2726).withOpacity(0.15),
          child: const Icon(Icons.badge_outlined, color: const Color(0xFFDC2726)),
        ),
        title: Text(
          item['name']?.toString() ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "Created At: $createdAt",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => _showAddEditDialog(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteItem(item['id'] as int),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) { return ts; }
  }
}
