import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart';

class AdminBookingRequestsScreen extends StatefulWidget {
  const AdminBookingRequestsScreen({super.key});

  @override
  State<AdminBookingRequestsScreen> createState() => _AdminBookingRequestsScreenState();
}

class _AdminBookingRequestsScreenState extends State<AdminBookingRequestsScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAllBookingRequests();
      setState(() {
        requests = data;
        debugPrint("✅ Loaded ${data.length} booking requests");
      });
    } catch (e) {
      debugPrint('Error fetching booking requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Booking Requests")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(child: Text("No booking requests found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final buyer = req['profiles'] ?? {};
                    final prop = req['properties'] ?? {};

                    final bool isSold = req['status'] == 'approved';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: buyer['avatar_url'] != null ? NetworkImage(buyer['avatar_url']) : null,
                          child: buyer['avatar_url'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(prop['title'] ?? 'Property'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Buyer: ${buyer['full_name'] ?? 'Unknown'}"),
                            Text("Status: ${req['status'].toUpperCase()}"),
                          ],
                        ),
                        trailing: isSold
                            ? const Chip(label: Text("✅ SOLD"), backgroundColor: Colors.green)
                            : Chip(label: Text(req['status'].toUpperCase())),
                      ),
                    );
                  },
                ),
    );
  }
}