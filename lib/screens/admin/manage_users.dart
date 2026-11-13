import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/firestore_service.dart';
import 'create_user_screen.dart';
import 'edit_user_screen.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Create New User',
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                );
                if (created == true) setState(() {}); // Refresh if created
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.school), text: 'Students'),
              Tab(icon: Icon(Icons.point_of_sale), text: 'Cashiers'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UserList(role: 'student'),
            _UserList(role: 'cashier'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
             final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                );
             if (created == true) setState(() {});
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _UserList extends StatefulWidget {
  final String role; // 'student' or 'cashier'
  const _UserList({required this.role});

  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<AppUser> _allUsers = [];
  List<AppUser> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _fs.getUsersByRole(widget.role);
    setState(() {
      _allUsers = users;
      _filtered = users;
      _isLoading = false;
    });
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allUsers;
      } else {
        _filtered = _allUsers.where((u) {
          // Search by name, email, or (if student) student number
          final matchesName = u.fullName.toLowerCase().contains(q);
          final matchesEmail = u.email.toLowerCase().contains(q);
          final matchesId = widget.role == 'student' && (u.studentNumber ?? '').toLowerCase().contains(q);
          return matchesName || matchesEmail || matchesId;
        }).toList();
      }
    });
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${widget.role == 'student' ? 'Student' : 'Cashier'}?'),
        content: Text('Are you sure you want to permanently delete ${user.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _fs.deleteUser(user.uid);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_filtered.isEmpty)
          const Expanded(child: Center(child: Text('No users found.')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final user = _filtered[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: widget.role == 'student' ? Colors.blue.shade100 : Colors.orange.shade100,
                      child: Icon(widget.role == 'student' ? Icons.school : Icons.point_of_sale),
                    ),
                    title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        if (widget.role == 'student')
                          Text('ID: ${user.studentNumber ?? 'N/A'} • ${user.yearLevel ?? 'N/A'}', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit is only for students
                        if (widget.role == 'student')
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditUserScreen(student: user)),
                              );
                              if (updated == true) _loadUsers();
                            },
                          ),
                        // Delete is for both
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}