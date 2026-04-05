import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';
// আপনার তৈরি করা ৩টি প্রোফাইল স্ক্রিন এখানে ইমপোর্ট করবেন
// import 'buyer_profile_screen.dart';
// import 'seller_profile_screen.dart';
// import 'admin_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _authService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    // ইউজার লগইন না থাকলে প্রফেশনাল প্রম্পট দেখাবে
    if (user == null) {
      return _buildLoginPrompt();
    }

    // ইউজার লগইন থাকলে তার রোল অনুযায়ী স্ক্রিন দেখাবে
    return FutureBuilder<String>(
      future: _authService.getUserRole(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final role = snapshot.data ?? 'buyer';

        if (role == 'admin') {
          return const Center(child: Text("Admin Profile Screen")); // AdminProfileScreen()
        } else if (role == 'seller') {
          return const Center(child: Text("Seller Profile Screen")); // SellerProfileScreen()
        } else {
          return const Center(child: Text("Buyer Profile Screen")); // BuyerProfileScreen()
        }
      },
    );
  }

  // --- প্রফেশনাল লগইন প্রম্পট UI ---
  Widget _buildLoginPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // একটি সুন্দর আইকন বা ইলাস্ট্রেশন (আপনার ইমেজের কালার প্যাটার্ন অনুযায়ী)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_pin, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 30),
          const Text(
            "Welcome to EstateX",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Login or Create an account to manage your properties and messages.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 40),
          
          // লগইন বাটন
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                // আপনার Login Screen এ নিয়ে যাবে
                Navigator.pushNamed(context, '/login'); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 15),
          
          // রেজিস্ট্রেশন বাটন (Outlined)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: () {
                // আপনার Register Screen এ নিয়ে যাবে
                Navigator.pushNamed(context, '/register');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Create Account", style: TextStyle(color: AppColors.primary, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}