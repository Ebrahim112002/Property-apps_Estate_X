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
  int _currentIndex = 0;

  Map<String, dynamic>? _highestBidder;
  int _totalBids = 0;
  bool _isFetchingBidder = false;

  // History list state
  List<dynamic> _fullBidHistory = [];
  bool _showAllBids = false;

  @override
  void initState() {
    super.initState();
    _fetchHighestBidderAndBidCount();
    _fetchPropertyBidHistory();
  }

  Future<void> _fetchHighestBidderAndBidCount() async {
    if (!mounted) return;
    setState(() => _isFetchingBidder = true);
    try {
      final bidId = widget.bid['id'];
      final bidCountResult = await _supabaseService.getBidCount(bidPropertyId: bidId);
      _totalBids = bidCountResult;

      final highestBidderId = widget.bid['highest_bidder_id'];
      if (highestBidderId != null) {
        final bidderData = await _supabaseService.getUserProfile(userId: highestBidderId);
        if (bidderData != null && mounted) {
          _highestBidder = bidderData;
        }
      }
    } catch (e) {
      debugPrint('Error fetching bidder info: $e');
    } finally {
      if (mounted) setState(() => _isFetchingBidder = false);
    }
  }

  Future<void> _fetchPropertyBidHistory() async {
    try {
      final history = await _supabaseService.getAllBidHistoryForProperty(
        bidPropertyId: widget.bid['id'],
      );
      if (mounted) {
        setState(() {
          _fullBidHistory = history;
        });
      }
    } catch (e) {
      debugPrint('Error loading full history: $e');
    }
  }

  Future<void> _placeBid() async {
    final bidAmount = double.tryParse(_bidAmountController.text.trim());
    if (bidAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (bidAmount <= (widget.bid['current_highest_bid'] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid must be higher than current highest bid')),
      );
      return;
    }

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Bid'),
        content: const Text(
          'Bidding is a serious commitment. Please ensure you have the financial capacity to complete the purchase if you win the auction.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Place Bid')),
        ],
      ),
    );

    if (shouldProceed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await _supabaseService.placeBid(
        bidPropertyId: widget.bid['id'],
        bidAmount: bidAmount,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Bid Placed Successfully!'), backgroundColor: Colors.green),
        );
        _bidAmountController.clear();
        widget.bid['current_highest_bid'] = bidAmount; // UI Instant local state update

        await _fetchHighestBidderAndBidCount();
        await _fetchPropertyBidHistory();
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
    final currentHighest = bid['current_highest_bid'] ?? 0;

    // ─────────────────────────────────────────
    // LIVE TIME CLOSE VALIDATION LOGIC
    // ─────────────────────────────────────────
    bool isTimeClosed = false;
    if (bid['end_time'] != null) {
      try {
        final DateTime endTime = DateTime.parse(bid['end_time'].toString());
        isTimeClosed = DateTime.now().isAfter(endTime);
      } catch (e) {
        debugPrint("Time parsing error: $e");
      }
    }

    final displayHistoryCount = _showAllBids 
        ? _fullBidHistory.length 
        : (_fullBidHistory.length > 3 ? 3 : _fullBidHistory.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Auction Details"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slideshow Section
            SizedBox(
              height: 320,
              width: double.infinity,
              child: images.isNotEmpty
                  ? Image.network(images[_currentIndex], fit: BoxFit.cover)
                  : Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 100)),
            ),

            // Thumbnails
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _currentIndex == index ? Colors.green : Colors.transparent, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(images[index], width: 70, height: 70, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isActive && !isTimeClosed) ? Colors.green : Colors.red, 
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (isActive && !isTimeClosed) ? "LIVE AUCTION" : "ENDED", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      if (bid['end_time'] != null)
                        Text(
                          "Ends: ${bid['end_time'].toString().substring(0, 10)}", 
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(bid['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(bid['location'] ?? '', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  
                  const Divider(height: 32),

                  // Dynamic Statistics Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              const Text("Base Price", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text("৳ ${bid['base_price']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              const Text("Highest Bid", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("৳ $currentHighest", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ==================== PLACE BID AREA OR TIME CLOSED CARD ====================
                  if (isActive && !isTimeClosed) ...[
                    const Text("Place Your Bid", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bidAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Enter Bid Amount (৳)",
                        prefixText: "৳ ",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _placeBid,
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text("SUBMIT BID NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    // TIME OVER CARD (Bidding time is close now নোটিশ)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_clock_outlined, color: Colors.redAccent, size: 24),
                          SizedBox(width: 10),
                          Text(
                            "Bidding time is close now",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // ==================== LIVE BID HISTORY / AUDIT SECTION ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Live Bidding Audit ($_totalBids)", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      if (_fullBidHistory.length > 3)
                        TextButton(
                          onPressed: () => setState(() => _showAllBids = !_showAllBids),
                          child: Text(_showAllBids ? "Show Less" : "See All History", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _fullBidHistory.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("No bids submitted yet.", style: TextStyle(color: Colors.grey))))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayHistoryCount,
                          itemBuilder: (context, index) {
                            final dynamic bidLog = _fullBidHistory[index];
                            final dynamic bidderInfo = bidLog['profiles'] ?? {};
                            final bool isTopBid = index == 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isTopBid ? const Color(0xFFFFFDE7) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: isTopBid ? Border.all(color: Colors.amber, width: 1.5) : null,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: bidderInfo['avatar_url'] != null ? NetworkImage(bidderInfo['avatar_url']) : null,
                                    child: bidderInfo['avatar_url'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              bidderInfo['full_name'] ?? 'Anonymous Buyer',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isTopBid ? Colors.brown[900] : Colors.black),
                                            ),
                                            if (isTopBid) ...[
                                              const SizedBox(width: 6),
                                              const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                                            ]
                                          ],
                                        ),
                                        Text(bidderInfo['email'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("৳ ${bidLog['bid_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                                      Text(
                                        bidLog['created_at'] != null ? bidLog['created_at'].toString().substring(11, 16) : '',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}