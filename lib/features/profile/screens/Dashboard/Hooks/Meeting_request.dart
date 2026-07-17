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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      const String selectString = '''
        id, status, meeting_date, meeting_time, full_name, email, phone_number, notes, buyer_id, seller_id, property_id,
        properties(id, title, location, price, image_urls)
      ''';

      var query = _supabase.from('property_meetings').select(selectString);

      if (widget.userRole == 'buyer') {
        query = query.eq('buyer_id', user.id);
      } else if (widget.userRole == 'seller') {
        query = query.eq('seller_id', user.id);
      }

      final response = await query.order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _meetings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load meetings: $e";
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'admin_approved':
        return Colors.green;
      case 'seller_approved':
        return Colors.indigo;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.blueGrey;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('${widget.userRole.toUpperCase()} Meetings', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMeetings,
          ),
        ],
      ),
      // ফ্লেক্সিবল স্ক্রলিং ব্যবহার করে আনবাউন্ডেড হাইট-উইডথ এরর বন্ধ করা হয়েছে
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!)))
              : _meetings.isEmpty
                  ? const Center(child: Text("No meeting requests found"))
                  : RefreshIndicator(
                      onRefresh: _fetchMeetings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _meetings.length,
                        itemBuilder: (context, index) {
                          final m = _meetings[index];
                          final property = m['properties'] as Map<String, dynamic>? ?? {};
                          final status = m['status'] as String? ?? 'pending';
                          final imageUrls = property['image_urls'] as List<dynamic>?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // নেটওয়ার্ক ইমেজ এরর হ্যান্ডলিং ও সাইজ বাউন্ডিং
                                if (imageUrls != null && imageUrls.isNotEmpty)
                                  SizedBox(
                                    height: 150,
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Image.network(
                                        imageUrls.first.toString(),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.home, size: 50)),
                                      ),
                                    ),
                                  ),
                                
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property['title']?.toString() ?? 'Property Meeting',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Price: ৳${property['price']?.toString() ?? 'N/A'}",
                                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                                      ),
                                      const Divider(height: 20),
                                      
                                      Text("Name: ${m['full_name'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                                      Text("Email: ${m['email'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                                      
                                      // সেলার রোল হলে ফোন নাম্বার হাইড রাখার নিখুঁত লজিক
                                      if (widget.userRole != 'seller' && m['phone_number'] != null)
                                        Text("Phone: ${m['phone_number']}", style: const TextStyle(fontSize: 14)),
                                      
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(child: Text("Date: ${m['meeting_date'] ?? ''}")),
                                          Expanded(child: Text("Time: ${m['meeting_time'] ?? ''}")),
                                        ],
                                      ),
                                      
                                      if (m['notes'] != null && m['notes'].toString().trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text("Note: ${m['notes']}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                                      ],
                                      
                                      const SizedBox(height: 12),
                                      
                                      // লেআউট সেফ অ্যাকশন প্যানেল (বাউন্ডিং এরর ফিক্সড)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          
                                          // এখানে ElevatedButton কে Expanded বা Flexible করা হয়েছে যাতে সাইজ ক্র্যাশ না করে
                                          if (widget.userRole == 'seller' || widget.userRole == 'admin')
                                            Flexible(
                                              child: ElevatedButton(
                                                onPressed: () => _showStatusUpdateDialog(m),
                                                style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                                                child: const Text("Action"),
                                              ),
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
                    ),
    );
  }

  void _showStatusUpdateDialog(Map<String, dynamic> meeting) {
    String selectedStatus = widget.userRole == 'admin' ? 'admin_approved' : 'seller_approved';
    final notesController = TextEditingController(text: meeting['notes']?.toString() ?? '');
    final dateController = TextEditingController(text: meeting['meeting_date']?.toString());
    final timeController = TextEditingController(text: meeting['meeting_time']?.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Update Status & Schedule"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: widget.userRole == 'admin'
                        ? ['admin_approved', 'rejected', 'cancelled']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                            .toList()
                        : ['seller_approved', 'rejected']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                    decoration: const InputDecoration(labelText: "Status"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Date", suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(meeting['meeting_date']),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (d != null) setDialogState(() => dateController.text = d.toIso8601String().split('T')[0]);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "Time", suffixIcon: Icon(Icons.access_time)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (t != null) {
                        setDialogState(() {
                          timeController.text = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: "Notes"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _supabase.from('property_meetings').update({
                      'status': selectedStatus,
                      'meeting_date': dateController.text.trim(),
                      'meeting_time': timeController.text.trim(),
                      'notes': notesController.text.trim(),
                      'updated_at': DateTime.now().toIso8601String(),
                    }).eq('id', meeting['id']);

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await _fetchMeetings();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }
}