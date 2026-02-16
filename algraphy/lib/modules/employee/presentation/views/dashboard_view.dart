import 'package:algraphy/modules/admin/data/repositories/admin_data_repository.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/employee/data/employee_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/logger_service.dart';

class DashboardView extends StatefulWidget {
  final UserModel currentUser;

  const DashboardView({super.key, required this.currentUser});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  
  // Data Placeholders
  String _hoursThisWeek = "0.0";
  String _daysPresent = "0";
  Map<String, double> _weeklyChartData = {}; 
  List<dynamic> _recentActivities = [];

  // Admin Specific Placeholders
  String _totalEmployees = "0";
  String _onDutyNow = "0";
  String _onLeave = "0";
  String _lateArrivals = "0";

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final isAdmin = widget.currentUser.role == 'admin';

      if (isAdmin) {
        // --- ADMIN DATA FETCH ---
        final data = await GetIt.I<AdminRepository>().getAdminStats();
        logger.i("Admin Dash Data $data");
   
        
        if (mounted) {
          setState(() {
            _totalEmployees = data['total_employees']?.toString() ?? "0";
            _onDutyNow = data['on_duty']?.toString() ?? "0";
            _onLeave = data['on_leave']?.toString() ?? "0";
            _lateArrivals = data['late_arrivals']?.toString() ?? "0";
            
            final rawChart = data['weekly_chart'];
            if (rawChart is Map) {
              _weeklyChartData = rawChart.map((k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 0.0));
            } else {
              _weeklyChartData = {};
            }
            
            _recentActivities = data['recent_activity'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        // --- EMPLOYEE DATA FETCH ---
        final data = await GetIt.I<EmployeeRepository>().getDashboardStats();
        if (mounted) {
          setState(() {
            _hoursThisWeek = data['hoursWeek'].toString();
            _daysPresent = data['daysPresent'].toString();
            
            final rawChart = data['weeklyChart'];
            if (rawChart is Map) {
               _weeklyChartData = rawChart.map((k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 0.0));
            } else {
               _weeklyChartData = {};
            }

            _recentActivities = data['recent_activity'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundDark = Color(0xFF080808);
    final bool isAdmin = widget.currentUser.role == 'admin';
    
    if (_isLoading) {
      return Container(
        color: backgroundDark,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFDC2726))),
      );
    }

    return Container(
      color: backgroundDark,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isAdmin ? _buildAdminDashboard(context) : _buildEmployeeDashboard(context),
      ),
    );
  }

  // --- EMPLOYEE DASHBOARD ---
  Widget _buildEmployeeDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back, ${widget.currentUser.firstName}!",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          "Here's your attendance overview",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        _buildGrid([
          _MetricCard(
            title: "Hours This Week",
            value: _hoursThisWeek,
            trend: "Target: 40h",
            icon: Icons.access_time_filled,
            iconColor: const Color(0xFF7C4DFF),
          ),
          _MetricCard(
            title: "Days Present",
            value: _daysPresent,
            trend: "This Month",
            icon: Icons.calendar_today,
            iconColor: const Color(0xFF00BFA5),
          ),
          const _MetricCard(
            title: "Attendance Rate",
            value: "100%", 
            trend: "On Track",
            icon: Icons.show_chart,
            iconColor: Color(0xFFFF9100),
          ),
          const _MetricCard(
            title: "Leave Balance",
            value: "14",
            trend: "Annual",
            icon: Icons.beach_access,
            iconColor: Color(0xFFE91E63),
          ),
        ]),

        const SizedBox(height: 24),

        const _SectionHeader(title: "Weekly Work Trend"),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: _WeeklyBarChart(data: _weeklyChartData),
        ),

        const SizedBox(height: 24),

        const _SectionHeader(title: "My Recent Activity"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: _recentActivities.isEmpty 
              ? [const Text("No recent activity", style: TextStyle(color: Colors.grey))]
              : _recentActivities.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildActivityItemFromLog(item, isFirst: index == 0, isLast: index == _recentActivities.length - 1);
              }).toList(),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- ADMIN DASHBOARD ---
  Widget _buildAdminDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Admin Portal",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          "Overview for ${DateFormat('MMMM d, yyyy').format(DateTime.now())}",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        _buildGrid([
          _MetricCard(
            title: "Total Employees",
            value: _totalEmployees,
            trend: "+3 New",
            icon: Icons.people_alt,
            iconColor: Colors.blueAccent,
          ),
          _MetricCard(
            title: "On Duty Today",
            value: _onDutyNow,
            trend: "83% Active",
            icon: Icons.badge,
            iconColor: Colors.greenAccent,
          ),
          _MetricCard(
            title: "On Leave",
            value: _onLeave,
            trend: "Approved",
            icon: Icons.flight_takeoff,
            iconColor: Colors.orangeAccent,
          ),
          _MetricCard(
            title: "Late Arrivals",
            value: _lateArrivals,
            trend: "Needs Review",
            icon: Icons.timer_off,
            iconColor: Colors.redAccent,
          ),
        ]),

        const SizedBox(height: 24),

        // const _SectionHeader(title: "Quick Actions"),
        // const SizedBox(height: 16),
        // Wrap(
        //   spacing: 12,
        //   runSpacing: 12,
        //   children: [
        //     _QuickActionChip(label: "Add Employee", icon: Icons.person_add, onTap: () {}),
        //     _QuickActionChip(label: "Approve Leaves", icon: Icons.playlist_add_check, onTap: () {}),
        //     _QuickActionChip(label: "Attendance Report", icon: Icons.summarize, onTap: () {}),
        //     _QuickActionChip(label: "Company Settings", icon: Icons.settings, onTap: () {}),
        //   ],
        // ),

        const SizedBox(height: 24),

        const _SectionHeader(title: "Company Attendance (Avg Hours)"),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: _WeeklyBarChart(data: _weeklyChartData),
        ),

        const SizedBox(height: 24),
        
        const _SectionHeader(title: "Live Employee Activity"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: _recentActivities.isEmpty 
              ? [const Text("No recent activity", style: TextStyle(color: Colors.grey))]
              : _recentActivities.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildAdminActivityItem(item, isFirst: index == 0, isLast: index == _recentActivities.length - 1);
              }).toList(),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- Helper: Convert Log to Activity Item (Employee) ---
  Widget _buildActivityItemFromLog(Map<String, dynamic> log, {bool isFirst = false, bool isLast = false}) {
    if (log['check_in'] == null) return const SizedBox.shrink();
    
    final checkIn = DateTime.parse(log['check_in']);
    final checkOut = log['check_out'] != null && log['check_out'].toString().isNotEmpty ? DateTime.parse(log['check_out']) : null;
    final dateStr = DateFormat('MMM d').format(checkIn);
    final timeStr = DateFormat('h:mm a').format(checkIn);

    String title = "Clocked In";
    String subtitle = "$dateStr at $timeStr";
    Color color = Colors.green;

    if (checkOut != null) {
      title = "Shift Completed";
      final outTimeStr = DateFormat('h:mm a').format(checkOut);
      subtitle = "$dateStr • $timeStr - $outTimeStr";
      color = Colors.blue;
    }

    return _ActivityItem(
      title: title,
      subtitle: subtitle,
      color: color,
      isFirst: isFirst,
      isLast: isLast,
    );
  }

  // --- Helper: Convert Log to Activity Item (Admin) ---
  Widget _buildAdminActivityItem(Map<String, dynamic> log, {bool isFirst = false, bool isLast = false}) {
    final name = log['name'] ?? 'Unknown';
    final type = log['type'] ?? 'Activity';
    final rawTime = log['clock_in'] ?? log['check_in']; // Get raw value and fallback

    // CRITICAL FIX: Handle Null or Empty check_in
    if (rawTime == null || rawTime.toString().isEmpty) {
      return const SizedBox.shrink(); // Skip invalid entries
    }

    DateTime time;
    try {
      time = DateTime.parse(rawTime.toString());
    } catch (_) {
      return const SizedBox.shrink(); // Skip malformed dates
    }

    final timeStr = DateFormat('h:mm a').format(time);

    Color color = Colors.grey;
    if (type == 'Check In') color = Colors.green;
    if (type == 'Check Out') color = Colors.blue;

    return _ActivityItem(
      title: name,
      subtitle: "$type at $timeStr",
      color: color,
      isFirst: isFirst,
      isLast: isLast,
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1, 
          children: children,
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({required this.title, required this.value, required this.trend, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 16)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(children: [const Icon(Icons.info_outline, color: Colors.grey, size: 12), const SizedBox(width: 4), Expanded(child: Text(trend, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis))]),
            ],
          )
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final Map<String, double> data; 
  const _WeeklyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 12,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
              const style = TextStyle(color: Colors.grey, fontSize: 10);
              if (value.toInt() >= 0 && value.toInt() < days.length) return SideTitleWidget(axisSide: meta.axisSide, child: Text(days[value.toInt()], style: style));
              return const SizedBox.shrink();
            })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) => Text('${value.toInt()}h', style: const TextStyle(color: Colors.grey, fontSize: 10)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(days.length, (index) {
            final dayName = days[index];
            final hours = data[dayName] ?? 0.0;
            return BarChartGroupData(x: index, barRods: [BarChartRodData(toY: hours, color: hours > 0 ? Colors.blueAccent : Colors.grey.withOpacity(0.1), width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), backDrawRodData: BackgroundBarChartRodData(show: true, toY: 12, color: Colors.white.withOpacity(0.05)))]);
          }),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _ActivityItem({required this.title, required this.subtitle, required this.color, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [if (!isFirst) Container(width: 2, height: 20, color: Colors.white10) else const SizedBox(height: 20), Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)])), if (!isLast) Container(width: 2, height: 30, color: Colors.white10)]),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 24)])),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickActionChip({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ActionChip(avatar: Icon(icon, size: 18, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF2A2A2A), padding: const EdgeInsets.all(12), onPressed: onTap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: const BorderSide(color: Colors.white10));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) { return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)); }
}