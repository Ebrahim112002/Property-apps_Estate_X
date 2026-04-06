import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/supabase_service.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final _service = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // ── Basic Info Controllers ──
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // ── Seller Specific ──
  String _sellerType = 'owner';
  final _companyCtrl = TextEditingController();

  // ── Read-only stats ──
  int _totalListings = 0;
  int _activeListings = 0;
  int _soldProperties = 0;
  double _rating = 0.0;

  String? _avatarUrl;
  File? _pickedImage;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _service.currentUser?.id;
    if (uid == null) return;

    final profile = await _service.getProfile(uid);
    final sellerProfile = await _service.getSellerProfile(uid);

    if (profile != null) {
      _nameCtrl.text = profile['full_name'] ?? '';
      _phoneCtrl.text = profile['phone'] ?? '';
      _cityCtrl.text = profile['city'] ?? '';
      _areaCtrl.text = profile['area'] ?? '';
      _addressCtrl.text = profile['full_address'] ?? '';
      _avatarUrl = profile['avatar_url'];
      _isActive = profile['is_active'] ?? false;
    }

    if (sellerProfile != null) {
      _sellerType = sellerProfile['seller_type'] ?? 'owner';
      _companyCtrl.text = sellerProfile['company_name'] ?? '';
      _totalListings = sellerProfile['total_listings'] ?? 0;
      _activeListings = sellerProfile['active_listings'] ?? 0;
      _soldProperties = sellerProfile['sold_properties'] ?? 0;
      _rating = (sellerProfile['average_rating'] ?? 0.0).toDouble();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _service.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = user.id;

      if (_pickedImage != null) {
        try {
          _avatarUrl = await _service.uploadAvatar(uid, _pickedImage!);
        } catch (e) {
          // Avatar upload failed, but continue with profile save
          debugPrint('Avatar upload failed: $e');
        }
      }

      await _service.updateProfile(uid, {
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'full_address': _addressCtrl.text.trim(),
        if (_avatarUrl != null) 'avatar_url': _avatarUrl,
      });

      await _service.upsertSellerProfile(uid, {
        'seller_type': _sellerType,
        'company_name': _companyCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isActive = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

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
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isActive) _buildWarningBanner(),
                          const SizedBox(height: 20),

                          // Stats cards
                          _buildStatsRow(),
                          const SizedBox(height: 20),

                          _buildSectionTitle('📋 Basic Information'),
                          _buildCard([
                            _buildField(
                              _nameCtrl,
                              'Full Name',
                              Icons.person_outline,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            _buildField(
                              _phoneCtrl,
                              'Phone Number',
                              Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ]),

                          _buildSectionTitle('📍 Location'),
                          _buildCard([
                            _buildField(
                              _cityCtrl,
                              'City',
                              Icons.location_city_outlined,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            _buildField(_areaCtrl, 'Area', Icons.map_outlined),
                            _buildField(
                              _addressCtrl,
                              'Full Address',
                              Icons.home_outlined,
                              maxLines: 2,
                            ),
                          ]),

                          _buildSectionTitle('🏢 Seller Information'),
                          _buildCard([
                            _buildSellerTypeDropdown(),
                            _buildField(
                              _companyCtrl,
                              'Company Name (Optional)',
                              Icons.business_outlined,
                            ),
                          ]),

                          const SizedBox(height: 30),
                          _buildSaveButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ──────────────────────────────────────────
  // WIDGETS
  // ──────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.deepPurple,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white24,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!) as ImageProvider
                            : (_avatarUrl != null
                                  ? NetworkImage(_avatarUrl!)
                                  : null),
                        child: (_pickedImage == null && _avatarUrl == null)
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _nameCtrl.text.isEmpty ? 'Your Name' : _nameCtrl.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Rating stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < _rating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_rating.toStringAsFixed(1)} • SELLER',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          'Total',
          _totalListings.toString(),
          Icons.list_alt,
          Colors.blue,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          'Active',
          _activeListings.toString(),
          Icons.check_circle_outline,
          Colors.green,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          'Sold',
          _soldProperties.toString(),
          Icons.handshake_outlined,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Profile incomplete! Fill in your name, phone & city to activate your account.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children
            .map(
              (w) =>
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: w),
            )
            .toList(),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSellerTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _sellerType,
      decoration: InputDecoration(
        labelText: 'Seller Type',
        prefixIcon: const Icon(
          Icons.business_center_outlined,
          color: Colors.deepPurple,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'owner', child: Text('Owner')),
        DropdownMenuItem(value: 'agent', child: Text('Agent')),
        DropdownMenuItem(value: 'developer', child: Text('Developer')),
      ],
      onChanged: (v) => setState(() => _sellerType = v!),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
