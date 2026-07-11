import 'package:flutter/material.dart';
import '../../../../services/supabase_service.dart';

class BannedAccountScreen extends StatelessWidget {
  const BannedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = SupabaseService();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gavel_rounded, size: 90, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "ACCESS DENIED!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your account has been suspended by the administrator. You cannot access any dashboard or features.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await authService.signOut(); // Supabase থেকে লগআউট
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/login',
                    ); // লগইন স্ক্রিনে ব্যাক
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout & Exit",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
