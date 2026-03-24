import 'package:flutter/material.dart';

class LeaveDetailsView extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isManagerView;
  final bool canAction;
  final Function(String status)? onAction;

  const LeaveDetailsView({
    super.key,
    required this.request,
    this.isManagerView = false,
    this.canAction = false,
    this.onAction,
  });

  Widget _buildHierarchyAvatar(String name, String status, ThemeData theme) {
    Color badgeColor = Colors.grey;
    IconData badgeIcon = Icons.schedule;
    
    if (status == 'Approved') {
      badgeColor = Colors.green;
      badgeIcon = Icons.check;
    } else if (status == 'Rejected') {
      badgeColor = Colors.red;
      badgeIcon = Icons.close;
    }

    final initials = name.isNotEmpty ? name[0] : '?';
    final displayName = name.split(' ').first;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Text(
                initials, 
                style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)
              ),
            ),
            Positioned(
              bottom: 0,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: badgeColor,
                  child: Icon(badgeIcon, size: 12, color: Colors.white),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Text(displayName, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    
    // Parse fields safely
    final name = "${request['first_name'] ?? ''} ${request['last_name'] ?? ''}";
    final primaryStatus = request['primary_status'] ?? 'Pending';
    final secondaryStatus = request['secondary_status'] ?? 'Pending';
    final type = request['leave_type'] ?? 'Leave';
    final days = request['days_count'] ?? '1';
    final start = request['start_date'] ?? '-';
    final reason = request['reason'] ?? 'Not provided';
    final created = request['created_at'] != null ? request['created_at'].toString().split(' ')[0] : '-';

    return Scaffold(
      backgroundColor: Colors.black, // Dark themed based on screenshots
      appBar: AppBar(
        title: const Text("Details"),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Details", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("for $name", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[800],
                  child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 28, color: Colors.white)),
                )
              ],
            ),
            
            const SizedBox(height: 30),

            // Approval Hierarchy Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("APPROVAL HIERARCHY", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildHierarchyAvatar("Line Mgr", primaryStatus, theme),
                      const SizedBox(width: 20),
                      const Icon(Icons.arrow_forward, color: Colors.white54, size: 20),
                      const SizedBox(width: 20),
                      _buildHierarchyAvatar("Sec Mgr", secondaryStatus, theme),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text("Leave", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            const Text("Employee Info", style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            
            // Vertical Accent Lines block
            Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.pink[200]!.withOpacity(0.5), width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Reporting Manager Action", style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("${request['primary_status'] ?? 'Pending'} ${request['primary_action_at'] != null ? '(' + request['primary_action_at'] + ')' : ''}", style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  
                  const Text("Secondary Manager Action", style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("${request['secondary_status'] ?? 'Pending'} ${request['secondary_action_at'] != null ? '(' + request['secondary_action_at'] + ')' : ''}", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text("Leave type", style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 4),
            Text(type, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            
            const SizedBox(height: 24),
            const Text("Date", style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 4),
            Text(start, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    color: Colors.tealAccent.withOpacity(0.5),
                  )
                ),
                const SizedBox(width: 12),
                Text("$days Day(s)", style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text("Total Days Taken", style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 4),
            Text("$days Day(s)", style: const TextStyle(color: Colors.white, fontSize: 16)),
            
            const SizedBox(height: 24),
            const Text("Date of request", style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 4),
            Text(created, style: const TextStyle(color: Colors.white, fontSize: 16)),
            
            const SizedBox(height: 24),
            const Text("Reason for leave", style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 4),
            Text(reason, style: const TextStyle(color: Colors.white, fontSize: 16)),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: (isManagerView && onAction != null) ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: !canAction 
          ? const Text("Pending Action from Co-Manager", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
          : Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAction!("Rejected");
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.red, 
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Reject", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAction!("Approved");
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Approve", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ) : null,
    );
  }
}
