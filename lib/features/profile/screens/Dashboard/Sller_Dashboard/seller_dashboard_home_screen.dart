import 'package:flutter/material.dart';
import '../Hooks/Header.dart';
import '../Hooks/dashboard_cards.dart';

class SellerDashboardHomeScreen extends StatefulWidget {
  const SellerDashboardHomeScreen({super.key});

  @override
  State<SellerDashboardHomeScreen> createState() =>
      _SellerDashboardHomeScreenState();
}

class _SellerDashboardHomeScreenState extends State<SellerDashboardHomeScreen> {
  // পরে Supabase থেকে আসবে
  int totalProperties = 12;
  int activeListings = 7;
  int totalBids = 89;
  int totalInterested = 54;

  // হেডার রিসেট করার জন্য UniqueKey ব্যবহার করছি যেন রিফ্রেশ করলে নতুন করে ডেটা লোড হয়
  Key headerKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              headerKey = UniqueKey(); // হেডার রিলোড ট্রিগার করবে
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== HEADER ====================
                DashboardHeader(
                  key: headerKey,
                  title: 'Seller Dashboard',
                  role: 'Seller',
                  profileRoute: '/seller-profile',
                ),
                const SizedBox(height: 24),

                // ==================== QUICK ACTIONS (এখন উপরে) ====================
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const DashboardQuickActions(),
                const SizedBox(height: 28),

                // ==================== STATISTICS GRID (এখন নিচে) ====================
                DashboardStatsGrid(
                  totalProperties: totalProperties,
                  activeListings: activeListings,
                  totalBids: totalBids,
                  totalFavorites: totalInterested,
                ),
                const SizedBox(height: 28),

                // ==================== RECENT PROPERTIES ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent Properties",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/my-properties'),
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
    return Column(
      children: List.generate(3, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
