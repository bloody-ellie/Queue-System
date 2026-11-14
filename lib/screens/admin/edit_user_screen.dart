import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/firestore_service.dart';

class EditUserScreen extends StatefulWidget {
  final AppUser student;
  const EditUserScreen({super.key, required this.student});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _fs = FirestoreService();
  
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _middleInitialCtrl;
  late String _yearLevel;
  bool _isSaving = false;

  final List<String> _yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.student.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.student.lastName ?? '');
    _middleInitialCtrl = TextEditingController(text: widget.student.middleInitial ?? '');
    _yearLevel = widget.student.yearLevel ?? '1st Year';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleInitialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.student.studentNumber ?? 'N/A',
                enabled: false, // ✅ NOT EDITABLE
                decoration: const InputDecoration(labelText: 'Student Number (Locked)', border: OutlineInputBorder(), filled: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _middleInitialCtrl,
                maxLength: 1,
                decoration: const InputDecoration(labelText: 'Middle Initial', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _yearLevel,
                decoration: const InputDecoration(labelText: 'Year Level', border: OutlineInputBorder()),
                items: _yearLevels.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (v) => setState(() => _yearLevel = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSaving ? const CircularProgressIndicator() : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final success = await _fs.updateStudentInfo(
      uid: widget.student.uid,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      middleInitial: _middleInitialCtrl.text.trim(),
      yearLevel: _yearLevel,
    );

    setState(() => _isSaving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Student info updated'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Return true to refresh list
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to update'), backgroundColor: Colors.red),
      );
    }
  }
}