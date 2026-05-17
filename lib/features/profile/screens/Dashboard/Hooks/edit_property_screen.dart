import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../services/supabase_service.dart';

class EditPropertyScreen extends StatefulWidget {
  final dynamic property;
  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _areaController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _plotSizeController;
  late TextEditingController _parkingController;

  String _selectedPropertyType = 'Flat';
  String _selectedListingType = 'Sale';
  bool _isLoading = false;

  List<String> _existingImageUrls = [];
  List<Map<String, dynamic>> _newImageFiles = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.property['title'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.property['location'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.property['price']?.toString() ?? '',
    );
    _areaController = TextEditingController(
      text: widget.property['area']?.toString() ?? '',
    );

    _selectedPropertyType = widget.property['property_type'] ?? 'Flat';
    _selectedListingType = widget.property['listing_type'] ?? 'Sale';

    _bedroomsController = TextEditingController(
      text: (widget.property['bedrooms'] ?? 0).toString(),
    );
    _bathroomsController = TextEditingController(
      text: (widget.property['bathrooms'] ?? 0).toString(),
    );
    _plotSizeController = TextEditingController(
      text: (widget.property['plot_size'] ?? '').toString(),
    );
    _parkingController = TextEditingController(
      text: (widget.property['parking_spaces'] ?? 0).toString(),
    );

    _existingImageUrls = List<String>.from(widget.property['image_urls'] ?? []);
  }

  Future<void> _pickNewImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (pickedFiles.isEmpty) return;

    List<Map<String, dynamic>> newImages = [];
    for (var file in pickedFiles) {
      final bytes = await file.readAsBytes();
      newImages.add({'name': file.name, 'bytes': bytes});
    }
    setState(() => _newImageFiles.addAll(newImages));
  }

  Future<void> _updateProperty() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint("🔄 Starting update...");

      List<String> allImageUrls = List<String>.from(_existingImageUrls);

      // নতুন ইমেজ আপলোড
      if (_newImageFiles.isNotEmpty) {
        debugPrint("📸 Uploading ${_newImageFiles.length} new images...");
        final service = SupabaseService();
        final newUrls = await service.uploadPropertyImages(
          _supabase.auth.currentUser!.id,
          _newImageFiles,
        );
        allImageUrls.addAll(newUrls);
        debugPrint("✅ New images uploaded: ${newUrls.length}");
      }

      final data = {
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'area': double.parse(_areaController.text.trim()),
        'property_type': _selectedPropertyType,
        'listing_type': _selectedListingType,
        'bedrooms': _selectedPropertyType == 'Flat'
            ? int.tryParse(_bedroomsController.text.trim()) ?? 0
            : null,
        'bathrooms': _selectedPropertyType == 'Flat'
            ? int.tryParse(_bathroomsController.text.trim()) ?? 0
            : null,
        'plot_size': _selectedPropertyType == 'Land'
            ? double.tryParse(_plotSizeController.text.trim())
            : null,
        'parking_spaces': _selectedPropertyType == 'Commercial'
            ? int.tryParse(_parkingController.text.trim())
            : null,
        'image_urls': allImageUrls,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint("📤 Updating with data: $data");

      final response = await _supabase
          .from('properties')
          .update(data)
          .eq('id', widget.property['id'])
          .select();

      debugPrint("✅ Update Response: $response");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Property Updated Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      debugPrint("❌ Update Error: $e");
      debugPrint("Stack: $stack");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update Failed: ${e.toString()}"),
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
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Property")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
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

                    DropdownButtonFormField<String>(
                      value: _selectedListingType,
                      decoration: const InputDecoration(
                        labelText: 'Listing Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Rent', 'Sale', 'Auction']
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
                            decoration: const InputDecoration(
                              labelText: 'Price (৳) *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _areaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Area (Sqft) *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
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
                          labelText: 'Plot Size',
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
                          TextButton.icon(
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text("Add New Images"),
                            onPressed: _pickNewImages,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._existingImageUrls.map(
                                (url) => Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(url),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ..._newImageFiles.map(
                                (img) => Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: MemoryImage(img['bytes']),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _newImageFiles.remove(img),
                                      ),
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _updateProperty,
                        child: const Text(
                          "Update Property",
                          style: TextStyle(
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
}
