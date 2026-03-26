import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // সুপাবেস ইমপোর্ট
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';

Future<void> main() async {
  // ১. ফ্লাটার ইঞ্জিন নিশ্চিত করা
  WidgetsFlutterBinding.ensureInitialized();

  // ২. আপনার দেওয়া URL এবং Key দিয়ে সুপাবেস কানেক্ট করা
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
      // আপনার তৈরি করা স্প্ল্যাশ স্ক্রিন থেকেই অ্যাপ শুরু হবে
      home: const SplashScreen(),
    );
  }
}