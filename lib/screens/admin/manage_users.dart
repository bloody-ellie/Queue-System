import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _role = 'student'; // default

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Manage Users')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passCtrl, obscureText: true, decoration: InputDecoration(labelText: 'Password (min 6)')),
            TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Full Name')),
            Row(
              children: [
                Text('Role: '),
                DropdownButton<String>(
                  value: _role,
                  items: ['student', 'cashier'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => _role = v!),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                bool success = await auth.createUser(
                  _emailCtrl.text,
                  _passCtrl.text,
                  _nameCtrl.text,
                  _role,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User created!')));
                  _emailCtrl.clear(); _passCtrl.clear(); _nameCtrl.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Creation failed')));
                }
              },
              child: Text('Create User'),
            ),
            // Optionally show list of users (but we'll keep it simple)
          ],
        ),
      ),
    );
  }
}