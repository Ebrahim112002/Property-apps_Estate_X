import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart';
import 'Bids_post.dart';
import 'EditBidPropertyScreen.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBid(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Auction?"),
        content: Text(
          "Are you sure you want to delete '$title'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auction Deleted Successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _editBid(dynamic bid) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditBidPropertyScreen(bid: bid)),
    ).then((value) {
      if (value == true) _fetchMyBids(); // Refresh after edit
    });
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
          ? const Center(
              child: Text(
                "You haven't posted any auction yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchMyBids,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _myBids.length,
                itemBuilder: (context, index) {
                  final bid = _myBids[index];
                  final List<dynamic> images = bid['image_urls'] ?? [];
                  final bool isActive = bid['is_active'] ?? true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Multiple Images with Scroll
                        if (images.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: Stack(
                              children: [
                                PageView.builder(
                                  itemCount: images.length,
                                  itemBuilder: (context, imgIndex) {
                                    return ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        images[imgIndex],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    );
                                  },
                                ),
                                if (images.length > 1)
                                  Positioned(
                                    bottom: 8,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(images.length, (
                                        i,
                                      ) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      bid['title'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isActive ? "Active" : "Ended",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                bid['location'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Details
                              Row(
                                children: [
                                  Text(
                                    "Base: ৳${bid['base_price']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "Current: ৳${bid['current_highest_bid']}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              if (bid['bedrooms'] != null ||
                                  bid['bathrooms'] != null)
                                Text(
                                  "🛏 ${bid['bedrooms'] ?? 0} Bed | 🛁 ${bid['bathrooms'] ?? 0} Bath",
                                ),

                              if (bid['plot_size'] != null)
                                Text("📐 Plot: ${bid['plot_size']} Katha"),

                              if (bid['parking_spaces'] != null)
                                Text("🅿 Parking: ${bid['parking_spaces']}"),

                              const SizedBox(height: 4),
                              Text(
                                "Ends: ${DateTime.parse(bid['end_time']).toString().substring(0, 16)}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.edit, size: 20),
                                      label: const Text("Edit"),
                                      onPressed: () => _editBid(bid),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onPressed: () =>
                                          _deleteBid(bid['id'], bid['title']),
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
        backgroundColor: Colors.black,
        onPressed: () =>
            Navigator.pushNamed(context, PostBidPropertyScreen.routeName),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
