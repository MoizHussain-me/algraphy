import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // 1. Import Platform Check
import '../views/registration_stepper_view.dart';
import '../../../../modules/common/widgets/coming_soon_page.dart';

class EmployeeManagementPage extends StatefulWidget {
  final bool isAdmin;
  final int initialIndex;

  const EmployeeManagementPage({
    super.key,
    required this.isAdmin,
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
    if (widget.isAdmin) {
      _tabs = ["Directory", "Onboarding", "Org Tree", "Documents"];
    } else {
      _tabs = ["Directory", "Org Tree"];
    }

    int startIndex = widget.initialIndex;
    if (startIndex >= _tabs.length) startIndex = 0;

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: startIndex,
    );
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

    return Column(
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
      const ComingSoonPage(title: "Employee Directory"),
    ];

    if (widget.isAdmin) {
      // 2. Platform Check Logic
      if (kIsWeb) {
        // Web: Show the full Stepper
        views.add(const RegistrationStepperView()); 
      } else {
        // Mobile: Show Restricted Message
        views.add(const _MobileOnboardingRestrictedView());
      }
      
      views.add(const ComingSoonPage(title: "Organization Tree"));
      views.add(const ComingSoonPage(title: "Documents"));
    } else {
      views.add(const ComingSoonPage(title: "Organization Tree"));
    }

    return views;
  }
}

// --- 3. New Restricted View Widget ---
class _MobileOnboardingRestrictedView extends StatelessWidget {
  const _MobileOnboardingRestrictedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.desktop_mac_outlined, size: 80, color: Colors.grey[800]),
            const SizedBox(height: 24),
            const Text(
              "Web Portal Only",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "The Employee Onboarding process is comprehensive and requires the Web Portal to manage documents and forms effectively.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                // Optional: Link to web url or instructions
              },
              icon: const Icon(Icons.info_outline),
              label: const Text("Read Guidelines"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
            )
          ],
        ),
      ),
    );
  }
}