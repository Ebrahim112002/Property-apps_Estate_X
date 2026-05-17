import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../../../services/supabase_service.dart';

class PostBidPropertyScreen extends StatefulWidget {
  static const String routeName = '/post-bid-property';

  const PostBidPropertyScreen({super.key});

  @override
  State<PostBidPropertyScreen> createState() => _PostBidPropertyScreenState();
}

class _PostBidPropertyScreenState extends State<PostBidPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  final _imagePicker = ImagePicker();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _plotSizeController = TextEditingController();
  final _parkingController = TextEditingController();

  String _selectedPropertyType = 'Flat';
  DateTime _endTime = DateTime.now().add(const Duration(days: 7));

  bool _isLoading = false;
  final List<Map<String, dynamic>> _selectedImages = [];

  // ===================== Improved Image Picker =====================
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সর্বোচ্চ ১০টি ছবি আপলোড করা যাবে')),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1200,
        limit: 10 - _selectedImages.length,
      );

      if (pickedFiles.isEmpty) return;

      List<Map<String, dynamic>> newImages = [];
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        newImages.add({'name': file.name, 'bytes': bytes});
      }

      setState(() => _selectedImages.addAll(newImages));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ইমেজ সিলেক্ট করতে সমস্যা: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // ===================== Submit =====================
  Future<void> _submitBidProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অন্তত একটি ছবি আপলোড করুন')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double? basePrice = double.tryParse(
        _basePriceController.text.trim(),
      );
      final double? area = double.tryParse(_areaController.text.trim());

      if (basePrice == null || area == null) {
        throw Exception('Base Price এবং Area সঠিকভাবে দিন');
      }

      final success = await _supabaseService.createBidProperty(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        basePrice: basePrice,
        area: area,
        propertyType: _selectedPropertyType,
        bedrooms: _selectedPropertyType == 'Flat'
            ? (int.tryParse(_bedroomsController.text.trim()) ?? 0)
            : null,
        bathrooms: _selectedPropertyType == 'Flat'
            ? (int.tryParse(_bathroomsController.text.trim()) ?? 0)
            : null,
        plotSize: _selectedPropertyType == 'Land'
            ? double.tryParse(_plotSizeController.text.trim())
            : null,
        parkingSpaces: _selectedPropertyType == 'Commercial'
            ? (int.tryParse(_parkingController.text.trim()) ?? 0)
            : null,
        imageFiles: _selectedImages,
        endTime: _endTime,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Auction Successfully Launched!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectEndTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _endTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _basePriceController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _plotSizeController.dispose();
    _parkingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Launch Premium Auction"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Golden Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFB300),
                            Color(0xFFFF8C00),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.gavel_rounded,
                            size: 72,
                            color: Colors.black87,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "PREMIUM AUCTION",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            "Showcase Your Property to Serious Bidders",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    _buildPremiumTextField(
                      _titleController,
                      'Property Title *',
                      'Enter attractive title',
                    ),
                    const SizedBox(height: 16),

                    _buildPremiumTextField(
                      _locationController,
                      'Location *',
                      'Full address or area',
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Highlight best features...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Property Type
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedPropertyType,
                        decoration: const InputDecoration(
                          labelText: 'Property Type *',
                          border: InputBorder.none,
                        ),
                        items: ['Flat', 'Land', 'Commercial']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPropertyType = val!),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _buildPremiumTextField(
                            _basePriceController,
                            'Base Price (৳) *',
                            'Starting bid amount',
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPremiumTextField(
                            _areaController,
                            'Area (Sq Ft) *',
                            '',
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Conditional Fields
                    if (_selectedPropertyType == 'Flat') ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildPremiumTextField(
                              _bedroomsController,
                              'Bedrooms',
                              '',
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPremiumTextField(
                              _bathroomsController,
                              'Bathrooms',
                              '',
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                    ] else if (_selectedPropertyType == 'Land') ...[
                      _buildPremiumTextField(
                        _plotSizeController,
                        'Plot Size (Katha / Decimal)',
                        '',
                        isNumber: true,
                      ),
                    ] else if (_selectedPropertyType == 'Commercial') ...[
                      _buildPremiumTextField(
                        _parkingController,
                        'Parking Spaces',
                        '',
                        isNumber: true,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Auction End Time
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFFFF8C00),
                          size: 30,
                        ),
                        title: const Text(
                          "Auction Ends On",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMMM yyyy, hh:mm a').format(_endTime),
                        ),
                        trailing: const Icon(
                          Icons.edit_calendar,
                          color: Colors.orange,
                        ),
                        onTap: _selectEndTime,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================== MULTIPLE IMAGE SECTION ====================
                    Text(
                      "Property Images (${_selectedImages.length}/10)",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              height: 130,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 45,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Tap to Select Multiple Images",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Text(
                                    "Max 10 images",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          if (_selectedImages.isNotEmpty)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedImages.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemBuilder: (context, index) {
                                return Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _selectedImages[index]['bytes'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        margin: const EdgeInsets.all(4),
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Text(
                                "No images selected yet",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Launch Button
                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                        ),
                        onPressed: _isLoading ? null : _submitBidProperty,
                        child: const Text(
                          "LAUNCH AUCTION NOW",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPremiumTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (v) => v!.isEmpty && label.contains('*') ? 'Required' : null,
    );
  }
}
