import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  final _service = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _preferredLocationCtrl = TextEditingController();

  // Buyer Specific
  String _preferredType = 'apartment';
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();
  final _bedroomsCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();

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
    final buyerProfile = await _service.getBuyerProfile(uid);

    if (profile != null) {
      _nameCtrl.text = profile['full_name'] ?? '';
      _phoneCtrl.text = profile['phone'] ?? '';
      _cityCtrl.text = profile['city'] ?? '';
      _areaCtrl.text = profile['area'] ?? '';
      _addressCtrl.text = profile['full_address'] ?? '';
      _preferredLocationCtrl.text = profile['preferred_location'] ?? '';
      _avatarUrl = profile['avatar_url'];
      _isActive = profile['is_active'] ?? false;
    }

    if (buyerProfile != null) {
      _preferredType =
          buyerProfile['preferred_property_type'] ?? 'apartment';
      _budgetMinCtrl.text = buyerProfile['budget_min']?.toString() ?? '';
      _budgetMaxCtrl.text = buyerProfile['budget_max']?.toString() ?? '';
      _bedroomsCtrl.text =
          buyerProfile['preferred_bedrooms']?.toString() ?? '';
      _sizeCtrl.text =
          buyerProfile['preferred_size_sqft']?.toString() ?? '';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
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
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final uid = user.id;
      String? newAvatarUrl = _avatarUrl;

      // ── Avatar Upload ──────────────────────────
      if (_pickedImageBytes != null && _pickedImage != null) {
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
        'preferred_location': _preferredLocationCtrl.text.trim(),
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      });

      final buyerData = <String, dynamic>{
        'preferred_property_type': _preferredType,
      };

      final min = double.tryParse(_budgetMinCtrl.text);
      final max = double.tryParse(_budgetMaxCtrl.text);
      final bedrooms = int.tryParse(_bedroomsCtrl.text);
      final size = int.tryParse(_sizeCtrl.text);

      if (min != null) buyerData['budget_min'] = min;
      if (max != null) buyerData['budget_max'] = max;
      if (bedrooms != null) buyerData['preferred_bedrooms'] = bedrooms;
      if (size != null) buyerData['preferred_size_sqft'] = size;

      await _service.upsertBuyerProfile(uid, buyerData);

      if (mounted) {
        setState(() {
          _avatarUrl = newAvatarUrl;
          _pickedImage = null;
          _pickedImageBytes = null;
          _isActive = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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
    _preferredLocationCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    _bedroomsCtrl.dispose();
    _sizeCtrl.dispose();
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
                            _buildField(
                              _preferredLocationCtrl,
                              'Preferred Location',
                              Icons.favorite_border,
                            ),
                          ]),

                          _buildSectionTitle('🏠 Property Preferences'),
                          _buildCard([
                            _buildDropdown(),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    _budgetMinCtrl,
                                    'Budget Min (৳)',
                                    Icons.attach_money,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildField(
                                    _budgetMaxCtrl,
                                    'Budget Max (৳)',
                                    Icons.attach_money,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    _bedroomsCtrl,
                                    'Bedrooms',
                                    Icons.bed_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildField(
                                    _sizeCtrl,
                                    'Size (sqft)',
                                    Icons.square_foot,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
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
      expandedHeight: 270,
      pinned: true,
      backgroundColor: AppColors.primary,
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // ── Avatar with Camera Button ──────
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── FIXED: Avatar সঠিকভাবে দেখাবে ──
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
                      child: ClipOval(
                        child: _buildAvatarImage(),
                      ),
                    ),
                    // Camera icon
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
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🏠 BUYER',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FIXED: Avatar Image Builder ──────────────────────────
  // locally picked bytes → network url → default icon — এই ক্রমে দেখাবে
  Widget _buildAvatarImage() {
    // ১. নতুন pick করা image আছে?
    if (_pickedImageBytes != null) {
      return Image.memory(
        _pickedImageBytes!,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
      );
    }
    // ২. Supabase থেকে আসা URL আছে?
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return Image.network(
        _avatarUrl!,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        // Loading placeholder
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        },
        // Error fallback
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Avatar load error: $error');
          return _defaultAvatarIcon();
        },
      );
    }
    // ৩. কিছু নেই → default icon
    return _defaultAvatarIcon();
  }

  Widget _defaultAvatarIcon() {
    return const Icon(Icons.person, size: 60, color: Colors.white);
  }

  // ─────────────────────────────────────────────────────────
  // OTHER WIDGETS
  // ─────────────────────────────────────────────────────────
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
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _preferredType,
      decoration: InputDecoration(
        labelText: 'Preferred Property Type',
        prefixIcon:
            Icon(Icons.home_work_outlined, color: AppColors.primary),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
        DropdownMenuItem(value: 'house', child: Text('House')),
        DropdownMenuItem(value: 'land', child: Text('Land')),
      ],
      onChanged: (v) => setState(() => _preferredType = v!),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
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