import 'package:flutter/material.dart';
import '../../../services/supabase_service.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _service = SupabaseService();
  bool _isLoading = true;

  int _totalUsers = 0;
  int _totalProperties = 0;
  int _totalSellers = 0;
  int _totalBuyers = 0;

  Map<String, dynamic>? _adminProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _service.currentUser?.id;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await _service.getProfile(uid);
    if (mounted) {
      setState(() {
        _adminProfile = profile;
      });
      await _loadStats();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final supabase = _service.supabaseClient;

      // Total Users
      final usersCount = await supabase.from('profiles').count();

      // Total Properties
      final propertiesCount = await supabase.from('properties').count();

      // Total Sellers
      final sellersRes = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'seller');

      // Total Buyers
      final buyersRes = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'buyer');

      if (mounted) {
        setState(() {
          _totalUsers = usersCount;
          _totalProperties = propertiesCount;
          _totalSellers = (sellersRes as List).length;
          _totalBuyers = (buyersRes as List).length;
        });
      }
    } catch (e) {
      debugPrint("Error loading stats: $e");
    }
  }
  // ====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('📊 Platform Overview'),
                        _buildStatsGrid(),
                        const SizedBox(height: 25),
                        _buildSectionTitle('👤 Admin Info'),
                        _buildAdminInfoCard(),
                        const SizedBox(height: 25),
                        _buildSectionTitle('⚙️ Admin Actions'),
                        _buildActionCard(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar() {
    final name = _adminProfile?['full_name'] ?? 'Admin User';
    final email = _service.currentUser?.email ?? 'admin@estatex.com';
    final avatar = _adminProfile?['avatar_url'];

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: Colors.red.shade700,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade900, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white24,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? const Icon(
                        Icons.admin_panel_settings,
                        size: 50,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Chip(
                label: const Text(
                  '🔑 SYSTEM ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.black26,
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            await _service.signOut();
            if (mounted) Navigator.pushReplacementNamed(context, '/profile');
          },
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _buildStatTile(
          'Total Users',
          _totalUsers.toString(),
          Icons.people_alt_rounded,
          Colors.blue,
        ),
        _buildStatTile(
          'Properties',
          _totalProperties.toString(),
          Icons.home_rounded,
          Colors.green,
        ),
        _buildStatTile(
          'Active Sellers',
          _totalSellers.toString(),
          Icons.badge_rounded,
          Colors.orange,
        ),
        _buildStatTile(
          'Total Buyers',
          _totalBuyers.toString(),
          Icons.shopping_bag_rounded,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminInfoCard() {
    final uid = _service.currentUser?.id ?? 'N/A';
    final email = _service.currentUser?.email ?? 'N/A';

    return Container(
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
      child: Column(
        children: [
          _buildInfoRow('Admin ID', uid, Icons.fingerprint),
          _buildDivider(),
          _buildInfoRow(
            'Access Level',
            'Root Administrator',
            Icons.security_rounded,
          ),
          _buildDivider(),
          _buildInfoRow('Email Address', email, Icons.alternate_email_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.red.shade400, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildDivider() => Divider(
    color: Colors.grey.shade100,
    height: 1,
    indent: 20,
    endIndent: 20,
  );

  Widget _buildActionCard() {
    return Container(
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
      child: Column(
        children: [
          _buildActionTile(
            'User Management',
            Icons.manage_accounts_rounded,
            Colors.blue,
            () {},
          ),
          _buildActionTile(
            'Property Verification',
            Icons.verified_user_rounded,
            Colors.green,
            () {},
          ),
          _buildActionTile(
            'Platform Reports',
            Icons.analytics_rounded,
            Colors.orange,
            () {},
          ),
          _buildActionTile(
            'System Settings',
            Icons.settings_applications_rounded,
            Colors.grey,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
