import 'package:flutter/material.dart';
import '../../../../../services/supabase_service.dart';

class BidDetailsScreen extends StatefulWidget {
  final dynamic bid;

  const BidDetailsScreen({super.key, required this.bid});

  @override
  State<BidDetailsScreen> createState() => _BidDetailsScreenState();
}

class _BidDetailsScreenState extends State<BidDetailsScreen> {
  final _supabaseService = SupabaseService();
  final _bidAmountController = TextEditingController();
  bool _isLoading = false;
  int _currentIndex = 0; // <-- Added for image control

  Future<void> _placeBid() async {
    final bidAmount = double.tryParse(_bidAmountController.text.trim());
    if (bidAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (bidAmount <= widget.bid['current_highest_bid']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid must be higher than current highest bid'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _supabaseService.placeBid(
        bidPropertyId: widget.bid['id'],
        bidAmount: bidAmount,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Bid Placed Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _bidAmountController.clear();
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
    final bid = widget.bid;
    final List<dynamic> images = bid['image_urls'] ?? [];
    final bool isActive = bid['is_active'] ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Auction Details"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================== Image Section (PropertyDetails Style) ====================
                SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: images.isNotEmpty
                      ? Image.network(
                          images[_currentIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 100),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                ),

                // Thumbnail Images
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: SizedBox(
                      height: 85,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => setState(() => _currentIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _currentIndex == index
                                      ? Colors.green
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  images[index],
                                  width: 85,
                                  height: 85,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isActive ? "LIVE AUCTION" : "ENDED",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "Ends: ${DateTime.parse(bid['end_time']).toString().substring(0, 16)}",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text(
                        bid['title'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bid['location'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bid Information - Golden Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF8E1), Color(0xFFFFE8B3)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "CURRENT HIGHEST BID",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              "৳ ${bid['current_highest_bid']}",
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Base Price: ৳ ${bid['base_price']}",
                              style: const TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Property Details
                      const Text(
                        "Property Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _detailRow("Property Type", bid['property_type']),
                      if (bid['bedrooms'] != null)
                        _detailRow("Bedrooms", "${bid['bedrooms']}"),
                      if (bid['bathrooms'] != null)
                        _detailRow("Bathrooms", "${bid['bathrooms']}"),
                      if (bid['plot_size'] != null)
                        _detailRow("Plot Size", "${bid['plot_size']} Katha"),
                      if (bid['parking_spaces'] != null)
                        _detailRow(
                          "Parking",
                          "${bid['parking_spaces']} Spaces",
                        ),
                      const SizedBox(height: 24),

                      // Description
                      if (bid['description'] != null &&
                          bid['description'].toString().isNotEmpty) ...[
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bid['description'],
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Place Bid Section
                      if (isActive) ...[
                        const Text(
                          "Place Your Bid",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bidAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Enter Bid Amount (৳)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixText: "৳ ",
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 5,
                            ),
                            onPressed: _isLoading ? null : _placeBid,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "PLACE BID NOW",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ] else
                        const Center(
                          child: Text(
                            "This auction has ended",
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Back Button (Optional - AppBar already has back, but matching PropertyDetails style)
          // Positioned(
          //   top: 50,
          //   left: 20,
          //   child: CircleAvatar(
          //     backgroundColor: Colors.white,
          //     child: IconButton(
          //       icon: const Icon(Icons.arrow_back, color: Colors.black),
          //       onPressed: () => Navigator.pop(context),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ); //comment
  }
}
