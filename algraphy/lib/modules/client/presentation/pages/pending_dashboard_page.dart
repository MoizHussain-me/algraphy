import 'package:flutter/material.dart';
import 'package:algraphy/modules/auth/data/models/user_model.dart';

class PendingDashboardPage extends StatelessWidget {
  final UserModel currentUser;

  const PendingDashboardPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 80,
              color: Color(0xFFDC2726),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${currentUser.fullName}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your profile is currently under review.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Our team will review your application and contact you soon. Once approved, you will have full access to the Client Dashboard.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Contact Support Button
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement contact support action
              },
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Contact Support'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
