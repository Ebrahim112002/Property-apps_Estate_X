import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MeetingRequestsPage extends StatefulWidget {
  final String userRole; // 'buyer', 'seller', 'admin'

  const MeetingRequestsPage({super.key, required this.userRole});

  @override
  State<MeetingRequestsPage> createState() => _MeetingRequestsPageState();
}

class _MeetingRequestsPageState extends State<MeetingRequestsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _meetings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMeetings();
  }
  Future<void> _fetchMeetings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Base Query
      var query = _supabase
          .from('property_meetings')
          .select('''
            *,
            properties(id, title, location, price, image_urls),
            buyer_profile:profiles!buyer_id(full_name, email),
            seller_profile:profiles!seller_id(full_name)
          ''');

      // Role-wise filtering
      if (widget.userRole == 'seller') {
        query = query.eq('seller_id', user.id);
      } else if (widget.userRole == 'buyer') {
        query = query.eq('buyer_id', user.id);
      }
      // Admin হলে কোনো filter লাগবে না — সব দেখবে

      final response = await query.order('created_at', ascending: false);

      setState(() {
        _meetings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load meetings: $e";
        _isLoading = false;
      });
      debugPrint('❌ Fetch Meetings Error: $e');
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
      case 'completed':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userRole.toUpperCase()} Meeting Requests'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMeetings),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _meetings.isEmpty
                  ? const Center(child: Text("No meeting requests found"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _meetings.length,
                      itemBuilder: (context, index) {
                        final m = _meetings[index];
                        final property = m['properties'] ?? {};
                        final buyer = m['buyer_profile'] ?? {};
                        final status = m['status'] ?? 'pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Property Image + Title
                              if (property['image_urls'] != null && 
                                  (property['image_urls'] as List).isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    (property['image_urls'] as List).first,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 180,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.home, size: 80, color: Colors.grey),
                                    ),
                                  ),
                                ),

                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      property['title'] ?? 'Property',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text("📍 ${property['location'] ?? ''}"),
                                    Text("💰 ৳${property['price'] ?? 'N/A'}"),

                                    const Divider(height: 24),

                                    // Buyer Info
                                    Row(
                                      children: [
                                        const Icon(Icons.person, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Buyer: ${buyer['full_name'] ?? 'Unknown'}",
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              if (widget.userRole != 'seller')
                                                Text("Email: ${buyer['email'] ?? ''}"),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Meeting Details
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 20),
                                        const SizedBox(width: 8),
                                        Text("Date: ${m['meeting_date']}"),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.access_time, size: 20),
                                        const SizedBox(width: 8),
                                        Text("Time: ${m['meeting_time']}"),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Status
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Chip(
                                          label: Text(status.toUpperCase()),
                                          backgroundColor: _getStatusColor(status).withOpacity(0.2),
                                          labelStyle: TextStyle(
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (widget.userRole == 'seller' || widget.userRole == 'admin')
                                          ElevatedButton(
                                            onPressed: () => _showStatusUpdateDialog(m),
                                            child: const Text("Update Status"),
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
    );
  }

  void _showStatusUpdateDialog(Map<String, dynamic> meeting) {
    String newStatus = meeting['status'];
    final notesController = TextEditingController(text: meeting['notes']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Meeting Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: newStatus,
              items: ['pending', 'approved', 'rejected', 'cancelled', 'completed']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                  .toList(),
              onChanged: (val) => newStatus = val!,
              decoration: const InputDecoration(labelText: "Status"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: "Notes (Optional)"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _supabase.from('property_meetings').update({
                'status': newStatus,
                'notes': notesController.text.trim(),
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', meeting['id']);

              Navigator.pop(context);
              _fetchMeetings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Status updated successfully")),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}