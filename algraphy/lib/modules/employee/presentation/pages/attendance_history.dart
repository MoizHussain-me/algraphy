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

  String _selectedFilter = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _onFilterChanged(String filter) async {
    setState(() {
      _selectedFilter = filter;
    });

    final now = DateTime.now();
    if (filter == 'Today') {
      _startDate = now;
      _endDate = now;
      _fetchHistory();
    } else if (filter == 'This Week') {
      int downToMonday = now.weekday - 1;
      _startDate = now.subtract(Duration(days: downToMonday));
      _endDate = now;
      _fetchHistory();
    } else if (filter == 'This Month') {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
      _fetchHistory();
    } else if (filter == 'All Time') {
      _startDate = null;
      _endDate = null;
      _fetchHistory();
    } else if (filter == 'Custom') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
      );
      if (picked != null) {
        _startDate = picked.start;
        _endDate = picked.end;
        _fetchHistory();
      } else {
        setState(() {
          _selectedFilter = 'All Time';
          _startDate = null;
          _endDate = null;
        });
        _fetchHistory();
      }
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      String? startStr;
      String? endStr;
      if (_startDate != null) {
        startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      if (_endDate != null) {
        endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      }

      final data = await GetIt.I<EmployeeRepository>().getAttendanceHistory(
        startDate: startStr,
        endDate: endStr,
      );
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

  Widget _buildFilterChips(ThemeData theme) {
    final filters = ['All Time', 'Today', 'This Week', 'This Month', 'Custom'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected && _selectedFilter != f) {
                    _onFilterChanged(f);
                  }
                },
                selectedColor: theme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? theme.primaryColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content;
    if (_isLoading) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    } else if (_history.isEmpty) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("No attendance history found", style: TextStyle(color: Colors.grey)),
        ),
      );
    } else {
      content = ListView.builder(
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
                    child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Date & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green.withOpacity(0.1) : const Color(0xFFDC2726).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isCompleted ? "Completed" : "Active",
                          style: TextStyle(
                            color: isCompleted ? Colors.green : const Color(0xFFDC2726),
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on, size: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          item['office_name']?.toString() ?? "Head Office",
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Times
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.login, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(item['clock_in']), 
                            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 13)
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(item['clock_out']), 
                            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 13)
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
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
            ],
          ),
        );
      },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterChips(theme),
        content,
      ],
    );
  }
}