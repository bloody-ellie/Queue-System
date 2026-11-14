import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart'; // ✅ Added this import

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestore = FirestoreService(); // ✅ Initialized the service here
  
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _studentNumberCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleInitialCtrl = TextEditingController();
  
  String _role = 'student';
  String _yearLevel = '1st Year';
  bool _isLoading = false;
  
  final List<String> _yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password * (min 6 chars)', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: ['student', 'cashier'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const Divider(height: 32),
              
              if (_role == 'student') ...[
                TextFormField(
                  controller: _studentNumberCtrl,
                  decoration: const InputDecoration(labelText: 'Student Number *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'First Name *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(labelText: 'Last Name *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _middleInitialCtrl,
                  maxLength: 1,
                  decoration: const InputDecoration(labelText: 'Middle Initial (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _yearLevel,
                  decoration: const InputDecoration(labelText: 'Year Level', border: OutlineInputBorder()),
                  items: _yearLevels.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setState(() => _yearLevel = v!),
                ),
              ],

              if (_role == 'cashier') ...[
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // ✅ 1. Check for Duplicate Student Number
    if (_role == 'student') {
      final studentNumber = _studentNumberCtrl.text.trim();
      final isTaken = await _firestore.isStudentNumberTaken(studentNumber);
      
      if (isTaken) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Student Number is already in use by another student.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // Stop the process
      }
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    String fullName = _role == 'student'
        ? '${_lastNameCtrl.text}, ${_firstNameCtrl.text} ${_middleInitialCtrl.text.isNotEmpty ? '${_middleInitialCtrl.text}.' : ''}'
        : _nameCtrl.text;

    // ✅ 2. Attempt to create user (Firebase handles duplicate emails automatically)
    bool success = await auth.createUser(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: fullName,
      role: _role,
      studentNumber: _role == 'student' ? _studentNumberCtrl.text.trim() : null,
      firstName: _role == 'student' ? _firstNameCtrl.text.trim() : null,
      lastName: _role == 'student' ? _lastNameCtrl.text.trim() : null,
      middleInitial: _role == 'student' ? _middleInitialCtrl.text.trim() : null,
      yearLevel: _role == 'student' ? _yearLevel : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ User created successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to refresh the list
      } else {
        // If success is false, it's highly likely the Email was already in use
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Creation failed. Email might already be in use.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}