import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart';

class SellerBidHistoryScreen extends StatefulWidget {
  const SellerBidHistoryScreen({super.key});

  @override
  State<SellerBidHistoryScreen> createState() => _SellerBidHistoryScreenState();
}

class _SellerBidHistoryScreenState extends State<SellerBidHistoryScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> _myProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPropertiesWithBids();
  }

  Future<void> _fetchMyPropertiesWithBids() async {
    setState(() => _isLoading = true);
    try {
      final properties = await _supabaseService.fetchMyBidProperties();
      _myProperties = properties;
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Auction Bids History"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myProperties.isEmpty
              ? const Center(
                  child: Text(
                    "You haven't created any auctions yet.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myProperties.length,
                  itemBuilder: (context, index) {
                    final property = _myProperties[index];
                    return PropertyBidCard(
                      property: property,
                      supabaseService: _supabaseService,
                    );
                  },
                ),
    );
  }
}

// ==================== Property Card with Bid History ====================
class PropertyBidCard extends StatefulWidget {
  final dynamic property;
  final SupabaseService supabaseService;

  const PropertyBidCard({
    super.key,
    required this.property,
    required this.supabaseService,
  });

  @override
  State<PropertyBidCard> createState() => _PropertyBidCardState();
}

class _PropertyBidCardState extends State<PropertyBidCard> {
  List<dynamic> _bids = [];
  bool _loadingBids = false;

  @override
  void initState() {
    super.initState();
    _loadBids();   // ← এখন অটো লোড হবে
  }

  Future<void> _loadBids() async {
    setState(() => _loadingBids = true);
    try {
      final bids = await widget.supabaseService.getBidHistoryForSeller(
        bidPropertyId: widget.property['id'],
      );
      if (mounted) {
        setState(() => _bids = bids);
      }
    } catch (e) {
      debugPrint('Error loading bids: $e');
    } finally {
      if (mounted) setState(() => _loadingBids = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final title = property['title'] ?? 'No Title';
    final currentBid = property['current_highest_bid'] ?? 0;
    final bidCount = property['bid_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Info
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Current Highest: ৳ $currentBid",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Total Bids: $bidCount",
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const Divider(height: 24),

            // Bids List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bid History",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _loadBids,   // Manual Refresh এখনো রাখা হলো
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),

            if (_loadingBids)
              const Center(child: CircularProgressIndicator())
            else if (_bids.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text("No bids yet on this auction")),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bids.length,
                itemBuilder: (context, index) {
                  final bid = _bids[index];
                  final bidder = bid['profiles'] ?? {};

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: bidder['avatar_url'] != null
                          ? NetworkImage(bidder['avatar_url'])
                          : null,
                      child: bidder['avatar_url'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      bidder['full_name'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      bidder['email'] ?? '',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "৳ ${bid['bid_amount']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          bid['created_at']?.toString().substring(0, 10) ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}