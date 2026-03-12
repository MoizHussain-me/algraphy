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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final repo = GetIt.I<AdminRepository>();
      final logs = await repo.getOrganizationAttendance(employeeId: widget.employeeId);
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
                    child: RadioListTile<String>(
                      title: Text("In", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                      value: 'clock_in',
                      groupValue: markType,
                      activeColor: theme.primaryColor,
                      onChanged: (val) => setDialogState(() => markType = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text("Out", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                      value: 'clock_out',
                      groupValue: markType,
                      activeColor: theme.primaryColor,
                      onChanged: (val) => setDialogState(() => markType = val!),
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
      body: RefreshIndicator(
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
                                            _timeInfo(context, "OUT", clockOut, Colors.orange),
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