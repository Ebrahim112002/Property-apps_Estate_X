import 'package:flutter/material.dart';
import '../Hooks/Header.dart';
import '../Hooks/dashboard_cards.dart';
import '../../../../../services/supabase_service.dart';
import '../Hooks/Meeting_request.dart';   // ← এই লাইনটা যোগ করো

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
  int totalInterested = 0;
  int totalMeetingRequests = 0;   // ← নতুন

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

      // Meeting Requests Count
      final meetings = await _supabaseService.fetchMeetingRequests('seller');

      setState(() {
        totalProperties = myProperties.length;
        activeListings = myProperties.where((p) => p['is_active'] == true).length;

        totalBids = myProperties.fold<int>(0, (sum, p) {
          final bidCount = p['bid_count'];
          if (bidCount is int) return sum + bidCount;
          if (bidCount is double) return sum + bidCount.toInt();
          return sum;
        });

        totalMeetingRequests = meetings.length;
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
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                key: UniqueKey(),
                title: 'Seller Dashboard',
                role: 'Seller',
                profileRoute: '/seller-profile',
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Actions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    const DashboardQuickActions(),
                    const SizedBox(height: 28),

                    const Text(
                      "Overview Statistics",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      DashboardStatsGrid(
                        totalProperties: totalProperties,
                        activeListings: activeListings,
                        totalBids: totalBids,
                        totalFavorites: totalInterested,
                        totalBookingRequests: 0,
                        totalMeetingRequests: totalMeetingRequests,   // ← নতুন প্যারামিটার
                      ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent Properties",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/my-properties'),
                          child: const Text("View All"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRecentProperties(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentProperties() {
    return Column(
      children: List.generate(3, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 2,
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final bool isUltraSmall = width < 330;

              return ListTile(
                contentPadding: EdgeInsets.all(isUltraSmall ? 10 : 14),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    "https://picsum.photos/id/${100 + index}/200",
                    width: isUltraSmall ? 64 : 74,
                    height: isUltraSmall ? 64 : 74,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  "Luxury 3 Bedroom Apartment",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: isUltraSmall ? 14 : 15),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text("Gulshan, Dhaka", style: TextStyle(fontSize: isUltraSmall ? 11 : 13)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "৳ 1,25,00,000 • Active",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: isUltraSmall ? 11 : 13),
                      ),
                    ),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: isUltraSmall ? 16 : 18, color: Colors.black45),
                onTap: () {},
              );
            },
          ),
        );
      }),
    );
  }
}