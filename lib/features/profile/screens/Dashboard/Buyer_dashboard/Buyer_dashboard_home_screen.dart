import 'package:flutter/material.dart';
import '../../../../../services/supabase_service.dart';
import '../Hooks/Header.dart';

class BuyerDashboardHomeScreen extends StatefulWidget {
  const BuyerDashboardHomeScreen({super.key});

  @override
  State<BuyerDashboardHomeScreen> createState() =>
      _BuyerDashboardHomeScreenState();
}

class _BuyerDashboardHomeScreenState extends State<BuyerDashboardHomeScreen> {
  final _supabaseService = SupabaseService();

  int savedProperties = 0;
  int totalInquiries = 12;
  int propertiesViewed = 47;
  int totalNotifications = 8;
  int totalBookingRequests = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;

      // Real Data Fetch
      final bookingRequests = await _supabaseService.fetchBuyersBookingRequests();

      setState(() {
        totalBookingRequests = bookingRequests.length;
        savedProperties = 18; // Default value

        // Static for now
        totalInquiries = 12;
        propertiesViewed = 47;
        totalNotifications = 8;
      });
    } catch (e) {
      debugPrint('Error loading buyer dashboard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ১. FIXED: Apnar ashol correct parameters shoho DashboardHeader design call
                    DashboardHeader(
                      key: UniqueKey(),
                      title: "Buyer Dashboard",
                      role: "Buyer",
                      profileRoute: '/buyer-profile',
                    ),
                    const SizedBox(height: 24),

                    // Welcome Text
                    const Text(
                      "Buyer Overview",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Grid Layout
                    _buildStatsGrid(),
                    const SizedBox(height: 16),

                    // ==================== MY BIDS HISTORY CARD FOR BUYER ====================
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/my-bids-history'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_edu_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              "My Bids History",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity Title (Main Design e jemon chilo)
                    const Text(
                      "Recent Saved Properties",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Placeholder Main Design content intact rakha hoyeche
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "No recently viewed items",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ==================== STATS GRID WIDGET ====================
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.65,
      children: [
        _buildStatCard(
          "Saved",
          savedProperties.toString(),
          Icons.favorite_border_rounded,
          Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/favorites'),
        ),
        _buildStatCard(
          "Inquiries",
          totalInquiries.toString(),
          Icons.chat_bubble_outline_rounded,
          Colors.orange,
        ),
        _buildStatCard(
          "Viewed",
          propertiesViewed.toString(),
          Icons.visibility_outlined,
          Colors.purple,
        ),
        // ২. FIXED: Booking Requests card-ti grid-e shundor kore thakbe (duplicate bad deya hoyeche)
        _buildStatCard(
          "Booking Requests",
          totalBookingRequests.toString(),
          Icons.request_page_outlined,
          Colors.teal,
          onTap: () => Navigator.pushNamed(context, '/buyer-booking-requests'),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 13.5, color: Colors.grey[700]),
            ),
            if (title == "Saved" || title == "Booking Requests")
              const Text(
                "Tap to view",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.teal,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}