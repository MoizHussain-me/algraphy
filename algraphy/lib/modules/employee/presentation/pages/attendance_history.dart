import 'package:algraphy/modules/employee/data/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final logs = await GetIt.I<AttendanceRepository>().getHistory();
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading history: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundDark = Color(0xFF080808);
    const Color cardColor = Color(0xFF1C1C1C);

    // FIX: Removed Scaffold & AppBar. Using Container for background.
    return Container(
      color: backgroundDark,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return _buildHistoryCard(log, cardColor);
                  },
                ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> log, Color cardColor) {
    // Parse Dates
    // API returns '2023-10-27 09:00:00'
    final checkIn = DateTime.parse(log['check_in']);
    final checkOut = log['check_out'] != null ? DateTime.parse(log['check_out']) : null;
    final String dateStr = DateFormat('EEE, d MMM y').format(checkIn);
    
    // Status Logic
    final bool isPresent = checkOut == null; // Currently checked in
    final double? hours = log['work_hours'] != null ? double.tryParse(log['work_hours'].toString()) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isPresent ? Colors.green : Colors.blueAccent,
            width: 4,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header: Date & Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (hours != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${hours.toStringAsFixed(1)} Hrs",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Time Row
          Row(
            children: [
              _buildTimeColumn("CHECK IN", checkIn, Colors.green),
              // Dotted Line or Spacer
              Expanded(
                child: Container(
                  height: 1, 
                  color: Colors.grey[800], 
                  margin: const EdgeInsets.symmetric(horizontal: 16)
                ),
              ),
              _buildTimeColumn("CHECK OUT", checkOut, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, DateTime? time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          time != null ? DateFormat('hh:mm a').format(time) : "--:--",
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          const Text("No attendance history found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}