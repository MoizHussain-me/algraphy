import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  final UserModel currentUser; // Accepts current user

  const DashboardView({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    const Color backgroundDark = Color(0xFF080808);
    // Check role to decide layout
    final bool isAdmin = currentUser.role == 'admin';
    
    return Container(
      color: backgroundDark,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isAdmin ? _buildAdminDashboard(context) : _buildEmployeeDashboard(context),
      ),
    );
  }

  // --- EMPLOYEE DASHBOARD (Personal Focus) ---
  Widget _buildEmployeeDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Welcome Header
        Text(
          "Welcome back, ${currentUser.firstName}!", // Dynamic Name
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
          const _MetricCard(
            title: "Hours This Week",
            value: "38.5",
            trend: "+2.5%",
            icon: Icons.access_time_filled,
            iconColor: Color(0xFF7C4DFF), // Purple
          ),
          const _MetricCard(
            title: "Days Present",
            value: "22",
            trend: "+5.2%",
            icon: Icons.calendar_today,
            iconColor: Color(0xFF00BFA5), // Teal
          ),
          const _MetricCard(
            title: "Attendance Rate",
            value: "95.6%",
            trend: "+1.2%",
            icon: Icons.show_chart,
            iconColor: Color(0xFFFF9100), // Orange
          ),
          const _MetricCard(
            title: "Leave Balance",
            value: "4 Days",
            trend: "Casual",
            icon: Icons.beach_access,
            iconColor: Color(0xFFE91E63), // Pink
          ),
        ]),

        const SizedBox(height: 24),

        // 3. Weekly Hours Chart
        const _SectionHeader(title: "My Weekly Hours"),
        const SizedBox(height: 16),
        const SizedBox(
          height: 250,
          child: _WeeklyBarChart(isEmployee: true),
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
            children: const [
              _ActivityItem(
                title: "Clocked In",
                subtitle: "Today at 09:00 AM",
                color: Colors.green,
                isFirst: true,
              ),
              _ActivityItem(
                title: "Leave Approved",
                subtitle: "Yesterday",
                color: Colors.blue,
              ),
              _ActivityItem(
                title: "Clocked Out",
                subtitle: "2 days ago at 05:30 PM",
                color: Colors.green,
              ),
              _ActivityItem(
                title: "Late Arrival",
                subtitle: "3 days ago at 09:45 AM",
                color: Colors.orange,
                isLast: true,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  // --- ADMIN DASHBOARD (Organization Focus) ---
  Widget _buildAdminDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Welcome Header
        const Text(
          "Admin Overview",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          "Organization status for today",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // 2. Key Metric Cards (Admin Specific)
        _buildGrid([
          const _MetricCard(
            title: "Live Headcount",
            value: "45/50",
            trend: "90% Present",
            icon: Icons.people,
            iconColor: Colors.blueAccent, 
          ),
          const _MetricCard(
            title: "Absent Today",
            value: "3",
            trend: "Sick / Casual",
            icon: Icons.person_off,
            iconColor: Colors.redAccent, 
          ),
          const _MetricCard(
            title: "Late Arrivals",
            value: "8",
            trend: "+2 vs yest.",
            icon: Icons.timer_off,
            iconColor: Colors.orangeAccent, 
          ),
          const _MetricCard(
            title: "Pending Approvals",
            value: "5",
            trend: "Needs Action",
            icon: Icons.approval,
            iconColor: Colors.amber, 
          ),
        ]),

        const SizedBox(height: 24),

        // 3. Organization Chart
        const _SectionHeader(title: "Organization Attendance Trend"),
        const SizedBox(height: 16),
        const SizedBox(
          height: 250,
          child: _WeeklyBarChart(isEmployee: false),
        ),

        const SizedBox(height: 24),

        // 4. Team Activity
        const _SectionHeader(title: "Team Activity Feed"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: const [
              _ActivityItem(
                title: "Sarah Smith",
                subtitle: "Clocked in Late (09:15 AM)",
                color: Colors.orange,
                isFirst: true,
              ),
              _ActivityItem(
                title: "John Doe",
                subtitle: "Applied for Sick Leave",
                color: Colors.blue,
              ),
              _ActivityItem(
                title: "Mike Ross",
                subtitle: "Clocked Out Early (04:00 PM)",
                color: Colors.red,
              ),
              _ActivityItem(
                title: "Emily Blunt",
                subtitle: "Completed Onboarding",
                color: Colors.green,
                isLast: true,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
      ],
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
          // Aspect Ratio 1.1 prevents overflow
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
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    trend.contains('+') || trend.contains('Need') ? Icons.info_outline : Icons.trending_up,
                    color: Colors.grey,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trend,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
  const _WeeklyBarChart({this.isEmployee = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: isEmployee ? 12 : 100,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: Colors.grey, fontSize: 10);
                  String text;
                  switch (value.toInt()) {
                    case 0: text = 'Mon'; break;
                    case 1: text = 'Tue'; break;
                    case 2: text = 'Wed'; break;
                    case 3: text = 'Thu'; break;
                    case 4: text = 'Fri'; break;
                    default: text = '';
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    isEmployee ? '${value.toInt()}h' : '${value.toInt()}%', 
                    style: const TextStyle(color: Colors.grey, fontSize: 10)
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: isEmployee 
            ? _buildEmployeeData() 
            : _buildAdminData(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildEmployeeData() {
    return [
      _makeGroupData(0, 8.5, Colors.blueAccent),
      _makeGroupData(1, 7.0, Colors.purpleAccent),
      _makeGroupData(2, 9.0, Colors.blueAccent),
      _makeGroupData(3, 9.5, Colors.blueAccent),
      _makeGroupData(4, 6.0, Colors.orangeAccent),
    ];
  }

  List<BarChartGroupData> _buildAdminData() {
    return [
      _makeGroupData(0, 95, Colors.greenAccent, maxY: 100),
      _makeGroupData(1, 92, Colors.greenAccent, maxY: 100),
      _makeGroupData(2, 88, Colors.orangeAccent, maxY: 100),
      _makeGroupData(3, 96, Colors.greenAccent, maxY: 100),
      _makeGroupData(4, 90, Colors.greenAccent, maxY: 100),
    ];
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color, {double maxY = 12}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.white.withValues(alpha: 0.05),
          ),
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
            if (!isFirst) Container(width: 2, height: 20, color: Colors.white10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
                ]
              ),
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
              const SizedBox(height: 24), // Spacing between items
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}