import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
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
      final data = await _repo.getShifts();
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
    final startCtrl = TextEditingController(text: isEdit ? item['start_time'] : '09:00:00');
    final endCtrl = TextEditingController(text: isEdit ? item['end_time'] : '17:00:00');
    final graceCtrl = TextEditingController(text: isEdit ? item['grace_time']?.toString() : '15');

    await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text(
            isEdit ? "Edit Shift" : "Add Shift",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: const InputDecoration(
                    labelText: "Shift Name",
                    hintText: "e.g. Morning Shift",
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: const InputDecoration(
                    labelText: "Start Time",
                    hintText: "HH:MM:SS",
                    prefixIcon: Icon(Icons.login),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: const InputDecoration(
                    labelText: "End Time",
                    hintText: "HH:MM:SS",
                    prefixIcon: Icon(Icons.logout),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: graceCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Grace Time (minutes)",
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
                try {
                  await _repo.saveShift({
                    'id': isEdit ? item['id'] : null,
                    'name': nameCtrl.text.trim(),
                    'start_time': startCtrl.text.trim(),
                    'end_time': endCtrl.text.trim(),
                    'grace_time': int.tryParse(graceCtrl.text.trim()) ?? 15,
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
        content: const Text("Are you sure you want to delete this shift?"),
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
        await _repo.deleteShift(id);
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
                        labelText: 'Search Shifts',
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
              const Expanded(child: Center(child: Text("No shifts found. Tap + to add one.")))
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
            heroTag: 'shift_fab',
            onPressed: () => _showAddEditDialog(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final startTime = item['start_time']?.toString() ?? '--:--';
    final endTime = item['end_time']?.toString() ?? '--:--';
    final grace = item['grace_time']?.toString() ?? '0';
    final createdAt = item['created_at'] != null ? _formatTimestamp(item['created_at']) : 'N/A';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.15),
          child: const Icon(Icons.access_time_outlined, color: Colors.teal),
        ),
        title: Text(
          item['name']?.toString() ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(child: Text("$startTime – $endTime", style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: const Color(0xFFDC2726)),
                      const SizedBox(width: 4),
                      Flexible(child: Text("$grace min grace", style: const TextStyle(fontSize: 13, color: const Color(0xFFDC2726)), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Created At: $createdAt",
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
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
              onPressed: () {
                final id = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
                if (id != 0) _deleteItem(id);
              },
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
