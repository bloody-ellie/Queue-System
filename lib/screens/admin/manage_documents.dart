import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/document_type.dart';

class ManageDocuments extends StatefulWidget {
  const ManageDocuments({super.key});

  @override
  State<ManageDocuments> createState() => _ManageDocumentsState();
}

class _ManageDocumentsState extends State<ManageDocuments> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final FirestoreService _fs = FirestoreService();
  List<DocumentType> _documents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await _fs.getDocumentTypes();
    setState(() => _documents = docs);
  }

  void _addDocument() async {
    if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      double price = double.tryParse(_priceController.text) ?? 0.0;
      await _fs.addDocumentType(_nameController.text, price);
      _nameController.clear();
      _priceController.clear();
      _load();
    }
  }

  void _toggleActive(DocumentType doc) async {
    await _fs.updateDocumentType(doc.id, active: !doc.active);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Documents')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Document Name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addDocument,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _documents.length,
              itemBuilder: (ctx, i) {
                final doc = _documents[i];
                return ListTile(
                  title: Text(doc.name),
                  subtitle: Text('₱${doc.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: doc.active,
                        onChanged: (_) => _toggleActive(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(doc);
                        },
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

  void _showEditDialog(DocumentType doc) {
    final nameCtrl = TextEditingController(text: doc.name);
    final priceCtrl = TextEditingController(text: doc.price.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              double price = double.tryParse(priceCtrl.text) ?? 0.0;
              await _fs.updateDocumentType(
                doc.id,
                name: nameCtrl.text,
                price: price,
              );
              if (mounted) {
                Navigator.pop(context);
                _load();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}