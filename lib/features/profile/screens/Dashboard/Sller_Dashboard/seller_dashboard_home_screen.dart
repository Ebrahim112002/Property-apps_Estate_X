import 'package:flutter/material.dart';
import '../../../../../services/supabase_service.dart';
import '../../../../../core/constants/app_colors.dart';

class SellerDashboardHomeScreen extends StatefulWidget {
  const SellerDashboardHomeScreen({super.key});

  @override
  State<SellerDashboardHomeScreen> createState() =>
      _SellerDashboardHomeScreenState();
}

class _SellerDashboardHomeScreenState extends State<SellerDashboardHomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  // পরে Supabase থেকে আসবে
  int totalProperties = 12;
  int activeListings = 7;
  int totalBids = 89;
  int totalInterested = 54;

  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getProfile();
  }

  Future<Map<String, dynamic>?> _getProfile() async {
    final user = _supabaseService.currentUser;
    if (user == null) return null;
    return await _supabaseService.getProfile(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Seller Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final avatarUrl = profile?['avatar_url'] as String?;
              final fullName = profile?['full_name'] ?? 'Seller';

              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/seller-profile'),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      // Bigger & Beautiful Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: Colors.deepPurple,
                                  size: 30,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "My Profile",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                            ),
                          ),
                          Text(
                            _getFirstName(fullName),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _profileFuture = _getProfile();
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              FutureBuilder<Map<String, dynamic>?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final name = _getFirstName(snapshot.data?['full_name'] ?? 'Seller');
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B00FF), Color(0xFFB14EFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back, $name 👋",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Manage your properties & track performance",
                          style: TextStyle(fontSize: 15, color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Statistics
              _buildStatsGrid(),
              const SizedBox(height: 28),

              // Quick Actions
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 28),

              // Recent Properties
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
    );
  }

  String _getFirstName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts[0] : 'Seller';
  }

  // ==================== STATISTICS ====================
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.65,
      children: [
        _buildStatCard("Total Properties", totalProperties.toString(), Icons.home_work_outlined, Colors.blue),
        _buildStatCard("Active Listings", activeListings.toString(), Icons.visibility_outlined, Colors.green),
        _buildStatCard("Total Bids", totalBids.toString(), Icons.gavel_rounded, Colors.orange),
        _buildStatCard("Interested", totalInterested.toString(), Icons.favorite_outline, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  // ==================== QUICK ACTIONS ====================
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline,
            label: "Add Property",
            color: Colors.deepPurple,
            onTap: () => Navigator.pushNamed(context, '/add-property'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionButton(
            icon: Icons.list_alt_outlined,
            label: "My Properties",
            color: Colors.indigo,
            onTap: () => Navigator.pushNamed(context, '/my-properties'),
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
        padding: const EdgeInsets.symmetric(vertical: 22),
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
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== RECENT PROPERTIES ====================
  Widget _buildRecentProperties() {
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
                Text("৳ 1,25,00,000 • Active", style: TextStyle(color: Colors.green)),
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