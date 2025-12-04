import 'package:algraphy/config/routes/app_routes.dart';
import 'package:algraphy/core/theme/colors.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'side_menu.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final String currentRoute;
  final UserModel currentUser;

  const MainScaffold({super.key, required this.body, this.title = '',this.currentRoute = AppRoutes.home,required this.currentUser});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWideScreen = width >= 800; // persistent side panel for desktop/web
    final currentRoute = widget.currentRoute;

    if (isWideScreen) {
      // Persistent side menu for wide screens
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Row(
          children: [
            SizedBox(
              width: 250,
              child: SideMenu(
                isPersistent: true,
                activeRoute: currentRoute,
                currentUser: widget.currentUser,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: AppColors.backgroundDark,
                    title: Text(widget.title.isEmpty ? 'Algraphy' : widget.title),
                  ),
                  Expanded(
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: widget.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile: keep GestureDetector for swipe drawer
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Detect left-to-right swipe from left edge to open drawer
          if (details.delta.dx > 12) {
            _openDrawer();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          drawerEdgeDragWidth: 20,
          drawer: SideMenu(
            isPersistent: false,
            activeRoute: currentRoute,
             currentUser: widget.currentUser,
          ),
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: _openDrawer,
            ),
            title: Text(widget.title.isEmpty ? 'Algraphy' : widget.title),
          ),
          body: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: widget.body,
            ),
          ),
        ),
      );
    }
  }
}
