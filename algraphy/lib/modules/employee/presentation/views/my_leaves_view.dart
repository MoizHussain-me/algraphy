import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class MyLeavesView extends StatefulWidget {
  const MyLeavesView({super.key});

  @override
  State<MyLeavesView> createState() => _MyLeavesViewState();
}

class _MyLeavesViewState extends State<MyLeavesView> {
  bool _isLoading = true;
  int _balance = 0;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchMyLeaves();
  }

  Future<void> _fetchMyLeaves() async {
    try {
      final data = await GetIt.I<EmployeeRepository>().getMyLeaves();
      
      if (mounted) {
        setState(() {
          // FIX: Access fields from the new API structure
          _balance = int.tryParse(data['balance']?.toString() ?? '0') ?? 0;
          
          // FIX: The list is now under the key 'history'
          _history = List<Map<String, dynamic>>.from(data['history'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2726)));
    }

    return RefreshIndicator(
      onRefresh: _fetchMyLeaves,
      color: const Color(0xFFDC2726),
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2726), Color(0xFFB91C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFFDC2726).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Annual Leave Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("$_balance Days", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("Request History", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text("No leave history found", style: TextStyle(color: Colors.grey))),
            ),

          ..._history.map((req) => Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(req['leave_type'] ?? 'General', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${req['start_date']} to ${req['end_date']} • ${req['days_count']} Days", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (req['reason'] != null && req['reason'].toString().isNotEmpty)
                      Text("Reason: ${req['reason']}", style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(req['status'] ?? 'Pending').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(req['status'] ?? 'Pending').withOpacity(0.5)),
                ),
                child: Text(req['status'] ?? 'Pending', style: TextStyle(color: _getStatusColor(req['status'] ?? 'Pending'), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          )),
        ],
      ),
    );
  }
}