import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/employee/data/attendance_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

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
  Map<String, double> _weeklyChartData = {}; // {'Mon': 8.0, 'Tue': 7.5}
  List<dynamic> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final data = await GetIt.I<AttendanceRepository>().getDashboardStats();
      if (mounted) {
        setState(() {
          _hoursThisWeek = data['hoursWeek'].toString();
          _daysPresent = data['daysPresent'].toString();
          
          // Parse Chart Data
          // API returns: {'Mon': 8.5, 'Tue': 7.0}
          // We convert it to a robust Map<String, double>
          final rawChart = data['weeklyChart'];
          if (rawChart is Map) {
             _weeklyChartData = rawChart.map((k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 0.0));
          } else if (rawChart is List) {
             // Handle case where PHP returns empty array [] instead of object {}
             _weeklyChartData = {};
          }

          _recentActivities = data['recent'] ?? [];
          _isLoading = false;
        });
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
        child: const Center(child: CircularProgressIndicator()),
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
        // 1. Welcome Header
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

        // 2. Key Metric Cards
        _buildGrid([
          _MetricCard(
            title: "Hours This Week",
            value: _hoursThisWeek,
            trend: "Target: 40h",
            icon: Icons.access_time_filled,
            iconColor: const Color(0xFF7C4DFF), // Purple
          ),
          _MetricCard(
            title: "Days Present",
            value: _daysPresent,
            trend: "This Month",
            icon: Icons.calendar_today,
            iconColor: const Color(0xFF00BFA5), // Teal
          ),
          const _MetricCard(
            title: "Attendance Rate",
            value: "100%", // Placeholder calculation
            trend: "On Track",
            icon: Icons.show_chart,
            iconColor: Color(0xFFFF9100), // Orange
          ),
          const _MetricCard(
            title: "Leave Balance",
            value: "14",
            trend: "Annual",
            icon: Icons.beach_access,
            iconColor: Color(0xFFE91E63), // Pink
          ),
        ]),

        const SizedBox(height: 24),

        // 3. Weekly Hours Chart
        const _SectionHeader(title: "Weekly Work Trend"),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: _WeeklyBarChart(data: _weeklyChartData, isEmployee: true),
        ),

        const SizedBox(height: 24),

        // 4. Recent Activity
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

  // --- Helper: Convert Log to Activity Item ---
  Widget _buildActivityItemFromLog(Map<String, dynamic> log, {bool isFirst = false, bool isLast = false}) {
    final checkIn = DateTime.parse(log['check_in']);
    final checkOut = log['check_out'] != null ? DateTime.parse(log['check_out']) : null;
    final dateStr = DateFormat('MMM d').format(checkIn);
    final timeStr = DateFormat('h:mm a').format(checkIn);

    // If checkOut exists, show that too, otherwise just Check In
    String title = "Clocked In";
    String subtitle = "$dateStr at $timeStr";
    Color color = Colors.green;

    if (checkOut != null) {
      // If we want to show Check Out as a separate event, we would need to split the list.
      // For simplicity, we show the completed session here.
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

  // --- ADMIN DASHBOARD (Placeholder for now) ---
  Widget _buildAdminDashboard(BuildContext context) {
    return const Center(child: Text("Admin Dashboard (Coming Soon)", style: TextStyle(color: Colors.white)));
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

// --- 1. Metric Card Widget ---
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey, size: 12),
                  const SizedBox(width: 4),
                  Expanded(child: Text(trend, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

// --- 2. Chart Widget (FL Chart) ---
class _WeeklyBarChart extends StatelessWidget {
  final bool isEmployee;
  final Map<String, double> data; // Dynamic Data
  
  const _WeeklyBarChart({this.isEmployee = true, required this.data});

  @override
  Widget build(BuildContext context) {
    // Days of week order
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 12,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: Colors.grey, fontSize: 10);
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                     return SideTitleWidget(axisSide: meta.axisSide, child: Text(days[value.toInt()], style: style));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}h', style: const TextStyle(color: Colors.grey, fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(days.length, (index) {
            final dayName = days[index];
            final hours = data[dayName] ?? 0.0;
            return _makeGroupData(index, hours, hours > 0 ? Colors.blueAccent : Colors.grey.withOpacity(0.1));
          }),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 12, color: Colors.white.withOpacity(0.05)),
        ),
      ],
    );
  }
}

// --- 3. Activity Timeline Widget ---
class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Line & Dot
        Column(
          children: [
            if (!isFirst) Container(width: 2, height: 20, color: Colors.white10) else const SizedBox(height: 20),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]),
            ),
            if (!isLast) Container(width: 2, height: 30, color: Colors.white10),
          ],
        ),
        const SizedBox(width: 16),
        // Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24), 
            ],
          ),
        ),
      ],
    );
  }
}

// --- Helper ---
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
  }
}