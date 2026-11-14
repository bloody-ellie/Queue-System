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
          title: const Text(
            'Manage Users',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Create New User',
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                );
                if (created == true) setState(() {});
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 8),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.blue.shade800,
                unselectedLabelColor: Colors.grey.shade600,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(icon: Icon(Icons.school), text: 'Students'),
                  Tab(icon: Icon(Icons.point_of_sale), text: 'Cashiers'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _UserList(role: 'student'),
            _UserList(role: 'cashier'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
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

// ✅ The _UserList class is now inside this same file, below ManageUsers
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
          final matchesName = u.fullName.toLowerCase().contains(q);
          final matchesEmail = u.email.toLowerCase().contains(q);
          final matchesId = widget.role == 'student' &&
              (u.studentNumber ?? '').toLowerCase().contains(q);
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted.')),
        );
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                      backgroundColor: widget.role == 'student'
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                      child: Icon(
                        widget.role == 'student'
                            ? Icons.school
                            : Icons.point_of_sale,
                        color: widget.role == 'student'
                            ? Colors.blue.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    title: Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        if (widget.role == 'student')
                          Text(
                            'ID: ${user.studentNumber ?? 'N/A'} • ${user.yearLevel ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.role == 'student')
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditUserScreen(student: user),
                                ),
                              );
                              if (updated == true) _loadUsers();
                            },
                          ),
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