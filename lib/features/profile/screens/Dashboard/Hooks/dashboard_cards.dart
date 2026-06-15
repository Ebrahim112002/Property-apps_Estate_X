import 'package:flutter/material.dart';

// ==================== QUICK ACTIONS COMPONENT ====================
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.6,
      children: [
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

  const DashboardStatsGrid({
    super.key,
    required this.totalProperties,
    required this.activeListings,
    required this.totalBids,
    required this.totalFavorites,
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
          "Total Bids",           // ← এখানে ক্লিক করলে Bid History দেখাবে
          totalBids.toString(),
          Icons.gavel_rounded,
          Colors.orange,
          onTap: () {
            Navigator.pushNamed(context, '/seller-bid-history');   // ← Route Name
            // অথবা MaterialPageRoute দিয়ে সরাসরি স্ক্রিনে যেতে চাইলে:
            // Navigator.push(context, MaterialPageRoute(builder: (_) => SellerBidHistoryScreen()));
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
            if (title == "Total Bids")
              const Text(
                "Tap to see details",
                style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}