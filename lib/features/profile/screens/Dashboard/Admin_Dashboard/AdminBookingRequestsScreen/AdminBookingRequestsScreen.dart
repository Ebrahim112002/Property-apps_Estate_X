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
    final data = await _supabaseService.getAllBookingRequests();
    setState(() {
      requests = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking Requests")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                final buyer = req['profiles'] ?? {};
                final prop = req['properties'] ?? {};

                final isSold = req['status'] == 'approved';

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: buyer['avatar_url'] != null ? NetworkImage(buyer['avatar_url']) : null,
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