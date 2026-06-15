import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart';

class SellerBookingRequestsScreen extends StatefulWidget {
  const SellerBookingRequestsScreen({super.key});

  @override
  State<SellerBookingRequestsScreen> createState() => _SellerBookingRequestsScreenState();
}

class _SellerBookingRequestsScreenState extends State<SellerBookingRequestsScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> _myProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPropertiesWithBookings();
  }

  Future<void> _fetchMyPropertiesWithBookings() async {
    setState(() => _isLoading = true);
    try {
      final properties = await _supabaseService.fetchMyBidProperties(); // আপনার নিজের প্রপার্টি
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
        title: const Text("Booking Requests"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myProperties.isEmpty
              ? const Center(
                  child: Text(
                    "You haven't created any properties yet.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myProperties.length,
                  itemBuilder: (context, index) {
                    final property = _myProperties[index];
                    return BookingPropertyCard(
                      property: property,
                      supabaseService: _supabaseService,
                    );
                  },
                ),
    );
  }
}

// ==================== Property Card with Booking Requests ====================
class BookingPropertyCard extends StatefulWidget {
  final dynamic property;
  final SupabaseService supabaseService;

  const BookingPropertyCard({
    super.key,
    required this.property,
    required this.supabaseService,
  });

  @override
  State<BookingPropertyCard> createState() => _BookingPropertyCardState();
}

class _BookingPropertyCardState extends State<BookingPropertyCard> {
  List<dynamic> _bookings = [];
  bool _loadingBookings = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _loadingBookings = true);
    try {
      final bookings = await widget.supabaseService.getBookingRequestsForSeller(
        propertyId: widget.property['id'].toString(),
      );
      if (mounted) {
        setState(() => _bookings = bookings);
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    } finally {
      if (mounted) setState(() => _loadingBookings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final title = property['title'] ?? 'No Title';
    final location = property['location'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(location, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            const Divider(),
            const Text(
              "Booking Requests",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_loadingBookings)
              const Center(child: CircularProgressIndicator())
            else if (_bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("No booking requests yet")),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  final user = booking['profiles'] ?? {};

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: user['avatar_url'] != null
                          ? NetworkImage(user['avatar_url'])
                          : null,
                      child: user['avatar_url'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      user['full_name'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          booking['status']?.toUpperCase() ?? 'PENDING',
                          style: TextStyle(
                            color: booking['status'] == 'approved'
                                ? Colors.green
                                : booking['status'] == 'rejected'
                                    ? Colors.red
                                    : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          booking['created_at']?.toString().substring(0, 10) ?? '',
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