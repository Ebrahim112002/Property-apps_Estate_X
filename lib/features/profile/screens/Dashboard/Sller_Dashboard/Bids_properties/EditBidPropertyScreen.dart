import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../services/supabase_service.dart';

class EditBidPropertyScreen extends StatefulWidget {
  final dynamic bid;

  const EditBidPropertyScreen({super.key, required this.bid});

  @override
  State<EditBidPropertyScreen> createState() => _EditBidPropertyScreenState();
}

class _EditBidPropertyScreenState extends State<EditBidPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  final _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _basePriceController;
  late TextEditingController _descriptionController;

  List<Map<String, dynamic>> _newImages = []; // নতুন যোগ করা ছবি
  List<dynamic> _existingImages = []; // আগের ছবি
  List<dynamic> _removedImageUrls = []; // যেগুলো ডিলিট করবে

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bid['title']);
    _locationController = TextEditingController(text: widget.bid['location']);
    _basePriceController = TextEditingController(
      text: widget.bid['base_price'].toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.bid['description'] ?? '',
    );

    _existingImages = List.from(widget.bid['image_urls'] ?? []);
  }

  Future<void> _pickNewImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (pickedFiles.isEmpty) return;

      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        _newImages.add({'name': file.name, 'bytes': bytes});
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image pick error: $e')));
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _removedImageUrls.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  Future<void> _updateBid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<String> allImageUrls = List.from(_existingImages);

      // নতুন ছবি আপলোড
      if (_newImages.isNotEmpty) {
        final newUrls = await _supabaseService.uploadBidPropertyImages(
          Supabase.instance.client.auth.currentUser!.id,
          _newImages,
        );
        allImageUrls.addAll(newUrls);
      }

      final success = await _supabaseService.updateBidProperty(
        id: widget.bid['id'],
        data: {
          'title': _titleController.text.trim(),
          'location': _locationController.text.trim(),
          'base_price': double.parse(_basePriceController.text.trim()),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'image_urls': allImageUrls,
        },
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Successfully Updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Refresh করার জন্য true পাঠানো হলো
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Auction"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
                        labelText: "Title *",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: "Location *",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _basePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Base Price (৳) *",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Existing Images
                    if (_existingImages.isNotEmpty) ...[
                      const Text(
                        "Existing Images",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(_existingImages.length, (
                          index,
                        ) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _existingImages[index],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -5,
                                right: -5,
                                child: GestureDetector(
                                  onTap: () => _removeExistingImage(index),
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
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // New Images
                    const Text(
                      "Add New Images",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickNewImages,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text("Tap to Add New Images"),
                        ),
                      ),
                    ),

                    if (_newImages.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        children: List.generate(_newImages.length, (index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _newImages[index]['bytes'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -5,
                                right: -5,
                                child: GestureDetector(
                                  onTap: () => _removeNewImage(index),
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
                              ),
                            ],
                          );
                        }),
                      ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _updateBid,
                        child: const Text(
                          "Update Auction",
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
}
