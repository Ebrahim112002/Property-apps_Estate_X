import 'package:flutter/material.dart';

// ==================== QUICK ACTIONS COMPONENT (UPDATED WITH MY BIDS HISTORY) ====================
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    // গ্রিডের আইটেমগুলোর লিস্ট তৈরি করা হলো যাতে বিজোড় কার্ডটি সুন্দরভাবে ফুল-উইডথ জুড়ে বসে
    final List<Widget> actionButtons = [
      _buildActionButton(
        icon: Icons.add_circle_outline,
        label: "Add Property",
        color: Colors.deepPurple,
        onTap: () {
          Navigator.pushNamed(context, '/add-property', arguments: 'Normal');
        },
      ),
      _buildActionButton(
        icon: Icons.gavel_outlined,
        label: "Add Auction properties",
        color: Colors.orange,
        onTap: () {
          Navigator.pushNamed(context, '/add-bid-properties', arguments: 'Auction');
        },
      ),
      _buildActionButton(
        icon: Icons.list_alt_outlined,
        label: "My Properties",
        color: Colors.indigo,
        onTap: () => Navigator.pushNamed(context, '/my-properties'),
      ),
      _buildActionButton(
        icon: Icons.local_offer_outlined,
        label: "Your Bids Properties",
        color: Colors.teal,
        onTap: () => Navigator.pushNamed(context, '/my-bid-properties'),
      ),
    ];

    return Column(
      children: [
        // প্রথম ৪টি কার্ড ২x২ গ্রিডে সাজানো হলো
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.6,
          children: actionButtons,
        ),
        const SizedBox(height: 14),
        
        // ==================== নতুন My Bids History কার্ড ====================
        // যেহেতু এটি ৫ম কার্ড, তাই গ্রিডের নিচে এটি চমৎকার একটি হরিজন্টাল ব্যানার কার্ড হিসেবে শো করবে
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/my-bids-history'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)], // প্রিমিয়াম লুকের জন্য চমৎকার গ্রেডিয়েন্ট
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
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== STATISTICS GRID COMPONENT ====================
class DashboardStatsGrid extends StatelessWidget {
  final int totalProperties;
  final int activeListings;
  final int totalBids;
  final int totalFavorites;
  final int totalBookingRequests;

  const DashboardStatsGrid({
    super.key,
    required this.totalProperties,
    required this.activeListings,
    required this.totalBids,
    required this.totalFavorites,
    required this.totalBookingRequests,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.65,
      children: [
        _buildStatCard(
          "Total Properties",
          totalProperties.toString(),
          Icons.home_work_outlined,
          Colors.blue,
          onTap: () {
            Navigator.pushNamed(context, '/seller-booking-requests');
          },
        ),
        _buildStatCard(
          "Active Listings",
          activeListings.toString(),
          Icons.visibility_outlined,
          Colors.green,
          onTap: () {},
        ),
        _buildStatCard(
          "Total Bids",
          totalBids.toString(),
          Icons.gavel_rounded,
          Colors.orange,
          onTap: () {
            Navigator.pushNamed(context, '/seller-bid-history');
          },
        ),
        _buildStatCard(
          "Favorites",
          totalFavorites.toString(),
          Icons.favorite,
          Colors.purple,
          onTap: () {
            Navigator.pushNamed(context, '/favorites');
          },
        ),
        _buildStatCard(
          "Booking Requests",
          totalBookingRequests.toString(),
          Icons.request_page_outlined,
          Colors.teal,
          onTap: () {
            Navigator.pushNamed(context, '/buyer-booking-requests');
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    {required VoidCallback onTap}
  ) {
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
            const SizedBox(height: 4),
            if (title == "Booking Requests")
              const Text(
                "Tap to view all",
                style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}