import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart';

class AdminManagePropertiesScreen extends StatefulWidget {
  const AdminManagePropertiesScreen({super.key});

  @override
  State<AdminManagePropertiesScreen> createState() => _AdminManagePropertiesScreenState();
}

class _AdminManagePropertiesScreenState extends State<AdminManagePropertiesScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> properties = [];
  bool _isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAllProperties();
      setState(() {
        properties = data;
      });
    } catch (e) {
      debugPrint('Error loading properties: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 100% Safe Data Extractor: টাইপ কাস্টিং ক্র্যাশ প্রতিরোধ করার জন্য
  Map<String, dynamic>? _extractSeller(dynamic profileData) {
    if (profileData == null) return null;
    if (profileData is List && profileData.isNotEmpty) {
      if (profileData.first is Map) {
        return Map<String, dynamic>.from(profileData.first as Map);
      }
    }
    if (profileData is Map<String, dynamic>) {
      return profileData;
    }
    return null;
  }

  // MODAL DETAILED VIEW: সম্পূর্ণ ক্র্যাশ-প্রুফ লেআউট উইডথ কন্ট্রোলসহ
  void _showDetailsDialog(Map<String, dynamic> p) {
    final seller = _extractSeller(p['profiles']);
    final sellerName = seller != null ? (seller['full_name'] ?? 'N/A') : 'N/A';
    final sellerEmail = seller != null ? (seller['email'] ?? 'N/A') : 'N/A';
    final sellerRole = seller != null ? (seller['role'] ?? 'buyer') : 'buyer';
    final sellerAvatar = seller != null ? seller['avatar_url'] : null;

    final List<dynamic> rawImages = p['image_urls'] is List ? p['image_urls'] : [];
    final String? firstImageUrl = rawImages.isNotEmpty ? rawImages.first.toString() : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          p['title'] ?? 'Details Overview', 
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85, // উইডথ লিমিট করে সাইজ এরর দূর করা হয়েছে
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Safe Image Handler with fallback
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: firstImageUrl != null && firstImageUrl.isNotEmpty
                      ? Image.network(
                          firstImageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.home, size: 50, color: Colors.grey),
                        ),
                ),
                const SizedBox(height: 12),
                Text("🆔 Property ID: ${p['id']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const Divider(),
                Text("📍 Location: ${p['location'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                Text("💰 Price: ৳${p['price'] ?? '0'}", style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
                Text("🏢 Type: ${p['property_type'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                const Divider(),
                
                // Seller Profile Section inside Dialog
                const Text("👤 Posted By (Seller Profile):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.blue[50],
                      backgroundImage: sellerAvatar != null && sellerAvatar.toString().isNotEmpty 
                          ? NetworkImage(sellerAvatar.toString()) 
                          : null,
                      child: sellerAvatar == null ? const Icon(Icons.person, color: Colors.blue) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(sellerEmail, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              sellerRole.toString().toUpperCase(), 
                              style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(p['description'] ?? 'No description provided.', style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }

  // MODAL FORM: Add / Edit Property Functionality
  void _showPropertyFormDialog({Map<String, dynamic>? property}) {
    final isEdit = property != null;
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(text: isEdit ? property['title'] : '');
    final locationController = TextEditingController(text: isEdit ? property['location'] : '');
    final priceController = TextEditingController(text: isEdit ? property['price']?.toString() : '');
    final descController = TextEditingController(text: isEdit ? property['description'] : '');
    
    final List<dynamic> propertyImages = isEdit && property['image_urls'] is List ? property['image_urls'] : [];
    final imageUrlController = TextEditingController(text: propertyImages.isNotEmpty ? propertyImages.first.toString() : '');
    String selectedType = (isEdit ? property['property_type'] : 'Flat') ?? 'Flat';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Edit Property Data" : "Add New Property"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Property Title*"),
                      validator: (v) => v!.isEmpty ? "Field Required" : null,
                    ),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: "Location/Area*"),
                      validator: (v) => v!.isEmpty ? "Field Required" : null,
                    ),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Price (৳)*"),
                      validator: (v) => v!.isEmpty ? "Field Required" : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: "Property Type"),
                      items: ['Flat', 'Commercial', 'Land'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedType = val!),
                    ),
                    TextFormField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: "Sample Image URL"),
                    ),
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context);
                setState(() => _isLoading = true);

                final List<String> images = imageUrlController.text.isNotEmpty ? [imageUrlController.text] : [];
                final payload = {
                  'title': titleController.text,
                  'location': locationController.text,
                  'price': double.parse(priceController.text),
                  'property_type': selectedType,
                  'description': descController.text,
                  'image_urls': images,
                  'seller_id': isEdit ? property['seller_id'] : _supabaseService.currentUser?.id,
                };

                bool success;
                if (isEdit) {
                  success = await _supabaseService.updatePropertyAdmin(property['id'].toString(), payload);
                } else {
                  success = await _supabaseService.createPropertyAdmin(payload);
                }

                if (success) _fetchProperties();
              },
              child: Text(isEdit ? "Update" : "Save"),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProperty(String propertyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Property?"),
        content: const Text("This action cannot be undone and will clear the listing data."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _supabaseService.deleteProperty(propertyId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Property deleted successfully"), backgroundColor: Colors.green),
      );
      _fetchProperties();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = properties.where((p) {
      final title = (p['title'] ?? '').toLowerCase();
      final location = (p['location'] ?? '').toLowerCase();
      final type = (p['property_type'] ?? '').toLowerCase();
      final seller = _extractSeller(p['profiles']);
      final sellerName = seller != null ? (seller['full_name'] ?? '').toLowerCase() : '';
      final sellerEmail = seller != null ? (seller['email'] ?? '').toLowerCase() : '';
      
      final query = searchQuery.toLowerCase();
      return title.contains(query) || location.contains(query) || type.contains(query) || sellerName.contains(query) || sellerEmail.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Manage Properties", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Filter by title, area, owner name, or email...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text("No properties matched."))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final List<dynamic> imageUrls = p['image_urls'] is List ? p['image_urls'] : [];
                          
                          final seller = _extractSeller(p['profiles']);
                          final sellerName = seller != null ? (seller['full_name'] ?? 'Unknown Seller') : 'Unknown Seller';
                          final sellerEmail = seller != null ? (seller['email'] ?? 'No Email') : 'No Email';
                          final sellerRole = seller != null ? (seller['role'] ?? 'buyer') : 'buyer';
                          final sellerAvatar = seller != null ? seller['avatar_url'] : null;

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: imageUrls.isNotEmpty && imageUrls.first.toString().isNotEmpty
                                        ? Image.network(
                                            imageUrls.first.toString(), 
                                            height: 60, 
                                            width: 60, 
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              height: 60, width: 60, color: Colors.grey[300], 
                                              child: const Icon(Icons.broken_image, size: 20)
                                            ),
                                          )
                                        : Container(height: 60, width: 60, color: Colors.grey[300], child: const Icon(Icons.home)),
                                  ),
                                  title: Text(
                                    p['title'] ?? 'No Title', 
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("📍 ${p['location'] ?? ''}", maxLines: 1),
                                      Text("💰 ৳${p['price'] ?? '0'}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.visibility, color: Colors.blueGrey), onPressed: () => _showDetailsDialog(p)),
                                      IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showPropertyFormDialog(property: p)),
                                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProperty(p['id'].toString())),
                                    ],
                                  ),
                                ),
                                
                                // Card-এর নিচের ইনফো ব্যানার (Avatar, Name, Email, Role সহ)
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[50],
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.blueGrey[200],
                                        backgroundImage: sellerAvatar != null && sellerAvatar.toString().isNotEmpty 
                                            ? NetworkImage(sellerAvatar.toString()) 
                                            : null,
                                        child: sellerAvatar == null ? const Icon(Icons.person, size: 14, color: Colors.white) : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                                            children: [
                                              const TextSpan(text: "Post By: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                              TextSpan(text: "$sellerName "),
                                              TextSpan(text: "($sellerEmail) ", style: TextStyle(color: Colors.grey[700])),
                                              TextSpan(
                                                text: "[${sellerRole.toString().toUpperCase()}]", 
                                                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}