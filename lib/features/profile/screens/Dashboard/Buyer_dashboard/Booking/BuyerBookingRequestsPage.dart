import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Hooks/Meeting_request.dart';

class BuyerBookingRequestsPage extends StatefulWidget {
  const BuyerBookingRequestsPage({super.key});

  @override
  State<BuyerBookingRequestsPage> createState() =>
      _BuyerBookingRequestsPageState();
}

class _BuyerBookingRequestsPageState extends State<BuyerBookingRequestsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBuyerBookings();
  }

  Future<void> _fetchBuyerBookings() async {
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
            seller_id,
            profiles!seller_id(full_name, email, role, city, area),
            properties(id, title, price, location, image_urls)
          ''')
          .eq('buyer_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _allBookings = List<Map<String, dynamic>>.from(response);
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load your bookings: $e';
        _isLoading = false;
      });
      debugPrint('❌ Fetch Buyer Bookings Error: $e');
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

  // ==================== MEETING REQUEST ====================
  Future<bool> createMeetingRequest({
    required String propertyId,
    required String sellerId,
    required String fullName,
    required String email,
    required String phone,
    required String date,
    required String time,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase.from('property_meetings').insert({
        'property_id': propertyId,
        'buyer_id': user.id,
        'seller_id': sellerId,
        'full_name': fullName,
        'email': email,
        'phone_number': phone,
        'meeting_date': date,
        'meeting_time': time,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      debugPrint('❌ Create Meeting Request Error: $e');
      return false;
    }
  }

  void _showMeetingRequestModal(
    BuildContext context,
    Map<String, dynamic> booking,
  ) async {
    final property = booking['properties'] as Map<String, dynamic>? ?? {};
    final seller = booking['profiles'] as Map<String, dynamic>? ?? {};
    final propertyId = property['id'];

    // Check if already requested for this property
    final existing = await _supabase
        .from('property_meetings')
        .select('id')
        .eq('buyer_id', _supabase.auth.currentUser!.id)
        .eq('property_id', propertyId)
        .maybeSingle();

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You have already requested a meeting for this property.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    DateTime? selectedDate;
    String? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text("Request Property Meeting"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property['title'] ?? 'Property',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(labelText: "Full Name *"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email *"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number *",
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    title: Text(
                      selectedDate == null
                          ? "Select Meeting Date"
                          : "Date: ${selectedDate!.toString().substring(0, 10)}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setModalState(() => selectedDate = date);
                      }
                    },
                  ),

                  ListTile(
                    title: Text(selectedTime ?? "Select Meeting Time"),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setModalState(() {
                          selectedTime =
                              "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDate == null || selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select date and time"),
                      ),
                    );
                    return;
                  }

                  final success = await createMeetingRequest(
                    propertyId: propertyId,
                    sellerId: seller['id'] ?? booking['seller_id'],
                    fullName: fullNameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    date: selectedDate!.toIso8601String().split('T')[0],
                    time: selectedTime!,
                  );

                  if (success && mounted) {
                    Navigator.pop(context); // Close modal

                    // Success Dialog with navigation
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Request Sent Successfully!"),
                        content: const Text(
                          "We're reviewing your request. We will contact you soon.\n\nYou can check the status in Meeting Requests page.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close success dialog
                              // Navigate to Meeting Requests Page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MeetingRequestsPage(
                                    userRole: 'buyer',
                                  ),
                                ),
                              );
                            },
                            child: const Text("See Your Status"),
                          ),
                        ],
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to send request. Try again."),
                      ),
                    );
                  }
                },
                child: const Text("Send Request"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booking Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBuyerBookings,
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
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchBuyerBookings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredBookings.isEmpty
                ? const Center(
                    child: Text(
                      'You have not made any booking requests yet.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchBuyerBookings,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredBookings.length,
                      itemBuilder: (context, index) {
                        final request = _filteredBookings[index];
                        final seller =
                            request['profiles'] as Map<String, dynamic>? ?? {};
                        final property =
                            request['properties'] as Map<String, dynamic>? ??
                            {};
                        final status =
                            request['status'] as String? ?? 'pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Property Info
                                Row(
                                  children: [
                                    if (property['image_urls'] != null &&
                                        (property['image_urls'] as List)
                                            .isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          (property['image_urls'] as List)
                                              .first,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.home,
                                                size: 90,
                                                color: Colors.grey,
                                              ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.home,
                                        size: 90,
                                        color: Colors.grey,
                                      ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            property['title'] ?? 'Property',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            property['location'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            'Price: ৳${property['price'] ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // Seller Info
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Seller: ${seller['full_name'] ?? 'Unknown'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(seller['email'] ?? ''),
                                          if (seller['city'] != null ||
                                              seller['area'] != null)
                                            Text(
                                              '${seller['city'] ?? ''}, ${seller['area'] ?? ''}',
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Status
                                Row(
                                  children: [
                                    const Text(
                                      'Status: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(status.toUpperCase()),
                                      backgroundColor: _getStatusColor(
                                        status,
                                      ).withOpacity(0.2),
                                      labelStyle: TextStyle(
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  'Requested on: ${request['created_at']?.substring(0, 10) ?? ''}',
                                  style: const TextStyle(color: Colors.grey),
                                ),

                                const SizedBox(height: 12),

                                // Meeting Request Button (শুধু Approved হলে)
                                if (status.toLowerCase() == 'approved')
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showMeetingRequestModal(
                                        context,
                                        request,
                                      ),
                                      icon: const Icon(Icons.calendar_today),
                                      label: const Text('Request for Meeting'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
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
