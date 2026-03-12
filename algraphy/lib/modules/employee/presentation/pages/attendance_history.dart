import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await GetIt.I<EmployeeRepository>().getAttendanceHistory();
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- SAFE FORMATTERS ---
  String _formatTime(dynamic timeStr) {
    if (timeStr == null || timeStr == '') return '--:--';
    try {
      final dt = DateTime.parse(timeStr.toString());
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '--:--';
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _formatHours(dynamic hours) {
    if (hours == null) return '-';
    final h = double.tryParse(hours.toString()) ?? 0.0;
    return "${h.toStringAsFixed(1)} hrs";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) return Center(child: CircularProgressIndicator(color: theme.primaryColor));

    if (_history.isEmpty) {
      return const Center(child: Text("No attendance history found", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final item = _history[index];
        final isCompleted = item['clock_out'] != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.1 : 0.05)),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(item['date']),
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCompleted ? "Completed" : "Active",
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  )
                ],
              ),

              // Times
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.login, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(item['clock_in']), 
                        style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 13)
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(item['clock_out']), 
                        style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 13)
                      ),
                    ],
                  ),
                ],
              ),

              // Total Hours Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isDark ? null : Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Text(
                  _formatHours(item['work_hours']),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color, 
                    fontWeight: FontWeight.bold,
                    fontSize: 13
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}