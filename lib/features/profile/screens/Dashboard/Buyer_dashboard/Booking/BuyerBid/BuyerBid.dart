import 'package:flutter/material.dart';
import '../../../../../../../services/supabase_service.dart';
import '../../../../../../home/ALl _properties/Bid_properties/bid_details_screen.dart'; // আপনার ফাইল পাথ অনুযায়ী ইম্পোর্ট করুন

class BuyerBidScreen extends StatefulWidget {
  const BuyerBidScreen({super.key});

  @override
  State<BuyerBidScreen> createState() => _BuyerBidScreenState();
}

class _BuyerBidScreenState extends State<BuyerBidScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _myBids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPlacedBids();
  }

  Future<void> _fetchMyPlacedBids() async {
    setState(() => _isLoading = true);
    try {
      final bids = await _supabaseService.fetchMyBids();
      setState(() {
        _myBids = bids;
      });
    } catch (e) {
      debugPrint('Error fetching my bids: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Participated Bids"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _myBids.isEmpty
              ? const Center(
                  child: Text(
                    "You haven't placed any bids yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchMyPlacedBids,
                  color: Colors.black,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myBids.length,
                    itemBuilder: (context, index) {
                      final bidData = _myBids[index];
                      final property = bidData['bid_properties'] ?? {};
                      final List<dynamic> images = property['image_urls'] ?? [];
                      final String imageUrl = images.isNotEmpty ? images[0] : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Property Image & Status Tag
                              Stack(
                                children: [
                                  imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 160,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image, size: 50),
                                        ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: (property['is_active'] ?? false) ? Colors.green : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (property['is_active'] ?? false) ? "ACTIVE" : "ENDED",
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      property['title'] ?? 'N/A',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      property['location'] ?? 'N/A',
                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text("Your Bid Amount", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            Text(
                                              "৳ ${bidData['bid_amount']}",
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text("Current Highest", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            Text(
                                              "৳ ${property['current_highest_bid']}",
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BidDetailsScreen(bid: property),
                                            ),
                                          ).then((_) => _fetchMyPlacedBids());
                                        },
                                        child: const Text("View Auction Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}