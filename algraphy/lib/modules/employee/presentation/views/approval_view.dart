import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:algraphy/modules/employee/presentation/views/leave_details_view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ApprovalsView extends StatefulWidget {
  const ApprovalsView({super.key});

  @override
  State<ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<ApprovalsView> {
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final data = await GetIt.I<EmployeeRepository>().getTeamLeaveRequests();
      if (mounted) {
        setState(() {
          _requests = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processRequest(String id, String status) async {
    setState(() => _isLoading = true);
    try {
      await GetIt.I<EmployeeRepository>().processLeaveRequest(id, status, "Manager Action");
      if (mounted) {
        setState(() {
          _requests.removeWhere((r) => r['id'].toString() == id);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Request $status"),
          backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, size: 60, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text("No pending approvals", textAlign: TextAlign.center, style: TextStyle(color: theme.hintColor)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (ctx, i) {
        final req = _requests[i];
        final id = req['id'].toString();
        final name = "${req['first_name']} ${req['last_name']}";
        final type = req['leave_type'] ?? 'Leave';
        final days = req['days_count'] ?? '1';
        final reason = req['reason'] ?? '';
        final start = req['start_date'];
        final end = req['end_date'];
        final canAction = req['can_action'] ?? false;

        return Card(
          color: theme.cardColor,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isDark ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.05)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeaveDetailsView(
                    request: req,
                    isManagerView: true,
                    canAction: canAction,
                    onAction: (status) => _processRequest(id, status),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                        child: Text(
                          name.isNotEmpty ? name[0] : '?', 
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name, 
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 16
                              ),
                            ),
                            Text("$days Days • $type", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : theme.scaffoldBackgroundColor.withOpacity(0.5), 
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.date_range, color: isDark ? Colors.white54 : Colors.black45, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              "$start  ➜  $end", 
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Reason: $reason", 
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54, 
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}