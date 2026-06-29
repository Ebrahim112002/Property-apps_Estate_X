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
    _fetchBidProperties();
  }

  Future<void> _fetchBidProperties() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAllBidProperties();
      setState(() {
        bidProperties = data;
      });
    } catch (e) {
      debugPrint('Error fetching bids: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
                  padding: const EdgeInsets.all(12),
                  itemCount: bidProperties.length,
                  itemBuilder: (context, index) {
                    final p = bidProperties[index];
                    final seller = p['profiles'] ?? {};
                    final imageUrls = p['image_urls'] as List? ?? [];

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: imageUrls.isNotEmpty
                                ? Image.network(imageUrls.first, height: 160, width: double.infinity, fit: BoxFit.cover)
                                : Container(height: 160, color: Colors.grey[300], child: const Icon(Icons.gavel, size: 60)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['title'] ?? 'No Title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Seller: ${seller['full_name'] ?? 'Unknown'}"),
                                Text("Highest Bid: ৳${p['current_highest_bid'] ?? '0'}"),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text(p['is_active'] == true ? "ACTIVE" : "CLOSED"),
                                  backgroundColor: p['is_active'] == true ? Colors.green : Colors.grey,
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