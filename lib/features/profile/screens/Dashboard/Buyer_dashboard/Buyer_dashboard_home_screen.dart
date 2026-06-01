import 'package:flutter/material.dart';
import '../Hooks/Header.dart';           // Dynamic Header
import '../Hooks/dashboard_cards.dart';   // যদি থাকে

class BuyerDashboardHomeScreen extends StatefulWidget {
  const BuyerDashboardHomeScreen({super.key});

  @override
  State<BuyerDashboardHomeScreen> createState() =>
      _BuyerDashboardHomeScreenState();
}

class _BuyerDashboardHomeScreenState extends State<BuyerDashboardHomeScreen> {
  int savedProperties = 18;
  int totalInquiries = 12;
  int propertiesViewed = 47;
  int totalNotifications = 8;

  Key headerKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => headerKey = UniqueKey());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamic Header
                DashboardHeader(
                  key: headerKey,
                  title: "Buyer Dashboard",
                  role: "Buyer",
                  profileRoute: '/buyer-profile',
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const BuyerDashboardQuickActions(),
                const SizedBox(height: 28),

                // Statistics
                BuyerDashboardStatsGrid(
                  savedProperties: savedProperties,
                  totalInquiries: totalInquiries,
                  propertiesViewed: propertiesViewed,
                  totalNotifications: totalNotifications,
                ),
                const SizedBox(height: 28),

                // Recommended Properties
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recommended For You",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/all-properties'),
                      child: const Text("View All"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecommendedProperties(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedProperties() {
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
                "https://picsum.photos/id/${200 + index}/200",
                width: 78,
                height: 78,
                fit: BoxFit.cover,
              ),
            ),
            title: const Text(
              "Modern 3 Bedroom Apartment",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Banani, Dhaka"),
                Text(
                  "৳ 85,00,000 • For Sale",
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 20),
            onTap: () => Navigator.pushNamed(context, '/property-details'),
          ),
        );
      }),
    );
  }
}

// ==================== Buyer Quick Actions & Stats (আগের মতোই) ====================

class BuyerDashboardQuickActions extends StatelessWidget {
  const BuyerDashboardQuickActions({super.key});

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
        _buildActionButton(Icons.search, "Browse Properties", Colors.blue, () => Navigator.pushNamed(context, '/all-properties')),
        _buildActionButton(Icons.favorite_border, "Saved Properties", Colors.pink, () => Navigator.pushNamed(context, '/saved-properties')),
        _buildActionButton(Icons.question_answer_outlined, "My Inquiries", Colors.teal, () => Navigator.pushNamed(context, '/my-inquiries')),
        _buildActionButton(Icons.notifications_outlined, "Notifications", Colors.orange, () => Navigator.pushNamed(context, '/notifications')),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class BuyerDashboardStatsGrid extends StatelessWidget {
  final int savedProperties;
  final int totalInquiries;
  final int propertiesViewed;
  final int totalNotifications;

  const BuyerDashboardStatsGrid({
    super.key,
    required this.savedProperties,
    required this.totalInquiries,
    required this.propertiesViewed,
    required this.totalNotifications,
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
        _buildStatCard("Saved", savedProperties.toString(), Icons.favorite, Colors.pink),
        _buildStatCard("Inquiries", totalInquiries.toString(), Icons.question_answer, Colors.teal),
        _buildStatCard("Viewed", propertiesViewed.toString(), Icons.visibility, Colors.blue),
        _buildStatCard("Notifications", totalNotifications.toString(), Icons.notifications, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 13.5, color: Colors.grey[700])),
        ],
      ),
    );
  }
}