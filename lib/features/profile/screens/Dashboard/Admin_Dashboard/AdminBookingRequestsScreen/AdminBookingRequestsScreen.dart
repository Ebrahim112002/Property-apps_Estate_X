import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart'; // পাথ চেক করে নিও

class AdminBookingRequestsScreen extends StatefulWidget {
  const AdminBookingRequestsScreen({super.key});

  @override
  State<AdminBookingRequestsScreen> createState() => _AdminBookingRequestsScreenState();
}

class _AdminBookingRequestsScreenState extends State<AdminBookingRequestsScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> requests = [];
  bool _isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAllBookingRequests();
      if (mounted) {
        setState(() {
          requests = data;
          debugPrint("✅ Loaded ${data.length} booking requests successfully.");
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching booking requests: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = requests.where((req) {
      final status = (req['status'] ?? 'pending').toString().toLowerCase();
      
      final buyer = req['buyer'] is Map ? req['buyer'] : {};
      final seller = req['seller'] is Map ? req['seller'] : {};
      final prop = req['properties'] is Map ? req['properties'] : {};
      
      final buyerName = (buyer['full_name'] ?? '').toString().toLowerCase();
      final buyerEmail = (buyer['email'] ?? '').toString().toLowerCase();
      final sellerName = (seller['full_name'] ?? '').toString().toLowerCase();
      final propTitle = (prop['title'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase().trim();

      bool matchesSearch = query.isEmpty ||
          buyerName.contains(query) ||
          buyerEmail.contains(query) ||
          sellerName.contains(query) ||
          propTitle.contains(query);

      bool matchesFilter = true;
      if (selectedFilter != 'All') {
        matchesFilter = (status == selectedFilter.toLowerCase());
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Admin: Booking Requests Panel",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _fetchRequests,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by buyer, seller, email or property...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['All', 'Pending', 'Approved', 'Rejected'].map((filterType) {
                final isSelected = selectedFilter == filterType;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(filterType),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      onSelected: (bool selected) {
                        if (selected) setState(() => selectedFilter = filterType);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRequests.isEmpty
                    ? const Center(child: Text("No booking requests found."))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final req = filteredRequests[index];
                          
                          final buyer = req['buyer'] is Map ? req['buyer'] : {};
                          final seller = req['seller'] is Map ? req['seller'] : {};
                          final prop = req['properties'] is Map ? req['properties'] : {};
                          final String status = (req['status'] ?? 'pending').toString().toLowerCase();
                          final String createdAt = req['created_at'] != null 
                              ? req['created_at'].toString().substring(0, 10) 
                              : 'N/A';

                          Color statusColor = Colors.orange;
                          if (status == 'approved') statusColor = Colors.green;
                          if (status == 'rejected') statusColor = Colors.red;

                          final List<dynamic> propertyImages = prop['image_urls'] is List ? prop['image_urls'] : [];
                          final String? propertyCover = propertyImages.isNotEmpty ? propertyImages.first.toString() : null;

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.only(bottom: 14),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: propertyCover != null
                                            ? Image.network(propertyCover, height: 60, width: 60, fit: BoxFit.cover)
                                            : Container(height: 60, width: 60, color: Colors.grey[200], child: const Icon(Icons.home, color: Colors.grey)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prop['title'] ?? 'Property ID: ${req['property_id']}',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                            ),
                                            Text("📍 ${prop['location'] ?? 'N/A'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      Chip(label: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10))),
                                    ],
                                  ),
                                  const Divider(),
                                  _buildUserRow("Seller:", seller['full_name'] ?? 'ID: ${req['seller_id']}', seller['email'] ?? '', seller['avatar_url']),
                                  const SizedBox(height: 8),
                                  _buildUserRow("Buyer:", buyer['full_name'] ?? 'ID: ${req['buyer_id']}', buyer['email'] ?? '', buyer['avatar_url']),
                                  const Divider(),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text("Date: $createdAt", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(String label, String name, String email, dynamic avatarUrl) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        CircleAvatar(
          radius: 12,
          backgroundImage: avatarUrl != null && avatarUrl.toString().isNotEmpty ? NetworkImage(avatarUrl.toString()) : null,
          child: avatarUrl == null ? const Icon(Icons.person, size: 12) : null,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text("$name (${email.isEmpty ? 'No Email' : email})", style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}