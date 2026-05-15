import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../services/supabase_service.dart';

// ====================== PostPropertyService ======================
class PostPropertyService {
  final _supabase = Supabase.instance.client;
  final SupabaseService _service = SupabaseService();
  Future<List<String>> _uploadPropertyImages(
    String userId,
    List<Map<String, dynamic>> images,
  ) async {
    final service = SupabaseService();
    return await service.uploadPropertyImages(userId, images);
  }

  Future<bool> createPropertyListing({
    required String title,
    required String location,
    required double price,
    required double area,
    required String propertyType,
    required String listingType,
    required int bedrooms,
    required int bathrooms,
    double? plotSize,
    int? parkingSpaces,
    required List<Map<String, dynamic>> imageFiles,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // সেলার রোল চেক
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null || profile['role'] != 'seller') {
        throw Exception('Only sellers can post properties');
      }

      // ইমেজ আপলোড শুরু
      final imageUrls = await _uploadPropertyImages(user.id, imageFiles);

      // ডাটাবেজ ম্যাপ (এখানে 'area' ফিল্ডটি নিশ্চিত করা হয়েছে)
      final data = {
        'seller_id': user.id,
        'title': title,
        'location': location,
        'price': price,
        'area': area,
        'property_type': propertyType,
        'listing_type': listingType,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'plot_size': plotSize,
        'parking_spaces': parkingSpaces,
        'is_verified': false,
        'image_urls': imageUrls, // ডাটাবেজে text array বা jsonb কলাম থাকতে হবে
      };

      await _supabase.from('properties').insert(data);

      debugPrint('✅ Property inserted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Create Property Error: $e');
      rethrow;
    }
  }
}

// ====================== AddPropertyScreen ======================
class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postService = PostPropertyService();
  final _imagePicker = ImagePicker();

  // Controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _plotSizeController = TextEditingController();
  final _parkingController = TextEditingController();

  String _selectedPropertyType = 'Flat';
  String _selectedListingType = 'Rent';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _selectedImageFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _plotSizeController.dispose();
    _parkingController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFiles.isEmpty) return;

      List<Map<String, dynamic>> newImages = [];
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        newImages.add({'name': file.name, 'bytes': bytes});
      }

      setState(() => _selectedImageFiles.addAll(newImages));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ইমেজ সিলেক্ট করতে সমস্যা: $e')));
      }
    }
  }

  Future<void> _submitProperty(String currentListingType) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অন্তত একটি ছবি সিলেক্ট করুন')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double price = double.parse(_priceController.text.trim());
      final double area = double.tryParse(_areaController.text.trim()) ?? 0;

      int bedrooms = 0;
      int bathrooms = 0;
      double? plotSize;
      int? parking;

      if (_selectedPropertyType == 'Flat') {
        bedrooms = int.tryParse(_bedroomsController.text.trim()) ?? 0;
        bathrooms = int.tryParse(_bathroomsController.text.trim()) ?? 0;
      } else if (_selectedPropertyType == 'Land') {
        plotSize = double.tryParse(_plotSizeController.text.trim());
      } else if (_selectedPropertyType == 'Commercial') {
        parking = int.tryParse(_parkingController.text.trim());
      }

      final success = await _postService.createPropertyListing(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        price: price,
        area: area,
        propertyType: _selectedPropertyType,
        listingType: currentListingType,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        plotSize: plotSize,
        parkingSpaces: parking,
        imageFiles: _selectedImageFiles,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 প্রোপার্টি সফলভাবে পোস্ট হয়েছে!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String incomingActionType =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'Normal';
    final String finalListingType = incomingActionType == 'Auction'
        ? 'Auction'
        : _selectedListingType;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          incomingActionType == 'Auction'
              ? "Add Auction Property"
              : "Add New Property",
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
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
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Property Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Title required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Location required' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedPropertyType,
                      decoration: const InputDecoration(
                        labelText: 'Property Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Flat', 'Land', 'Commercial']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedPropertyType = val!),
                    ),
                    const SizedBox(height: 16),

                    if (incomingActionType != 'Auction')
                      DropdownButtonFormField<String>(
                        value: _selectedListingType,
                        decoration: const InputDecoration(
                          labelText: 'Listing Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Rent', 'Sale']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedListingType = val!),
                      ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: incomingActionType == 'Auction'
                                  ? 'Base Price (৳)'
                                  : 'Price (৳) *',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Price required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _areaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Area (Sq Ft) *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Area required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_selectedPropertyType == 'Flat') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bedroomsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Bedrooms',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _bathroomsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Bathrooms',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_selectedPropertyType == 'Land') ...[
                      TextFormField(
                        controller: _plotSizeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Plot Size (Katha / Decimal)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else if (_selectedPropertyType == 'Commercial') ...[
                      TextFormField(
                        controller: _parkingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Parking Spaces',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Image Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.upload_rounded),
                            label: const Text("Select Images"),
                            onPressed: _pickImages,
                          ),
                          const SizedBox(height: 8),
                          if (_selectedImageFiles.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedImageFiles.map((image) {
                                return Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: MemoryImage(image['bytes']),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedImageFiles.remove(image),
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _submitProperty(finalListingType),
                        child: Text(
                          incomingActionType == 'Auction'
                              ? "Launch Auction"
                              : "Post Property",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}
