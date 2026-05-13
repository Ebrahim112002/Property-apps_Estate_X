import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/property_model.dart';
import '../../../services/supabase_service.dart';
import '../../profile/screens/profile_screen.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/home_filter_chips.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_section_header.dart';
import '../widgets/property_card.dart';

// Seller Dashboard
import '../../profile/screens/Dashboard/Sller_Dashboard/seller_dashboard_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  late Future<List<Property>> _propertiesFuture;
  late Future<Map<String, dynamic>?> _userProfileFuture;

  String selectedType = 'Rent';
  String selectedFilter = 'House';
  int _selectedIndex = 0;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _propertiesFuture = _supabaseService.fetchProperties();
      _userProfileFuture = _getUserProfile();
    });
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final user = _supabaseService.currentUser;
    if (user == null) return null;
    return await _supabaseService.getProfile(user.id);
  }

  // ==================== Role Based Navigation ====================
  void _onItemTapped(int index) async {
    if (index == 3) {
      // Dashboard Button
      final user = _supabaseService.currentUser;

      if (user == null) {
        // লগইন না থাকলে Register এ নিয়ে যাবে
        if (mounted) Navigator.pushNamed(context, '/register');
        return;
      }

      try {
        final role = await _supabaseService.getUserRole(user.id);

        if (mounted) {
          if (role == 'seller') {
            Navigator.pushNamed(context, '/seller-dashboard');
          } else if (role == 'admin') {
            Navigator.pushNamed(context, '/admin-profile');
          } else if (role == 'buyer') {
            Navigator.pushNamed(context, '/buyer-profile');
          } else {
            // Default
            setState(() => _selectedIndex = 3);
          }
        }
      } catch (e) {
        debugPrint('Role fetch error: $e');
        if (mounted) Navigator.pushNamed(context, '/profile');
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped, // Updated here
        onAuctionTapped: () {
          Navigator.pushNamed(context, '/auction-screen');
        },
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const Center(child: Text("Search Screen"));
      case 2:
        return const Center(child: Text("Saved Properties"));
      case 3:
        return const ProfileScreen(); // Default fallback (যদি কোনো সমস্যা হয়)
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: HomeHeader(
                  onAvatarTap: () => _onItemTapped(3), // এটাও আপডেট করা হয়েছে
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HomeSearchBar(
                  controller: _searchController,
                  onFilterTap: () {},
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: HomeBanner(),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: HomeFilterChips(
                  selectedType: selectedType,
                  selectedFilter: selectedFilter,
                  onTypeChanged: (value) =>
                      setState(() => selectedType = value),
                  onCategoryChanged: (value) =>
                      setState(() => selectedFilter = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: HomeSectionHeader(title: "Best Offers", onSeeAll: () {}),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildPropertyList(),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyList() {
    return FutureBuilder<List<Property>>(
      future: _propertiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No properties found',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final properties = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: properties.length,
          itemBuilder: (context, index) =>
              PropertyCard(property: properties[index]),
        );
      },
    );
  }
}
