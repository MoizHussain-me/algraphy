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
import '../../../profile/presentation/profile_page.dart';
import '../../../client/presentation/views/client_overview_view.dart';

class AttendancePage extends StatefulWidget {
  final UserModel currentUser;
  const AttendancePage({super.key, required this.currentUser});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool get _isManager => widget.currentUser.role == 'admin' || widget.currentUser.isManager;
  bool get _isClient => widget.currentUser.role == 'client';

  Key _leavesViewKey = UniqueKey();

  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    _setupTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {}); 
    });
  }

  void _setupTabs() {
    if (_isClient) {
      _tabs = [
        "Overview",
        "Work",
        "Chats",
        "Documents",
        "Profile",
      ];
      return;
    }

    _tabs = [
      "Activities",
      "Dashboard",
      "Leaves",
      "Documents",
      "Attendance",
      "Profile",
    ];

    if (_isManager) {
      _tabs.add("Approvals");
    } else {
      // _tabs.add("Feeds");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> views = [];

    if (_isClient) {
      views = [
        ClientOverviewView(currentUser: widget.currentUser),
        const ComingSoonPage(title: "Project Work"),
        const ComingSoonPage(title: "Client Chats"),
        const ComingSoonPage(title: "Shared Documents"),
        ProfilePage(user: widget.currentUser, showScaffold: false),
      ];
    } else {
      views = [
        AttendanceTimerView(userName: widget.currentUser),
        DashboardView(currentUser: widget.currentUser),
        MyLeavesView(key: _leavesViewKey),
        DocumentManagementPage(isAdmin: false),
        const AttendanceHistoryPage(),
        ProfilePage(user: widget.currentUser, showScaffold: false),
      ];

      if (_isManager) {
        views.add(const ApprovalsView());
      } else {
        //views.add(const ComingSoonPage(title: "Feeds"));
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _buildFAB(Theme.of(context).primaryColor),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: double.infinity,
            child: TabBar(
              controller: _tabController,
              isScrollable: true, 
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
              dividerColor: Colors.transparent, 
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              labelPadding: const EdgeInsets.only(right: 24),
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

  Widget? _buildFAB(Color primaryColor) {
    if (_isClient) return null;
    // Index 2 is Leaves
    if (_tabController.index == 2) {
      return FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApplyLeaveView()),
          );
          if (result == true) {
            setState(() {
              _leavesViewKey = UniqueKey();
              _tabController.animateTo(2); 
            });
          }
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Apply Leave", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    return null;
  }
}
