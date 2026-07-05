import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart';

class AdminManageBidsScreen extends StatefulWidget {
  const AdminManageBidsScreen({super.key});

  @override
  State<AdminManageBidsScreen> createState() => _AdminManageBidsScreenState();
}

class _AdminManageBidsScreenState extends State<AdminManageBidsScreen> {
  final _supabaseService = SupabaseService();
  List<dynamic> bidProperties = [];
  bool _isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'All'; // 'All', 'Active', 'Deadline Passed'

  @override
  void initState() {
    super.initState();
    _fetchBidProperties();
  }

  Future<void> _fetchBidProperties() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getAllBidProperties();
      setState(() {
        bidProperties = data;
      });
    } catch (e) {
      debugPrint('Error fetching bids: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ডেডলাইন পার হয়েছে কিনা তা যাচাই করার ইউটিলিটি
  bool _isDeadlinePassed(dynamic endTimeStr) {
    if (endTimeStr == null) return false;
    try {
      final endTime = DateTime.parse(endTimeStr.toString());
      return endTime.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  // ১. প্রপার্টি ডিটেইলস পপআপ ডায়ালগ
  void _showDetailsDialog(Map<String, dynamic> p) {
    final seller = p['profiles'] ?? {};
    final List<dynamic> imageUrls = p['image_urls'] is List ? p['image_urls'] : [];
    final bool isExpired = _isDeadlinePassed(p['end_time']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(p['title'] ?? 'Auction Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrls.isNotEmpty
                      ? Image.network(imageUrls.first.toString(), height: 160, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 160, color: Colors.grey[300], child: const Icon(Icons.gavel, size: 50)),
                ),
                const SizedBox(height: 12),
                Text("📍 Location: ${p['location'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                Text("🏢 Type: ${p['property_type'] ?? 'Flat'}", style: const TextStyle(fontSize: 14)),
                Text("📐 Area: ${p['area'] ?? '0'} sqft", style: const TextStyle(fontSize: 14)),
                const Divider(),
                Text("📉 Base Price: ৳${p['base_price'] ?? '0'}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text("🚀 Highest Bid: ৳${p['current_highest_bid'] ?? '0'}", style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.bold)),
                Text("🔢 Total Bids: ${p['bid_count'] ?? '0'}", style: const TextStyle(fontSize: 14)),
                const Divider(),
                Row(
                  children: [
                    const Text("⏱️ Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      isExpired ? "DEADLINE PASSED" : (p['is_active'] == true ? "ACTIVE" : "CLOSED"),
                      style: TextStyle(
                        color: isExpired ? Colors.red : (p['is_active'] == true ? Colors.green : Colors.grey),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text("📅 End Date: ${p['end_time'] != null ? p['end_time'].toString().substring(0, 10) : 'N/A'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(),
                const Text("👤 Seller Info:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Name: ${seller['full_name'] ?? 'Unknown'}"),
                Text("Email: ${seller['email'] ?? 'N/A'}"),
                const Divider(),
                const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(p['description'] ?? 'No description provided.', style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  // ২. এডিট করার পপআপ ফর্ম ডায়ালগ
  void _showEditFormDialog(Map<String, dynamic> property) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: property['title']);
    final locationCtrl = TextEditingController(text: property['location']);
    final basePriceCtrl = TextEditingController(text: property['base_price']?.toString());
    final highestBidCtrl = TextEditingController(text: property['current_highest_bid']?.toString());
    bool isActive = property['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Edit Auction Listing"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Title"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(labelText: "Location"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: basePriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Base Price (৳)"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: highestBidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Current Highest Bid (৳)"),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Is Active Auction", style: TextStyle(fontSize: 14)),
                    value: isActive,
                    onChanged: (val) => setModalState(() => isActive = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context);
                setState(() => _isLoading = true);

                final updatedData = {
                  'title': titleCtrl.text,
                  'location': locationCtrl.text,
                  'base_price': double.tryParse(basePriceCtrl.text) ?? property['base_price'],
                  'current_highest_bid': double.tryParse(highestBidCtrl.text) ?? property['current_highest_bid'],
                  'is_active': isActive,
                };

                final success = await _supabaseService.updateBidPropertyAdmin(property['id'].toString(), updatedData);
                if (success) {
                  _fetchBidProperties();
                } else {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text("Update"),
            )
          ],
        ),
      ),
    );
  }

  // ৩. ডিলিট অপারেশন
  Future<void> _deleteBidProperty(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Auction?"),
        content: const Text("Are you sure you want to completely delete this bid property? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _supabaseService.deleteBidPropertyAdmin(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Auction deleted cleanly"), backgroundColor: Colors.green),
      );
      _fetchBidProperties();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting database entry"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // সার্চ কোয়েরি এবং টগল ফিল্টারের কম্বাইনড ফিল্টারিং লজিক pipeline
    final filteredBids = bidProperties.where((p) {
      final title = (p['title'] ?? '').toLowerCase();
      final location = (p['location'] ?? '').toLowerCase();
      final seller = p['profiles'] ?? {};
      final sellerName = (seller['full_name'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();

      // সার্চ ম্যাচ চেক
      bool matchesSearch = title.contains(query) || location.contains(query) || sellerName.contains(query);

      // টগল বাটন স্টেট ম্যাচ চেক
      bool matchesFilter = true;
      bool isExpired = _isDeadlinePassed(p['end_time']);

      if (selectedFilter == 'Active') {
        matchesFilter = (p['is_active'] == true && !isExpired);
      } else if (selectedFilter == 'Deadline Passed') {
        matchesFilter = isExpired;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Manage Auctions & Bids", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // সার্চ বার সেকশন
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by title, area, or seller name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),

          // নতুন সংযুক্ত করা "টগল ফিল্টার বাটন" রোউ (All, Active, Deadline Passed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['All', 'Active', 'Deadline Passed'].map((filterType) {
                final isSelected = selectedFilter == filterType;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        filterType,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent,
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() => selectedFilter = filterType);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ডাটা লিস্ট ভিউ সেকশন
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBids.isEmpty
                    ? const Center(child: Text("No properties found for this category."))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredBids.length,
                        itemBuilder: (context, index) {
                          final p = filteredBids[index];
                          final seller = p['profiles'] ?? {};
                          final imageUrls = p['image_urls'] as List? ?? [];
                          final bool isExpired = _isDeadlinePassed(p['end_time']);

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 1,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: imageUrls.isNotEmpty
                                      ? Image.network(imageUrls.first.toString(), height: 160, width: double.infinity, fit: BoxFit.cover)
                                      : Container(height: 160, color: Colors.grey[300], child: const Icon(Icons.gavel, size: 60)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['title'] ?? 'No Title', 
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text("👤 Seller: ${seller['full_name'] ?? 'Unknown'}"),
                                            Text("📉 Base Price: ৳${p['base_price'] ?? '0'}"),
                                            Text(
                                              "🚀 Highest Bid: ৳${p['current_highest_bid'] ?? '0'}", 
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                Chip(
                                                  label: Text(isExpired ? "DEADLINE PASSED" : (p['is_active'] == true ? "ACTIVE" : "CLOSED")),
                                                  backgroundColor: isExpired ? Colors.red[100] : (p['is_active'] == true ? Colors.green[100] : Colors.grey[300]),
                                                  labelStyle: TextStyle(
                                                    color: isExpired ? Colors.red : (p['is_active'] == true ? Colors.green : Colors.black87),
                                                    fontSize: 11, fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Chip(
                                                  label: Text("Bids: ${p['bid_count'] ?? '0'}"),
                                                  backgroundColor: Colors.blue[50],
                                                  labelStyle: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // অ্যাডমিন অ্যাকশন বাটন প্যানেল
                                      Column(
                                        children: [
                                          IconButton(icon: const Icon(Icons.visibility, color: Colors.blueGrey), onPressed: () => _showDetailsDialog(p)),
                                          IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showEditFormDialog(p)),
                                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteBidProperty(p['id'].toString())),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}