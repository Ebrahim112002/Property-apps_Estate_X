import 'package:flutter/material.dart';
import '../../../../../../services/supabase_service.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> users = [];
  bool _isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Database থেকে সব ইউজার ডাটা রিলোড করার মেথড
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final data = await _supabaseService.getAllUsers();
    setState(() {
      users = data;
      _isLoading = false;
    });
  }

  // MODAL: ইউজারের সব ডিটেইলস দেখানোর পপআপ
  void _showUserDetailsDialog(Map<String, dynamic> user) {
    final bool isBanned = user['banned'] ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
              child: user['avatar_url'] == null ? const Icon(Icons.person, color: Colors.blue) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user['full_name'] ?? 'No Name',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              _buildDetailRow(Icons.fingerprint, "User ID", user['id']),
              _buildDetailRow(Icons.email, "Email", user['email']),
              _buildDetailRow(Icons.phone, "Phone", user['phone']),
              _buildDetailRow(Icons.badge, "Role", user['role']?.toString().toUpperCase()),
              _buildDetailRow(Icons.location_city, "City", user['city']),
              _buildDetailRow(Icons.home, "Full Address", user['full_address']),
              _buildDetailRow(
                Icons.gavel, 
                "Ban Status", 
                isBanned ? "🔴 BANNED (True)" : "🟢 ACTIVE (False)"
              ),
              _buildDetailRow(Icons.calendar_today, "Created At", user['created_at']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value != null && value.toString().isNotEmpty ? value.toString() : 'Not Provided',
                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // রোল আপডেট করার ডায়ালগ বক্স
  void _showRoleChangeDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] == 'banned' ? 'buyer' : (user['role'] ?? 'buyer');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text("Change Role for ${user['full_name'] ?? 'User'}"),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: "Select New Role"),
            items: ['buyer', 'seller', 'admin'].map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role.toUpperCase()),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setModalState(() => selectedRole = val);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                await _supabaseService.updateUserRole(user['id'], selectedRole);
                _fetchUsers();
              },
              child: const Text("Update Role"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = users.where((u) {
      final id = (u['id'] ?? '').toLowerCase();
      final name = (u['full_name'] ?? '').toLowerCase();
      final email = (u['email'] ?? '').toLowerCase();
      final role = (u['role'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      
      return id.contains(query) || name.contains(query) || email.contains(query) || role.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Manage Users", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Filter by ID, name, role, email...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text("No users found."))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          final bool isBanned = user['banned'] ?? false;
                          final role = user['role'] ?? 'buyer';

                          return Card(
                            color: isBanned ? Colors.red[50] : Colors.white,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isBanned ? Colors.grey[300] : Colors.blue[100],
                                backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                                child: user['avatar_url'] == null 
                                    ? Icon(Icons.person, color: isBanned ? Colors.grey : Colors.blue) 
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['full_name'] ?? 'No Name',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      role.toString().toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    backgroundColor: isBanned ? Colors.red : Colors.blue,
                                  )
                                ],
                              ),
                              subtitle: Text(user['email'] ?? 'No Email', maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blueGrey),
                                    onPressed: () => _showUserDetailsDialog(user),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'role') {
                                        _showRoleChangeDialog(user);
                                      } else if (value == 'ban') {
                                        setState(() => _isLoading = true);
                                        await _supabaseService.toggleUserBan(user['id'], isBanned);
                                        _fetchUsers();
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text("Delete Account?"),
                                            content: const Text("This action cannot be undone and will delete user profile history."),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                                              TextButton(
                                                onPressed: () => Navigator.pop(c, true),
                                                child: const Text("Delete Account", style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          setState(() => _isLoading = true);
                                          await _supabaseService.deleteUserAccount(user['id']);
                                          _fetchUsers();
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (!isBanned)
                                        const PopupMenuItem(
                                          value: 'role',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20),
                                              SizedBox(width: 8),
                                              Text("Change Role"),
                                            ],
                                          ),
                                        ),
                                      PopupMenuItem(
                                        value: 'ban',
                                        child: Row(
                                          children: [
                                            Icon(
                                              isBanned ? Icons.check_circle : Icons.block, 
                                              size: 20, 
                                              color: isBanned ? Colors.green : Colors.orange
                                            ),
                                            const SizedBox(width: 8),
                                            Text(isBanned ? "Unban User" : "Ban User"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_forever, size: 20, color: Colors.red),
                                            const SizedBox(width: 8),
                                            Text("Delete Account", style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
}