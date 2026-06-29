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
    final data = await _supabaseService.getAllProperties();
    setState(() {
      properties = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Properties")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final p = properties[index];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: (p['image_urls'] != null && (p['image_urls'] as List).isNotEmpty)
                        ? Image.network((p['image_urls'] as List).first, width: 80, fit: BoxFit.cover)
                        : const Icon(Icons.home_work, size: 60),
                    title: Text(p['title'] ?? ''),
                    subtitle: Text("${p['location']} • ৳${p['price']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                          title: const Text("Delete Property?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete")),
                          ],
                        ));
                        if (confirm == true) {
                          await _supabaseService.deleteProperty(p['id']);
                          _fetchProperties();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}