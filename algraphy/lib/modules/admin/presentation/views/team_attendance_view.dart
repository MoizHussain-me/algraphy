import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../../data/repositories/admin_data_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/theme/colors.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../modules/common/widgets/main_scaffold.dart';

class TeamAttendanceView extends StatefulWidget {
  final String? employeeId;
  final bool showScaffold;
  final UserModel? loggedInUser;

  const TeamAttendanceView({
    super.key,
    this.employeeId,
    this.showScaffold = false,
    this.loggedInUser,
  });

  @override
  State<TeamAttendanceView> createState() => _TeamAttendanceViewState();
}

class _TeamAttendanceViewState extends State<TeamAttendanceView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _attendanceLogs = [];
  List<UserModel> _employees = [];

  String _selectedFilter = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _onFilterChanged(String filter) async {
    setState(() {
      _selectedFilter = filter;
    });

    final now = DateTime.now();
    if (filter == 'Today') {
      _startDate = now;
      _endDate = now;
      _refreshData();
    } else if (filter == 'This Week') {
      int downToMonday = now.weekday - 1;
      _startDate = now.subtract(Duration(days: downToMonday));
      _endDate = now;
      _refreshData();
    } else if (filter == 'This Month') {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
      _refreshData();
    } else if (filter == 'All Time') {
      _startDate = null;
      _endDate = null;
      _refreshData();
    } else if (filter == 'Custom') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
      );
      if (picked != null) {
        _startDate = picked.start;
        _endDate = picked.end;
        _refreshData();
      } else {
        setState(() {
          _selectedFilter = 'All Time';
          _startDate = null;
          _endDate = null;
        });
        _refreshData();
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final repo = GetIt.I<AdminRepository>();
      
      String? startStr;
      String? endStr;
      if (_startDate != null) {
        startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      if (_endDate != null) {
        endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      }

      final logs = await repo.getOrganizationAttendance(
        employeeId: widget.employeeId,
        startDate: startStr,
        endDate: endStr,
      );
      final employees = await repo.getAllEmployees();

      if (mounted) {
        setState(() {
          _attendanceLogs = logs;
          _employees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching data: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showManualMarkDialog() {
    UserModel? selectedUser;
    String markType = 'clock_in';
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text("Manual Attendance Mark", style: TextStyle(color: theme.textTheme.titleLarge?.color)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<UserModel>(
                dropdownColor: theme.cardColor,
                decoration: InputDecoration(
                  labelText: "Select Employee",
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
                ),
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                items: _employees.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text("${u.firstName} ${u.lastName}"),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedUser = val),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => markType = 'clock_in'),
                      child: Row(
                        children: [
                          Icon(
                            markType == 'clock_in' ? Icons.check_box : Icons.check_box_outline_blank,
                            color: markType == 'clock_in' ? theme.primaryColor : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text("In", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => markType = 'clock_out'),
                      child: Row(
                        children: [
                          Icon(
                            markType == 'clock_out' ? Icons.check_box : Icons.check_box_outline_blank,
                            color: markType == 'clock_out' ? theme.primaryColor : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text("Out", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedUser == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _markAttendance(selectedUser!.id, markType);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAttendance(String userId, String type) async {
    setState(() => _isLoading = true);
    try {
      await GetIt.I<AdminRepository>().markEmployeeAttendance(userId, type);
      await _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance marked successfully"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    final mainContent = Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.employeeId != null 
          ? null 
          : FloatingActionButton.extended(
              onPressed: _showManualMarkDialog,
              backgroundColor: theme.primaryColor,
              icon: const Icon(Icons.edit_calendar, color: Colors.white),
              label: const Text("Manual Mark", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
      body: Column(
        children: [
          _buildFilterChips(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: theme.primaryColor,
        child: _attendanceLogs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: theme.disabledColor),
                    const SizedBox(height: 16),
                    const Text("No attendance logs found", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _attendanceLogs.length,
                itemBuilder: (context, index) {
                  final log = _attendanceLogs[index];
                  final name = "${log['first_name']} ${log['last_name']}";
                  final date = log['date'] ?? '';
                  final clockIn = log['clock_in'] != null ? _formatTime(log['clock_in']) : '--:--';
                  final clockOut = log['clock_out'] != null ? _formatTime(log['clock_out']) : '--:--';
                  final status = log['status'] ?? 'Absent';
                  final hours = log['work_hours'] != null ? double.parse(log['work_hours'].toString()).toStringAsFixed(1) : '0';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.1)),
                      boxShadow: isDark ? null : [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(width: 4, color: _getStatusColor(status)),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 2),
                                              Text(_formatDate(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        if (widget.employeeId == null)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.history_rounded, color: Colors.blueAccent, size: 20),
                                              visualDensity: VisualDensity.compact,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => TeamAttendanceView(
                                                      employeeId: log['employee_id']?.toString(),
                                                      showScaffold: true,
                                                      loggedInUser: widget.loggedInUser,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(color: theme.dividerColor.withOpacity(0.1)),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            _timeInfo(context, "IN", clockIn, Colors.green),
                                            const SizedBox(width: 20),
                                            _timeInfo(context, "OUT", clockOut, const Color(0xFFDC2726)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text("$hours hrs", style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w900, fontSize: 18)),
                                            Text(status, style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.showScaffold) {
      return MainScaffold(
        title: "History",
        currentUser: widget.loggedInUser ?? UserModel.empty(),
        currentRoute: AppRoutes.home,
        body: mainContent,
      );
    }
    return mainContent;
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

  Widget _timeInfo(BuildContext context, String label, String time, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(time, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present': return Colors.green;
      case 'Completed': return Colors.blueAccent;
      case 'On Break': return Colors.orange;
      case 'Late': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '--:--';
    try {
      final date = DateTime.parse(dateTimeStr);
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return dateTimeStr;
    }
  }
}