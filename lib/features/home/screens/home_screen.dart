import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/property_model.dart';
import '../../../services/supabase_service.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Property>> _propertiesFuture;
  late Future<Map<String, dynamic>?> _userProfileFuture;
  String selectedFilter = 'House';
  String selectedType = 'Rent';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: _selectedIndex == 3 
          ? const ProfileScreen() 
          : _buildHomeContent(),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  // ==================== HOME CONTENT ====================
  Widget _buildHomeContent() {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildExploreTitle(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildFilterChips(),
              const SizedBox(height: 20),
              _buildSectionHeader("Best Offers", onSeeAll: () {}),
              const SizedBox(height: 15),
              _buildPropertyList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 1. HEADER with Big Avatar ====================
  Widget _buildHeader() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userProfileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final userName = profile?['full_name'] ?? 'Guest User';
        final userCity = profile?['city'] ?? 'Set Location';
        final userAvatar = profile?['avatar_url'];
        final userArea = profile?['area'] ?? '';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, ${_getFirstName(userName)}!",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, 
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          userArea.isNotEmpty ? "$userArea, $userCity" : userCity,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, 
                          color: Colors.grey, size: 18),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Badge(
                    child: Icon(Icons.notifications_outlined, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                // ✅ Bigger Avatar (60x60) with click to profile
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2.5),
                      image: userAvatar != null && userAvatar.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(userAvatar),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: userAvatar == null || userAvatar.isEmpty
                        ? Icon(Icons.person_outline, 
                            color: AppColors.primary, size: 35)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _getFirstName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts[0] : 'User';
  }

  // ==================== 2. EXPLORE TITLE ====================
  Widget _buildExploreTitle() {
    return const Text(
      "Explore",
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
    );
  }

  // ==================== 3. SEARCH BAR ====================
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search your home...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (value) {
                // Handle search
              },
            ),
          ),
          Container(
            height: 45,
            width: 45,
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ==================== 4. FILTER CHIPS ====================
  Widget _buildFilterChips() {
    List<String> typeFilters = ['Any type', 'Rent', 'Buy'];
    List<String> categoryFilters = ['House', 'Apartment', 'Villa', 'Land'];
    
    return Column(
      children: [
        // Type filters (Rent/Buy)
        Row(
          children: typeFilters.map((filter) {
            bool isSelected = selectedType == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selectedType = filter;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Category filters
        SizedBox(
          height: 35,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categoryFilters.map((filter) {
              bool isSelected = selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: Text(
            "See all",
            style: TextStyle(color: AppColors.primary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // ==================== 5. PROPERTY LIST ====================
  Widget _buildPropertyList() {
    return FutureBuilder<List<Property>>(
      future: _propertiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'Error loading properties',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.home_work_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'No properties found',
                    style: TextStyle(color: Colors.grey.shade600),
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
              _buildPropertyCard(properties[index]),
        );
      },
    );
  }

  // ==================== PROPERTY CARD (Reference Image Style) ====================
  Widget _buildPropertyCard(Property property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  property.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: Icon(
                    Icons.favorite_border,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    property.propertyType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      property.location,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "\$${property.price.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      property.listingType == 'Rent' ? "/month" : "",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                    const Spacer(),
                    // Features
                    Row(
                      children: [
                        Icon(Icons.bed, size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          "${property.bedrooms} Beds",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Icon(Icons.bathtub, size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          "${property.bathrooms} Baths",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Icon(Icons.garage, size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          "1 Garage",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM NAVIGATION BAR ====================
  Widget _buildFloatingNavBar() {
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, "Home", 0),
          _navItem(Icons.search_rounded, "Explore", 1),
          _navItem(Icons.favorite_rounded, "Saved", 2),
          _navItem(Icons.person_rounded, "Profile", 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSel = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSel ? AppColors.primary : Colors.grey,
              size: 24,
            ),
            if (isSel) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}