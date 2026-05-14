import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../models/property_model.dart';

// =========================================================================
// ১. UI SCREEN WIDGET   =============
class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postService = PostPropertyService();

  // কন্ট্রোলারস
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  // ড্রপডাউন এবং স্টেট ভেরিয়েবলস
  String _selectedPropertyType = 'Flat'; // Flat, Land, Commercial
  String _selectedListingType = 'Rent';   // Rent, Sale
  bool _isLoading = false;

  // ডামি ইমেজ ডাটা স্ট্রাকচার (ইমেজের মাল্টিপল সিলেকশন সিমুলেট করার জন্য)
  // আপনার আসল ইমেজ পিকার (যেমন image_picker বা file_picker) দিয়ে এই লিস্টে ডাটা পুশ করবেন
  final List<Map<String, dynamic>> _selectedImageFiles = []; 

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  // ডাটা সাবমিট করার মেথড
  Future<void> _submitProperty(String currentListingType) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double price = double.parse(_priceController.text.trim());
      final double area = double.parse(_areaController.text.trim());
      final int bedrooms = _selectedPropertyType.toLowerCase() == 'land' 
          ? 0 
          : int.tryParse(_bedroomsController.text.trim()) ?? 0;
      final int bathrooms = _selectedPropertyType.toLowerCase() == 'land' 
          ? 0 
          : int.tryParse(_bathroomsController.text.trim()) ?? 0;

      // ব্যাকএন্ড সার্ভিস কল
      final success = await _postService.createPropertyListing(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        price: price,
        area: area,
        propertyType: _selectedPropertyType,
        listingType: currentListingType, // বাটন থেকে আসা টাইপ (Normal/Auction/Rent/Sale)
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        imageFiles: _selectedImageFiles,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ প্রোপার্টি সফলভাবে পোস্ট করা হয়েছে!')),
        );
        Navigator.pop(context); // আগের স্ক্রিনে ব্যাক করবে
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ এরর: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // dashboard_card.dart এর বাটন থেকে পাঠানো Arguments রিসিভ করা হচ্ছে ('Normal' নাকি 'Auction')
    final String incomingActionType = ModalRoute.of(context)?.settings.arguments as String? ?? 'Normal';
    
    // যদি অকশন বাটন থেকে আসে, লিস্টিং টাইপ 'Auction' লক করে দেব, অন্যথায় ড্রপডাউন থেকে নেবে
    final String finalListingType = incomingActionType == 'Auction' ? 'Auction' : _selectedListingType;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(incomingActionType == 'Auction' ? "Add Auction Property" : "Add New Property"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // টাইটেল
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Property Title *', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'টাইটেল দিন' : null,
                  ),
                  const SizedBox(height: 16),

                  // লোকেশন
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location / Address *', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'লোকেশন দিন' : null,
                  ),
                  const SizedBox(height: 16),

                  // প্রোপার্টি টাইপ ড্রপডাউন (Flat, Land, Commercial)
                  DropdownButtonFormField<String>(
                    value: _selectedPropertyType,
                    decoration: const InputDecoration(labelText: 'Property Type', border: OutlineInputBorder()),
                    items: ['Flat', 'Land', 'Commercial'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPropertyType = val ?? 'Flat'),
                  ),
                  const SizedBox(height: 16),

                  // লিস্টিং টাইপ (যদি অকশন না হয়, তবে Rent/Sale ড্রপডাউন দেখাবে)
                  if (incomingActionType != 'Auction') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedListingType,
                      decoration: const InputDecoration(labelText: 'Listing Type', border: OutlineInputBorder()),
                      items: ['Rent', 'Sale'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedListingType = val ?? 'Rent'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // প্রাইস এবং এরিয়া (পাশাপাশি দুটি ফিল্ড)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: incomingActionType == 'Auction' ? 'Base Price (৳) *' : 'Price (৳) *', border: const OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'মূল্য দিন' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _areaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Area (Sq Ft) *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'আয়তন দিন' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // বেডরুম এবং বাথরুম (ল্যান্ড বা জমি হলে এই ফিল্ডগুলো হাইড থাকবে)
                  if (_selectedPropertyType.toLowerCase() != 'land') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bedroomsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Bedrooms', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _bathroomsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Bathrooms', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ইমেজ সেকশন কন্টেইনার (এখানে আপনার ইমেজ পিকার উইজেট বসাতে পারবেন)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.collections_outlined, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            // এখানে ইমেজ পিক করার লজিক ট্র্রিগার করবেন
                            // যেমন: _selectedImageFiles.add({'name': 'file.jpg', 'bytes': Uint8List});
                          },
                          child: const Text("Upload Multiple Images"),
                        ),
                        Text("${_selectedImageFiles.length} images selected", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // সাবমিট বাটন
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _submitProperty(finalListingType),
                      child: Text(incomingActionType == 'Auction' ? "Launch Auction" : "Post Property Now"),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// =========================================================================
// ২. BACKEND SERVICE CLASS (ডাটাবেজ ও স্টোরেজ প্রসেসিং)
// =========================================================================
class PostPropertyService {
  final _supabase = Supabase.instance.client;

  /// মাল্টিপল ইমেজ Supabase Storage-এ আপলোড করার মেথড
  Future<List<String>> _uploadPropertyImages(String userId, List<Map<String, dynamic>> selectedImages) async {
    List<String> uploadedUrls = [];
    final supabaseUrl = 'https://hxkokgzbeqmfdkzzeuex.supabase.co';

    if (selectedImages.isEmpty) return uploadedUrls;

    for (var image in selectedImages) {
      try {
        final String fileName = image['name'] ?? 'image.jpg';
        final Uint8List bytes = image['bytes'];
        
        final parts = fileName.split('.');
        final ext = parts.length < 2 ? 'jpg' : parts.last.toLowerCase();
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final randomOffset = bytes.length; 
        final storagePath = '$userId/${timestamp}_$randomOffset.$ext';

        // 'property_images' নামক স্টোরেজ বাল্কে বাইনারি আপলোড
        await _supabase.storage.from('property_images').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
        );

        final publicUrl = '$supabaseUrl/storage/v1/object/public/property_images/$storagePath';
        uploadedUrls.add(publicUrl);
      } catch (e) {
        debugPrint('❌ ইন্ডিভিজুয়াল ইমেজ আপলোড ব্যর্থ: $e');
      }
    }
    return uploadedUrls;
  }

  /// সম্পূর্ণ প্রোপার্টি পোস্ট করার মেইন মেথড (শুধুমাত্র সেলারদের জন্য)
  Future<bool> createPropertyListing({
    required String title,
    required String location,
    required double price,
    required double area,
    required String propertyType, 
    required String listingType,  
    required int bedrooms,
    required int bathrooms,
    required List<Map<String, dynamic>> imageFiles, 
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('ইউজার লগইন করা নেই।');

      // ১. সিকিউরিটি চেক: ইউজার আসলেই সেলার কিনা ডাটাবেজ থেকে ভেরিফাই করা
      final profileData = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (profileData['role'] != 'seller') {
        throw Exception('অনুমতি নেই! শুধুমাত্র সেলার অ্যাকাউন্ট থেকে প্রোপার্টি পোস্ট করা সম্ভব।');
      }

      // ২. ইমেজগুলো স্টোরেজে আপলোড করে পাবলিক লিংক নিয়ে আসা
      debugPrint('⏳ ইমেজ আপলোড হচ্ছে...');
      List<String> imageUrls = await _uploadPropertyImages(user.id, imageFiles);

      // ৩. মডেল অবজেক্ট তৈরি করা
      final newProperty = Property(
        id: '', // ডাটাবেজ অটো-জেনারেট করবে
        sellerId: user.id,
        title: title,
        location: location,
        price: price,
        imageUrls: imageUrls,
        propertyType: propertyType,
        listingType: listingType,
        bedrooms: propertyType.toLowerCase() == 'land' ? 0 : bedrooms, 
        bathrooms: propertyType.toLowerCase() == 'land' ? 0 : bathrooms,
        area: area,
        isVerified: false, 
        createdAt: DateTime.now(),
      );

      // ৪. ডাটা ম্যাপ তৈরি ও আইডি রিমুভ করা যেন কোনো প্রাইমারি কি এরর না আসে
      final propertyData = newProperty.toJson();
      propertyData.remove('id'); 

      debugPrint('⏳ ডাটাবেজে প্রোপার্টি সেভ হচ্ছে...');
      await _supabase.from('properties').insert(propertyData);
      
      debugPrint('✅ প্রোপার্টি সফলভাবে পোস্ট হয়েছে!');
      return true;
    } catch (e) {
      debugPrint('❌ প্রোপার্টি পোস্ট করতে সমস্যা হয়েছে: $e');
      rethrow;
    }
  }
}