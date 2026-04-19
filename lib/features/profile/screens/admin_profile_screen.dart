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
      setState(() => _adminProfile = profile);
      await _loadStats();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final supabase = _service.supabaseClient;

      final usersCount = await supabase.from('profiles').count();
      final propertiesCount = await supabase.from('properties').count();

      final sellersRes = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'seller');

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
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Platform Overview'),
                        const SizedBox(height: 16),
                        _buildStatsGrid(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Admin Information'),
                        const SizedBox(height: 12),
                        _buildAdminInfoCard(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Quick Actions'),
                        const SizedBox(height: 12),
                        _buildActionCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ────────────────────── Modern Sliver AppBar ──────────────────────
  Widget _buildSliverAppBar() {
    final name = _adminProfile?['full_name'] ?? 'System Admin';
    final email = _service.currentUser?.email ?? 'admin@estatex.com';
    final avatarUrl = _adminProfile?['avatar_url'] as String?;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      floating: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.maybePop(context),
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
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade900,
                Colors.red.shade700,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Modern Avatar with glow effect
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildAdminAvatar(avatarUrl),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    '🔑 SYSTEM ADMINISTRATOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (_, __, ___) => _defaultAdminIcon(),
      );
    }
    return _defaultAdminIcon();
  }

  Widget _defaultAdminIcon() {
    return Container(
      color: Colors.red.shade800,
      child: const Icon(
        Icons.admin_panel_settings,
        size: 55,
        color: Colors.white,
      ),
    );
  }

  // ────────────────────── Stats Grid (Modern) ──────────────────────
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.45,
      children: [
        _buildStatTile('Total Users', _totalUsers.toString(), Icons.people_alt, Colors.blue.shade600),
        _buildStatTile('Properties', _totalProperties.toString(), Icons.home, Colors.green.shade600),
        _buildStatTile('Active Sellers', _totalSellers.toString(), Icons.storefront, Colors.orange.shade600),
        _buildStatTile('Total Buyers', _totalBuyers.toString(), Icons.person_search, Colors.purple.shade600),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Section Title (Modern)
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: -0.3,
      ),
    );
  }

  // Admin Info Card
  Widget _buildAdminInfoCard() {
    final uid = _service.currentUser?.id ?? 'N/A';
    final email = _service.currentUser?.email ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Admin ID', uid, Icons.fingerprint_rounded),
          _buildDivider(),
          _buildInfoRow('Access Level', 'Root Administrator', Icons.verified_user_rounded),
          _buildDivider(),
          _buildInfoRow('Email Address', email, Icons.email_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.red.shade600, size: 22),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(
        color: Colors.grey.shade100,
        height: 1,
        thickness: 1,
        indent: 20,
        endIndent: 20,
      );

  // Action Card (more premium look)
  Widget _buildActionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile('User Management', Icons.manage_accounts, Colors.blue.shade600, () {}),
          _buildDivider(),
          _buildActionTile('Property Verification', Icons.verified, Colors.green.shade600, () {}),
          _buildDivider(),
          _buildActionTile('Platform Reports', Icons.analytics, Colors.orange.shade600, () {}),
          _buildDivider(),
          _buildActionTile('System Settings', Icons.settings, Colors.grey.shade700, () {}),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}