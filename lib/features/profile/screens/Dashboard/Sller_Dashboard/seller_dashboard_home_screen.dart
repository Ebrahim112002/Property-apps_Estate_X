import 'package:flutter/material.dart';
import '../Hooks/Header.dart';
import '../Hooks/dashboard_cards.dart';
import '../../../../../services/supabase_service.dart';   // ← যোগ করুন

class SellerDashboardHomeScreen extends StatefulWidget {
  const SellerDashboardHomeScreen({super.key});

  @override
  State<SellerDashboardHomeScreen> createState() =>
      _SellerDashboardHomeScreenState();
}

class _SellerDashboardHomeScreenState extends State<SellerDashboardHomeScreen> {
  final _supabaseService = SupabaseService();

  // Dynamic Stats
  int totalProperties = 0;
  int activeListings = 0;
  int totalBids = 0;
  int totalInterested = 0;   // Favorites / Interested

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final myProperties = await _supabaseService.fetchMyBidProperties();

      setState(() {
        totalProperties = myProperties.length;

        // Active Listings
        activeListings = myProperties.where((p) => p['is_active'] == true).length;

        // ✅ Fixed: Total Bids - Safe way
        totalBids = myProperties.fold<int>(0, (sum, p) {
          final bidCount = p['bid_count'];
          if (bidCount is int) return sum + bidCount;
          if (bidCount is double) return sum + bidCount.toInt();
          return sum;
        });

        // totalInterested পরে যোগ করবেন
        // totalInterested = ... 
      });
    } catch (e) {
      debugPrint('Dashboard data load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== HEADER ====================
                DashboardHeader(
                  key: UniqueKey(),
                  title: 'Seller Dashboard',
                  role: 'Seller',
                  profileRoute: '/seller-profile',
                ),
                const SizedBox(height: 24),

                // ==================== QUICK ACTIONS ====================
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const DashboardQuickActions(),
                const SizedBox(height: 28),

                // ==================== STATISTICS GRID ====================
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  DashboardStatsGrid(
                    totalProperties: totalProperties,
                    activeListings: activeListings,
                    totalBids: totalBids,
                    totalFavorites: totalInterested,
                    totalBookingRequests: 0, // পরে যোগ করবেন
                  ),

                const SizedBox(height: 28),

                // ==================== RECENT PROPERTIES ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent Properties",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/my-properties'),
                      child: const Text("View All"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecentProperties(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== RECENT PROPERTIES WIDGET ====================
  Widget _buildRecentProperties() {
    // এখনো স্ট্যাটিক রাখা হয়েছে। পরে Supabase থেকে আনতে পারবেন
    return Column(
      children: List.generate(3, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                "https://picsum.photos/id/${100 + index}/200",
                width: 78,
                height: 78,
                fit: BoxFit.cover,
              ),
            ),
            title: const Text(
              "Luxury 3 Bedroom Apartment",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Gulshan, Dhaka"),
                Text(
                  "৳ 1,25,00,000 • Active",
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 20),
            onTap: () {},
          ),
        );
      }),
    );
  }
}