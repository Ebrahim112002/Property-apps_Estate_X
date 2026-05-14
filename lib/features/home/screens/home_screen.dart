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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  late Future<List<Property>> _propertiesFuture;

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
    });
  }

  void _onItemTapped(int index) async {
    if (index == 3) {
      final user = _supabaseService.currentUser;
      if (user == null) {
        if (mounted) Navigator.pushNamed(context, '/login');
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
        onItemTapped: _onItemTapped,
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
        return const Center(
          child: Text("Search Screen", style: TextStyle(color: Colors.white)),
        );
      case 2:
        return const Center(
          child: Text(
            "Saved Properties",
            style: TextStyle(color: Colors.white),
          ),
        );
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Stack(
          children: [
            // ১. কাস্টম গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড (image_b1eeb6.png এর স্টাইলে)
            ClipPath(
              clipper: HeaderCurveClipper(),
              child: Container(
                height: 230, // ব্যানারের মাঝ বরাবর পর্যন্ত কালার থাকবে
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(
                        0xFF04261F,
                      ), // ১ম ইমেজের আসল ডিপ ডার্ক ফরেস্ট গ্রিন (লাক্সারি বেস)
                      const Color(0xFF0B4633), // মিস্ট ফরেস্ট মিডিয়াম গ্রিন
                      const Color(0xFF145D47), // রিফ্রেশিং সেজ-গ্রিন শেড
                      const Color(
                        0xFF1B705A,
                      ).withOpacity(0.9), // লাইটার ট্রানজিশনাল গ্রিন
                    ],
                  ),
                ),
              ),
            ),

            // ২. মেইন কন্টেন্ট লেয়ার
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // হেডার
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: HomeHeader(onAvatarTap: () => _onItemTapped(3)),
                  ),
                  const SizedBox(height: 20),

                  // সার্চ বার
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: HomeSearchBar(
                      controller: _searchController,
                      onFilterTap: () {},
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ব্যানার
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: HomeBanner(),
                  ),
                  const SizedBox(height: 32),

                  // সাদা সেকশন - কন্টেন্ট এরিয়া
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
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
                          child: HomeSectionHeader(
                            title: "Best Offers",
                            onSeeAll: () {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildPropertyList(),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        final properties = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: properties.length,
          itemBuilder: (context, index) =>
              PropertyCard(property: properties[index]),
        );
      },
    );
  }
}

// ৩. কাস্টম শেপ ক্লিপার (Wave Effect)
class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 35);

    var firstControlPoint = Offset(size.width * 0.25, size.height - 5);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 0.75, size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 15);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
