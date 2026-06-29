import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart';

class AdminManageBidsScreen extends StatefulWidget {
  const AdminManageBidsScreen({super.key});

  @override
  State<AdminManageBidsScreen> createState() => _AdminManageBidsScreenState();
}

class _AdminManageBidsScreenState extends State<AdminManageBidsScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> bidProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _supabaseService.getAllBidProperties();
    setState(() {
      bidProperties = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Auctions")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : bidProperties.isEmpty
              ? const Center(child: Text("No bid properties found"))
              : ListView.builder(
                  itemCount: bidProperties.length,
                  itemBuilder: (context, index) {
                    final p = bidProperties[index];
                    final seller = p['profiles'] ?? {};
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: p['image_urls'] != null && (p['image_urls'] as List).isNotEmpty
                            ? Image.network((p['image_urls'] as List).first, width: 70, height: 70, fit: BoxFit.cover)
                            : const Icon(Icons.gavel, size: 50),
                        title: Text(p['title'] ?? 'No Title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Seller: ${seller['full_name'] ?? 'Unknown'}"),
                            Text("Highest Bid: ৳${p['current_highest_bid']}"),
                            Text("Status: ${p['is_active'] == true ? 'Active' : 'Closed'}"),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(p['is_active'] == true ? "LIVE" : "ENDED"),
                          backgroundColor: p['is_active'] == true ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}