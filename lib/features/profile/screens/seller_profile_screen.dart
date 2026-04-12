import 'dart:typed_data';
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
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isActive = false;

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

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (mounted) {
        setState(() {
          _pickedImage = picked;
          _pickedImageBytes = bytes;
        });
      }
    }
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
      String? newAvatarUrl = _avatarUrl;

      // ── Avatar Upload ──────────────────────────
      if (_pickedImage != null && _pickedImageBytes != null) {
        try {
          newAvatarUrl = await _service.uploadAvatar(
            uid,
            _pickedImage!.name,
            _pickedImageBytes!,
          );
        } catch (e) {
          debugPrint('Avatar upload failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Avatar upload failed: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // ── Update Profiles ────────────────────────
      await _service.updateProfile(uid, {
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'full_address': _addressCtrl.text.trim(),
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
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
        setState(() {
          _avatarUrl = newAvatarUrl;
          _pickedImage = null;
          _pickedImageBytes = null;
          _isActive = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
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

                          _buildStatsRow(),
                          const SizedBox(height: 20),

                          _buildSectionTitle('📋 Basic Information'),
                          _buildCard([
                            _buildField(
                              _nameCtrl,
                              'Full Name',
                              Icons.person_outline,
                              validator: (v) =>
                                  v!.isEmpty ? 'Required' : null,
                            ),
                            _buildField(
                              _phoneCtrl,
                              'Phone Number',
                              Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  v!.isEmpty ? 'Required' : null,
                            ),
                          ]),

                          _buildSectionTitle('📍 Location'),
                          _buildCard([
                            _buildField(
                              _cityCtrl,
                              'City',
                              Icons.location_city_outlined,
                              validator: (v) =>
                                  v!.isEmpty ? 'Required' : null,
                            ),
                            _buildField(
                                _areaCtrl, 'Area', Icons.map_outlined),
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

  // ─────────────────────────────────────────────────────────
  // SLIVER APP BAR — Avatar সহ সঠিকভাবে
  // ─────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      backgroundColor: Colors.deepPurple,
      // ── Back Button ──────────────────────────
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            await _service.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/profile');
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4527A0), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // ── FIXED: Avatar ──────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        color: Colors.white24,
                      ),
                      child: ClipOval(child: _buildAvatarImage()),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
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
                _nameCtrl.text.isNotEmpty
                    ? _nameCtrl.text
                    : 'Seller Name',
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
                      i < _rating.round()
                          ? Icons.star
                          : Icons.star_border,
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
        ),
      ),
    );
  }

  // ── FIXED: Avatar Image Builder ──────────────────────────
  Widget _buildAvatarImage() {
    if (_pickedImageBytes != null) {
      return Image.memory(
        _pickedImageBytes!,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
      );
    }
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return Image.network(
        _avatarUrl!,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Avatar load error: $error');
          return _defaultAvatarIcon();
        },
      );
    }
    return _defaultAvatarIcon();
  }

  Widget _defaultAvatarIcon() {
    return const Icon(Icons.person, size: 60, color: Colors.white);
  }

  // ─────────────────────────────────────────────────────────
  // OTHER WIDGETS
  // ─────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Total', _totalListings.toString(),
            Icons.list_alt, Colors.blue),
        const SizedBox(width: 10),
        _buildStatCard('Active', _activeListings.toString(),
            Icons.check_circle_outline, Colors.green),
        const SizedBox(width: 10),
        _buildStatCard('Sold', _soldProperties.toString(),
            Icons.handshake_outlined, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
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
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
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
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: w,
              ),
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
        prefixIcon: const Icon(Icons.edit_outlined, color: Colors.deepPurple),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.deepPurple, width: 1.5),
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