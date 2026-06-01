import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';

// Auth Screens
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';

// Home & Bottom Nav
import 'features/home/screens/home_screen.dart';
// all properties
import 'features/home/ALl _properties/all_properties_view.dart';
import 'features/home/ALl _properties/Bid_properties/all_bid_properties.dart';

// Seller Dashboard
import 'features/profile/screens/Dashboard/Sller_Dashboard/seller_dashboard_home_screen.dart';
// buyer dashboard
import 'features/profile/screens/Dashboard/Buyer_dashboard/Buyer_dashboard_home_screen.dart';

// post bids
import 'features/profile/screens/Dashboard/Sller_Dashboard/Bids_properties/Bids_post.dart';
import 'features/profile/screens/Dashboard/Sller_Dashboard/Bids_properties/my_bid_properties.dart';
import 'features/profile/screens/Dashboard/Hooks/favorite.dart';

// Profile Screens
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/admin_profile_screen.dart';
import 'features/profile/screens/buyer_profile_screen.dart';
import 'features/profile/screens/seller_profile_screen.dart';

import 'features/profile/screens/Dashboard/Sller_Dashboard/post_properties.dart'; 

import 'features/profile/screens/Dashboard/Sller_Dashboard/my_properties.dart'; 

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
        '/home': (context) => const HomeScreen(),

        // Role Based Dashboard
        '/seller-dashboard': (context) => const SellerDashboardHomeScreen(),

        // Profile Routes
        '/profile': (context) => const ProfileScreen(),
        '/admin-profile': (context) => const AdminProfileScreen(),
        '/buyer-profile': (context) => const BuyerProfileScreen(),
        '/seller-profile': (context) => const SellerProfileScreen(),
        
        // Add Property Route
        '/add-property': (context) => const AddPropertyScreen(),
        '/my-properties': (context) => const MyPropertiesScreen(),
        '/all-properties': (context) => const AllPropertiesView(),
        '/all-bid-properties': (context) => const AllBidPropertiesScreen(),
        '/add-bid-properties': (context) => const PostBidPropertyScreen(),
        '/my-bid-properties': (context) => const MyBidPropertiesScreen(),
        
        '/buyer-dashboard': (context) => const BuyerDashboardHomeScreen(),
        
        '/favorites': (context) => const FavoritePage(),
      },
    );
  }
}