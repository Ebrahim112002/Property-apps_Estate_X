import 'package:flutter/material.dart';

// ==================== QUICK ACTIONS COMPONENT ====================
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, // প্রতি লাইনে ২টি করে বাটন থাকবে
      shrinkWrap: true, // কলামের ভেতরে জায়গা ঠিক রাখার জন্য
      physics:
          const NeverScrollableScrollPhysics(), // স্ক্রোলিং বন্ধ রাখার জন্য
      crossAxisSpacing: 14, // পাশাপাশি বাটনের দূরত্ব
      mainAxisSpacing: 14, // উপর-নিচের বাটনের দূরত্ব
      childAspectRatio: 1.6, // বাটনগুলোর সাইজ বা অনুপাত
      children: [
        // ১. Add Property বাটন (ক্লিক করলে সাধারণ প্রোপার্টি ফর্মে নিয়ে যাবে)
        _buildActionButton(
          icon: Icons.add_circle_outline,
          label: "Add Property",
          color: Colors.deepPurple,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/add-property',
              arguments: 'Normal', // সাধারণ লিস্টিং আইডেন্টিফায়ার
            );
          },
        ),

        // ২. Add Auction Property বাটন (ক্লিক করলে এটিও একই ফাইলে যাবে কিন্তু 'Auction' টাইপ নিয়ে)
        _buildActionButton(
          icon: Icons.gavel_outlined,
          label: "Add Auction properties",
          color: Colors.orange,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/add-bid-properties', // আপনার main.dart এর রাউট
              arguments: 'Auction', // অকশন আইডেন্টিফায়ার
            );
          },
        ),

        // ৩. My Properties বাটন
        _buildActionButton(
          icon: Icons.list_alt_outlined,
          label: "My Properties",
          color: Colors.indigo,
          onTap: () => Navigator.pushNamed(context, '/my-properties'),
        ),

        // ৪. Bids & Offers বাটন
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
  final int totalInterested;

  const DashboardStatsGrid({
    super.key,
    required this.totalProperties,
    required this.activeListings,
    required this.totalBids,
    required this.totalInterested,
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
        ),
        _buildStatCard(
          "Active Listings",
          activeListings.toString(),
          Icons.visibility_outlined,
          Colors.green,
        ),
        _buildStatCard(
          "Total Bids",
          totalBids.toString(),
          Icons.gavel_rounded,
          Colors.orange,
        ),
        _buildStatCard(
          "Interested",
          totalInterested.toString(),
          Icons.favorite_outline,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
        ],
      ),
    );
  }
}
