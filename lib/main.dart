import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart'; // ইমপোর্ট চেক করুন
import 'features/auth/screens/register_screen.dart'; // ইমপোর্ট চেক করুন
import 'features/profile/screens/profile_screen.dart';

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
      initialRoute: '/', // অ্যাপ স্প্ল্যাশ স্ক্রিন দিয়ে শুরু হবে
      routes: {
        '/': (context) => const SplashScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}