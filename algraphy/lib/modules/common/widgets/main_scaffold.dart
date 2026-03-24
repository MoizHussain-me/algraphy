import 'package:algraphy/config/routes/app_routes.dart';
import 'package:algraphy/core/theme/colors.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'side_menu.dart';
import 'notification_panel.dart';
import '../../../core/services/notification_store.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final String currentRoute;
  final UserModel currentUser;

  const MainScaffold({super.key, required this.body, this.title = '', this.currentRoute = AppRoutes.home, required this.currentUser});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NotificationStore _notificationStore = NotificationStore();

  @override
  void initState() {
    super.initState();
    // Fetch notifications on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationStore.fetchNotifications();
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openNotificationPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim, secondaryAnim) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: const SizedBox(
                width: 340,
                height: double.infinity,
                child: NotificationPanel(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBellButton(BuildContext context) {
    return ListenableBuilder(
      listenable: _notificationStore,
      builder: (context, _) {
        final unread = _notificationStore.unreadCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => _openNotificationPanel(context),
            ),
            if (unread > 0)
              Positioned(
                top: 8,
                right: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWideScreen = width >= 800;
    final currentRoute = widget.currentRoute;

    if (isWideScreen) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    title: Text(widget.title.isEmpty ? 'Algraphy' : widget.title),
                    actions: [_buildBellButton(context)],
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
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: _openDrawer,
            ),
            title: Text(widget.title.isEmpty ? 'Algraphy' : widget.title),
            actions: [_buildBellButton(context)],
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
