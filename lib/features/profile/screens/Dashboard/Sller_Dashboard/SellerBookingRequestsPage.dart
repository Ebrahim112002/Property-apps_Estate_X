import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerBookingRequestsPage extends StatefulWidget {
  const SellerBookingRequestsPage({super.key});

  @override
  State<SellerBookingRequestsPage> createState() =>
      _SellerBookingRequestsPageState();
}

class _SellerBookingRequestsPageState extends State<SellerBookingRequestsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  
  String _selectedFilter = 'All'; // All, Pending, Approved, Rejected, Cancelled

  final List<String> _filters = ['All', 'Pending', 'Approved', 'Rejected', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchBookingRequests();
  }

  Future<void> _fetchBookingRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final response = await _supabase
          .from('booking_requests')
          .select('''
            id,
            status,
            created_at,
            buyer_id,
            profiles!buyer_id(full_name, email, role, city, area), 
            properties(id, title, price, location, image_urls)
          ''')
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _allBookings = List<Map<String, dynamic>>.from(response);
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load booking requests: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredBookings = List.from(_allBookings);
    } else {
      _filteredBookings = _allBookings.where((request) {
        final status = (request['status'] as String? ?? '').toLowerCase();
        return status == _selectedFilter.toLowerCase();
      }).toList();
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _supabase
          .from('booking_requests')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${newStatus.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchBookingRequests(); // Refresh list
    } catch (e) {
      debugPrint('❌ Update Booking Status Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookingRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          _applyFilter();
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.blue[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchBookingRequests,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredBookings.isEmpty
                        ? const Center(child: Text('No booking requests found.'))
                        : RefreshIndicator(
                            onRefresh: _fetchBookingRequests,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredBookings.length,
                              itemBuilder: (context, index) {
                                final request = _filteredBookings[index];
                                final buyer = request['profiles'] as Map<String, dynamic>? ?? {};
                                final property = request['properties'] as Map<String, dynamic>? ?? {};
                                final status = request['status'] as String? ?? 'pending';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Property Info (same as before)
                                        Row(
                                          children: [
                                            if (property['image_urls'] != null &&
                                                (property['image_urls'] as List).isNotEmpty)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  (property['image_urls'] as List).first,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 80),
                                                ),
                                              )
                                            else
                                              const Icon(Icons.home, size: 80, color: Colors.grey),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    property['title'] ?? 'Property',
                                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(property['location'] ?? '', style: const TextStyle(color: Colors.grey)),
                                                  Text('Price: ৳${property['price'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),

                                        // Buyer Info
                                        Row(
                                          children: [
                                            const Icon(Icons.person),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(buyer['full_name'] ?? 'Unknown Buyer', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  Text(buyer['email'] ?? ''),
                                                  Text('${buyer['city'] ?? ''}, ${buyer['area'] ?? ''}'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Status
                                        Row(
                                          children: [
                                            const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                            Chip(
                                              label: Text(status.toUpperCase()),
                                              backgroundColor: _getStatusColor(status).withOpacity(0.2),
                                              labelStyle: TextStyle(color: _getStatusColor(status)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // Action Buttons
                                        if (status.toLowerCase() == 'pending')
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _updateBookingStatus(request['id'], 'approved'),
                                                  icon: const Icon(Icons.check),
                                                  label: const Text('Approve'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () => _updateBookingStatus(request['id'], 'rejected'),
                                                  icon: const Icon(Icons.close),
                                                  label: const Text('Reject'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                ),
                                              ),
                                            ],
                                          )
                                        else if (status.toLowerCase() == 'approved')
                                          ElevatedButton.icon(
                                            onPressed: () => _updateBookingStatus(request['id'], 'cancelled'),
                                            icon: const Icon(Icons.cancel),
                                            label: const Text('Cancel Booking'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}