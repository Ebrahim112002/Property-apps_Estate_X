import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../services/supabase_service.dart';
import 'Bids_post.dart'; 

class MyBidPropertiesScreen extends StatefulWidget {
  static const String routeName = '/my-bid-properties';

  const MyBidPropertiesScreen({super.key});

  @override
  State<MyBidPropertiesScreen> createState() => _MyBidPropertiesScreenState();
}

class _MyBidPropertiesScreenState extends State<MyBidPropertiesScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> _myBids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyBids();
  }

  Future<void> _fetchMyBids() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.fetchMyBidProperties();
      setState(() => _myBids = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBid(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Auction?"),
        content: Text("Are you sure you want to delete '$title'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabaseService.deleteBidProperty(id);
        _fetchMyBids();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auction Deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bid Properties"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myBids.isEmpty
              ? const Center(child: Text("You haven't posted any auction yet"))
              : RefreshIndicator(
                  onRefresh: _fetchMyBids,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _myBids.length,
                    itemBuilder: (context, index) {
                      final bid = _myBids[index];
                      final imageUrl = (bid['image_urls'] as List?)?.isNotEmpty == true
                          ? bid['image_urls'][0]
                          : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bid['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(bid['location'], style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text("Base: ৳${bid['base_price']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      Text("Current: ৳${bid['current_highest_bid']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.edit),
                                          label: const Text("Edit"),
                                          onPressed: () {
                                            // Edit Logic - পরে করবো
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Edit feature coming soon...")),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          label: const Text("Delete", style: TextStyle(color: Colors.red)),
                                          onPressed: () => _deleteBid(bid['id'], bid['title']),
                                        ),
                                      ),
                                    ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, PostBidPropertyScreen.routeName),
        child: const Icon(Icons.add),
      ),
    );
  }
}