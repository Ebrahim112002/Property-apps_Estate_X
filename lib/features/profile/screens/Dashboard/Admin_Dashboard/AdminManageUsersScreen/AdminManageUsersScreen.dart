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

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final data = await _supabaseService.getAllUsers();
    setState(() {
      users = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = users.where((u) {
      final name = (u['full_name'] ?? '').toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users"), backgroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by name...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final isActive = user['is_active'] ?? true;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                            child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(user['full_name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'] ?? ''),
                              Text("Role: ${user['role']}"),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'role') {
                                // Simple role selector
                                final newRole = await showDialog<String>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text("Change Role"),
                                    content: Column(mainAxisSize: MainAxisSize.min, children: ['buyer','seller','admin'].map((r) => ListTile(
                                      title: Text(r),
                                      onTap: () => Navigator.pop(c, r),
                                    )).toList()),
                                  ),
                                );
                                if (newRole != null) {
                                  await _supabaseService.updateUserRole(user['id'], newRole);
                                  _fetchUsers();
                                }
                              } else if (value == 'ban') {
                                await _supabaseService.toggleUserBan(user['id'], isActive);
                                _fetchUsers();
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text("Delete Account?"),
                                    content: const Text("This action cannot be undone."),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _supabaseService.deleteUserAccount(user['id']);
                                  _fetchUsers();
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'role', child: Text("Change Role")),
                              PopupMenuItem(
                                value: 'ban',
                                child: Text(isActive ? "Ban User" : "Unban User"),
                              ),
                              const PopupMenuItem(value: 'delete', child: Text("Delete Account", style: TextStyle(color: Colors.red))),
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