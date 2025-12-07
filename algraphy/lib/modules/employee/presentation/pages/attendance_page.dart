import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/common/widgets/coming_soon_page.dart';
import 'package:algraphy/modules/employee/presentation/pages/attendance_history.dart';
import 'package:algraphy/modules/employee/presentation/views/dashboard_view.dart';
import 'package:algraphy/modules/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import '../views/attendance_timer_view.dart';

class AttendancePage extends StatefulWidget {
  final UserModel currentUser;
  const AttendancePage({super.key,required this.currentUser});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
    // Tabs list
  final List<String> _tabs = [
    "Dashboard",
    "Activities",
    "Attendance History",
    "Feeds",
    "Profile",
    "Approvals"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundDark = Color(0xFF080808);
    const Color primaryRed = Color(0xFFDC2726);

    // FIX: Removed Scaffold & AppBar to prevent duplicates.
    // MainScaffold provides the outer structure.
    return Column(
      children: [
        // 1. Tab Bar
        Container(
          color: backgroundDark,
          width: double.infinity,
          child: TabBar(
            controller: _tabController,
            isScrollable: true, 
            indicatorColor: primaryRed,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            dividerColor: Colors.transparent, 
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            labelPadding: const EdgeInsets.only(right: 24),
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),

        // 2. Tab Views Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              
              DashboardView(currentUser: widget.currentUser,),
              // Tab 2: Activities (Timer)
              const AttendanceTimerView(),
              const AttendanceHistoryPage(),
              // Other Tabs
              const ComingSoonPage(title: "Feeds"),
              ProfilePage(user: widget.currentUser),
              const ComingSoonPage(title: "Approvals"),
            ],
          ),
        ),
      ],
    );
  }
}