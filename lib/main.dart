import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';

// Auth Screens
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';

// Profile Screens
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/admin_profile_screen.dart';
import 'features/profile/screens/buyer_profile_screen.dart';
import 'features/profile/screens/seller_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hxkokgzbeqmfdkzzeuex.supabase.co',
    anonKey: 'sb_publishable_lpOKSL2cJyyFuDMAXEOH0w_Q5jlrP7y',
  );

  runApp(const EstateXApp());
}

class EstateXApp extends StatelessWidget {
  const EstateXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EstateX',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        // Role Checker Profile (সবচেয়ে গুরুত্বপূর্ণ)
        '/profile': (context) => const ProfileScreen(),

        // Specific Profiles
        '/admin-profile': (context) => const AdminProfileScreen(),
        '/buyer-profile': (context) => const BuyerProfileScreen(),
        '/seller-profile': (context) => const SellerProfileScreen(),
      },
    );
  }
}
