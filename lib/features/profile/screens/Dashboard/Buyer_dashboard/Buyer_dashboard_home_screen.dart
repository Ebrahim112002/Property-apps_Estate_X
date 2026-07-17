import 'package:flutter/material.dart';
import '../../../../../services/supabase_service.dart';
import '../Hooks/Header.dart';
import '../../Dashboard/Hooks/Meeting_request.dart';

class BuyerDashboardHomeScreen extends StatefulWidget {
  const BuyerDashboardHomeScreen({super.key});

  @override
  State<BuyerDashboardHomeScreen> createState() =>
      _BuyerDashboardHomeScreenState();
}

class _BuyerDashboardHomeScreenState extends State<BuyerDashboardHomeScreen> {
  final _supabaseService = SupabaseService();

  // Dynamic & Logical Stats for Buyer
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
      final bookingRequests = await _supabaseService
          .fetchBuyersBookingRequests();

      setState(() {
        totalBookingRequests = bookingRequests.length;
        savedProperties = 18; // Default favorite value

        // Static or placeholders for now
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
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== HEADER ====================
                  DashboardHeader(
                    key: UniqueKey(),
                    title: "Buyer Dashboard",
                    role: "Buyer",
                    profileRoute: '/buyer-profile',
                  ),

                  // ==================== CONTENT BODY ====================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
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
                        const SizedBox(height: 28),

                        // ==================== QUICK INTERACTIONS ====================
                        const Text(
                          "Quick Interactions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildBuyerQuickActions(context),

                        const SizedBox(height: 28),

                        // Recent Activity Title
                        const Text(
                          "Recent Saved Properties",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Placeholder Card
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
                ],
              ),
            ),
    );
  }

  // ==================== STATS GRID WIDGET ====================
  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double aspectRatio = width < 340
            ? 1.15
            : width < 380
            ? 1.25
            : 1.45;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
              "Booking Requests",
              totalBookingRequests.toString(),
              Icons.request_page_outlined,
              Colors.teal,
              onTap: () =>
                  Navigator.pushNamed(context, '/buyer-booking-requests'),
            ),
            _buildStatCard(
              "Meeting Requests",
              "View", // এখানে সংখ্যা দেখাতে চাইলে আলাদা ভ্যারিয়েবল রাখো
              Icons.calendar_today_rounded,
              Colors.deepPurple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MeetingRequestsPage(userRole: 'buyer'),
                ),
              ),
            ),
            _buildStatCard(
              "Saved Properties",
              savedProperties.toString(),
              Icons.favorite_border_rounded,
              Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/favorites'),
            ),
            _buildStatCard(
              "Total Inquiries",
              totalInquiries.toString(),
              Icons.chat_bubble_outline_rounded,
              Colors.orange,
            ),
          ],
        );
      },
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth;
            final double pad = cardWidth < 150 ? 12 : 16;

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: color, size: cardWidth < 150 ? 24 : 28),
                      if (onTap != null)
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: Colors.grey.withOpacity(0.4),
                          size: 14,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== BUYER QUICK ACTIONS ====================
  Widget _buildBuyerQuickActions(BuildContext context) {
    return Column(
      children: [
        _actionCardRow(
          context,
          title: "My Bids History",
          subtitle: "Track your active & previous property bids",
          icon: Icons.history_edu_rounded,
          route: '/my-bids-history',
          colors: [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
        ),
        const SizedBox(height: 12),

        // New Meeting Requests Card
        _actionCardRow(
          context,
          title: "Meeting Requests",
          subtitle: "View & manage your property meeting requests",
          icon: Icons.calendar_today_rounded,
          route: '/buyer-meeting-requests',
          colors: [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
        ),
        const SizedBox(height: 12),

        _actionCardRow(
          context,
          title: "Explore Properties",
          subtitle: "Find properties and start bidding now",
          icon: Icons.search_rounded,
          route: '/all-properties',
          colors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
        ),
      ],
    );
  }

  Widget _actionCardRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    required List<Color> colors,
  }) {
    return GestureDetector(
      onTap: () {
        if (route == '/buyer-meeting-requests') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MeetingRequestsPage(userRole: 'buyer'),
            ),
          );
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
