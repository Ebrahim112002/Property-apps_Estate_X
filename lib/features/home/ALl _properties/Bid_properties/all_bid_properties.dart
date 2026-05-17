import 'package:flutter/material.dart';
import '../../../../../services/supabase_service.dart';
import 'premium_bid_card.dart';
import 'bid_details_screen.dart';

class AllBidPropertiesScreen extends StatefulWidget {
  static const String routeName = '/all-bid-properties';

  const AllBidPropertiesScreen({super.key});

  @override
  State<AllBidPropertiesScreen> createState() => _AllBidPropertiesScreenState();
}

class _AllBidPropertiesScreenState extends State<AllBidPropertiesScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> _bids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllBids();
  }

  Future<void> _fetchAllBids() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.fetchActiveBidProperties();
      setState(() => _bids = data);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Auctions"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllBids,
              child: _bids.isEmpty
                  ? const Center(child: Text("No active auctions right now"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _bids.length,
                      itemBuilder: (context, index) {
                        final bid = _bids[index];
                        return PremiumBidCard(
                          bid: bid,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BidDetailsScreen(bid: bid),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
