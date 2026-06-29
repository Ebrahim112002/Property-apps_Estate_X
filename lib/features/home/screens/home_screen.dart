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

  String selectedType = 'Any type'; 
  String selectedFilter = 'Any type'; 
  int _selectedIndex = 0;
  String _searchQuery = ''; 

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
    if (index == 1) {
      Navigator.pushNamed(context, '/all-properties');
      return; 
    }
    if (index == 2) {
      // বটম নেভিগেশন বারের ২ নম্বর ইডেক্স (হার্ট/ফেভারিট আইকন)-এ ক্লিক করলেও এটি কাজ করবে
      Navigator.pushNamed(context, '/favorites');
      return;
    }
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
            Navigator.pushNamed(context, '/admin-dashboard');
          } else if (role == 'buyer') {
            Navigator.pushNamed(context, '/buyer-dashboard');
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
          Navigator.pushNamed(context, '/all-bid-properties');
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
            // ১. কাস্টম গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
            ClipPath(
              key: const ValueKey('gradient_bg'),
              clipper: HeaderCurveClipper(),
              child: Container(
                height: 170, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF04261F), 
                      const Color(0xFF0B4633), 
                      const Color(0xFF145D47), 
                      const Color(0xFF1B705A).withOpacity(0.9), 
                    ],
                  ),
                ),
              ),
            ),

            // ২. মেইন কন্টেন্ট লেয়ার
            SafeArea(
              bottom: false,
              child: FutureBuilder<List<Property>>(
                future: _propertiesFuture,
                builder: (context, snapshot) {
                  final List<Property> allProperties = snapshot.data ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // হেডার (ডানপাশে লাভ বাটন যুক্ত করা হয়েছে)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: HomeHeader(onAvatarTap: () => _onItemTapped(3)),
                            ),
                            // ==================== নতুন FAVORITE / LOVE ICON ACTION ====================
                            IconButton(
                              icon: const Icon(
                                Icons.favorite_border_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/favorites');
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // সার্চ বার
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: HomeSearchBar(
                          controller: _searchController,
                          allProperties: allProperties, 
                          onFilterTap: () {},
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ব্যানার
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: HomeBanner(),
                      ),
                      const SizedBox(height: 32),

                      // কন্টেন্ট এরিয়া
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
                              child: _buildPropertyList(snapshot),
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyList(AsyncSnapshot<List<Property>> snapshot) {
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
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final allProperties = snapshot.data!;

    final displayProperties = allProperties.where((property) {
      final titleMatch = property.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final locationMatch = property.location.toLowerCase().contains(_searchQuery.toLowerCase());
      final textMatches = titleMatch || locationMatch;

      final typeMatches = selectedType == 'Any type' || 
          property.listingType.toLowerCase() == selectedType.toLowerCase();

      final categoryMatches = selectedFilter == 'Any type' || 
          property.propertyType.toLowerCase() == selectedFilter.toLowerCase();

      return textMatches && typeMatches && categoryMatches;
    }).toList();

    if (displayProperties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No properties match your current filters',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayProperties.length,
      itemBuilder: (context, index) =>
          PropertyCard(property: displayProperties[index]),
    );
  }
}

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