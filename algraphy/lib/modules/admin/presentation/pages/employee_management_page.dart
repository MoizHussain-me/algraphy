import 'package:algraphy/modules/signature/presentation/pages/document_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import '../views/registration_stepper_view.dart';
import '../views/team_attendance_view.dart';
import '../views/geofence_management_view.dart';
import '../../../../modules/common/widgets/coming_soon_page.dart';
import 'all_employees_page.dart'; 

class EmployeeManagementPage extends StatefulWidget {
  final bool isAdmin;
  final int initialIndex;
  final UserModel currentUser;

  const EmployeeManagementPage({
    super.key,
    required this.isAdmin,
    required this.currentUser,
    this.initialIndex = 0,
  });

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    _setupTabs();
    
    int startIndex = widget.initialIndex;
    if (startIndex >= _tabs.length) startIndex = 0;

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: startIndex,
    );
  }

  void _setupTabs() {
    if (widget.isAdmin) {
      _tabs = ["Directory", "Attendance", "Onboarding", "Geofencing", "Org Tree", "Documents"];
    } else {
      _tabs = ["Directory", "Attendance", "Org Tree", "Documents"];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            children: _buildTabViews(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTabViews() {
    List<Widget> views = [
      AllEmployeesPage(currentUser: widget.currentUser), 
      TeamAttendanceView(loggedInUser: widget.currentUser),
    ];

    if (widget.isAdmin) {
      // Admin Views
      if (kIsWeb) {
        views.add(const RegistrationStepperView()); 
      } else {
        views.add(const _MobileOnboardingRestrictedView());
      }
      views.add(const GeofenceManagementView());
      views.add(const ComingSoonPage(title: "Organization Tree"));
      views.add(const DocumentManagementPage(isAdmin: true));
    } else {
      // Non-Admin Views
      views.add(const ComingSoonPage(title: "Organization Tree"));
      views.add(const DocumentManagementPage(isAdmin: false));
    }

    return views;
  }
}

class _MobileOnboardingRestrictedView extends StatelessWidget {
  const _MobileOnboardingRestrictedView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Web Portal Only", style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }
}