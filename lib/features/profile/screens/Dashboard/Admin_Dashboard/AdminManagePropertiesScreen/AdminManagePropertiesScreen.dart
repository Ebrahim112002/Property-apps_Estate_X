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
        debugPrint("✅ Fetched ${data.length} properties");
      });
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProperty(String propertyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Property?"),
        content: const Text("This action cannot be undone."),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Properties")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : properties.isEmpty
              ? const Center(child: Text("No properties found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final p = properties[index];
                    final imageUrls = p['image_urls'] as List? ?? [];

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: imageUrls.isNotEmpty
                                ? Image.network(imageUrls.first, height: 180, width: double.infinity, fit: BoxFit.cover)
                                : Container(height: 180, color: Colors.grey[300], child: const Icon(Icons.home, size: 80)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['title'] ?? 'No Title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text("📍 ${p['location'] ?? ''}"),
                                      Text("💰 ৳${p['price'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                  onPressed: () => _deleteProperty(p['id'].toString()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}