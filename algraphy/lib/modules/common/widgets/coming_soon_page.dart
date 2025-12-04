import 'package:algraphy/modules/auth/data/models/user_model.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'main_scaffold.dart';

class ComingSoonPage extends StatefulWidget {
  final String title;
  final UserModel user;
  const ComingSoonPage({super.key, required this.title,required this.user});

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage> {
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentUser: widget.user,
      title: widget.title,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 72, color: AppColors.textGrey),
            const SizedBox(height: 16),
            Text(
              '${widget.title}\nComing Soon',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: AppColors.textGrey,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
