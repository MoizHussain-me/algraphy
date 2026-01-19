import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:algraphy/modules/common/widgets/coming_soon_page.dart';
import 'package:algraphy/modules/employee/presentation/pages/attendance_history.dart';
import 'package:algraphy/modules/employee/presentation/views/approval_view.dart';
import 'package:algraphy/modules/employee/presentation/views/dashboard_view.dart';
import 'package:algraphy/modules/signature/presentation/pages/document_management_page.dart';
import 'package:flutter/material.dart';
import '../views/attendance_timer_view.dart';
import '../views/apply_leave_view.dart'; 
import '../views/my_leaves_view.dart'; 

class AttendancePage extends StatefulWidget {
  final UserModel currentUser;
  const AttendancePage({super.key, required this.currentUser});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Logic: Employee is Manager if Admin OR has direct reports
  bool get _isManager => widget.currentUser.role == 'admin' || widget.currentUser.isManager;

  // Key to force refresh of Leaves tab
  Key _leavesViewKey = UniqueKey();

  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    _setupTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to show/hide FAB
    });
  }

  void _setupTabs() {
    _tabs = [
      "Activities",
      "Dashboard",
      "Leaves",   
      "Documents",  
      "Attendance", 
    ];

    // FIX: Add the 5th tab conditionally so Controller length matches UI
    if (_isManager) {
      _tabs.add("Approvals");
    } else {
      _tabs.add("Feeds");
    }
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

    // Rebuild views list to apply the new Key if it changed
    List<Widget> views = [
      AttendanceTimerView(userName: widget.currentUser),
      DashboardView(currentUser: widget.currentUser),
      // Pass the key here. When _leavesViewKey changes, this widget rebuilds from scratch.
      MyLeavesView(key: _leavesViewKey),
      DocumentManagementPage(isAdmin: false), 
      const AttendanceHistoryPage(),
    ];

    if (_isManager) {
      views.add(const ApprovalsView());
    } else {
      views.add(const ComingSoonPage(title: "Feeds"));
    }

    return Scaffold(
      backgroundColor: backgroundDark,
      floatingActionButton: _tabController.index == 2 ? FloatingActionButton.extended(
        onPressed: () async {
          // Wait for result from Apply page
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApplyLeaveView()),
          );

          // If result is true (submission successful), force refresh the Leaves tab
          if (result == true) {
            setState(() {
              _leavesViewKey = UniqueKey(); // Changes the key -> Rebuilds MyLeavesView -> Calls initState -> Fetches Data
              
              // Optional: Switch to the "Leaves" tab (Index 2) so they see it
              _tabController.animateTo(2); 
            });
          }
        },
        backgroundColor: primaryRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Apply Leave", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
      body: Column(
        children: [
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
              // Use _tabs here to ensure it matches the controller length
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: views,
            ),
          ),
        ],
      ),
    );
  }
}