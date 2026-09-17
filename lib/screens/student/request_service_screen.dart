import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/document_type.dart';
import '../../models/payment.dart';
import '../../models/queue_ticket.dart';
import '../../models/schedule.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../services/firestore_service.dart';

class RequestServiceScreen extends StatefulWidget {
  const RequestServiceScreen({super.key});

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final FirestoreService _fs = FirestoreService();
  
  // Multi-select state
  bool _includeTuition = false;
  Set<String> _selectedDocumentIds = {};
  
  DateTime? _selectedSlot;
  List<DocumentType> _documentTypes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final docs = await _fs.getDocumentTypes();
    setState(() {
      _documentTypes = docs.where((d) => d.active).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Service'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tuition Toggle (No fee)
                  Card(
                    child: SwitchListTile(
                      title: const Text(
                        'Tuition',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('No fee (select if you need to pay tuition)'),
                      value: _includeTuition,
                      onChanged: (value) {
                        setState(() => _includeTuition = value);
                      },
                      activeColor: Colors.blue,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Documents Section
                  const Text(
                    'Select Documents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: _documentTypes.isEmpty
                        ? const Center(
                            child: Text('No document types available.'),
                          )
                        : ListView.builder(
                            itemCount: _documentTypes.length,
                            itemBuilder: (ctx, i) {
                              final doc = _documentTypes[i];
                              final isSelected = _selectedDocumentIds.contains(doc.id);
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: CheckboxListTile(
                                  title: Text(doc.name),
                                  subtitle: Text('₱${doc.price.toStringAsFixed(2)}'),
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedDocumentIds.add(doc.id);
                                      } else {
                                        _selectedDocumentIds.remove(doc.id);
                                      }
                                    });
                                  },
                                  secondary: Icon(
                                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                                    color: isSelected ? Colors.blue : Colors.grey,
                                  ),
                                  checkboxShape: const CircleBorder(),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  const Divider(),
                  
                  // Summary - Tuition NOT counted in total
                  _buildSummary(),
                  
                  const SizedBox(height: 12),
                  
                  // Time Slot
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _selectSlot(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _selectedSlot == null 
                                ? 'Select Time Slot' 
                                : 'Slot: ${_formatTime(_selectedSlot!)}',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasSelection() ? () => _submitRequest(auth.currentUser!.uid) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _hasSelection() 
                            ? 'Book Slot & Get QR ${_getTotalText()}'
                            : 'Select at least one service',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary() {
    final itemCount = _getItemCount();
    final documentTotal = _calculateDocumentTotal();
    
    if (itemCount == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No services selected',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    // Build list of selected items
    final items = <String>[];
    if (_includeTuition) items.add('Tuition (Free)');
    for (var id in _selectedDocumentIds) {
      final doc = _documentTypes.firstWhere((d) => d.id == id);
      items.add('${doc.name} (₱${doc.price.toStringAsFixed(2)})');
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getItemCount()} service(s) selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '• $item',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          )).toList(),
          const SizedBox(height: 8),
          if (documentTotal > 0)
            Text(
              'Document Total: ₱${documentTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          if (documentTotal == 0 && _includeTuition)
            const Text(
              'No document fees (Tuition only)',
              style: TextStyle(color: Colors.green),
            ),
        ],
      ),
    );
  }

  bool _hasSelection() {
    return _includeTuition || _selectedDocumentIds.isNotEmpty;
  }

  // ✅ Calculate ONLY document total (tuition is free)
  double _calculateDocumentTotal() {
    double total = 0.0;
    for (var id in _selectedDocumentIds) {
      final doc = _documentTypes.firstWhere((d) => d.id == id);
      total += doc.price;
    }
    return total;
  }

  int _getItemCount() {
    int count = 0;
    if (_includeTuition) count++;
    count += _selectedDocumentIds.length;
    return count;
  }

  String _getTotalText() {
    final docTotal = _calculateDocumentTotal();
    if (docTotal > 0) {
      return '(Documents: ₱${docTotal.toStringAsFixed(2)})';
    } else if (_includeTuition) {
      return '(Tuition only - no fee)';
    }
    return '';
  }

  Future<void> _selectSlot(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      
      final schedules = await _fs.getSchedules();
      Navigator.pop(context);
      
      final availableSchedules = schedules.where((s) => 
        s.isAvailable && !s.isFull
      ).toList();
      
      if (availableSchedules.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No available time slots.')),
          );
        }
        return;
      }
      
      final selected = await showDialog<Schedule>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select Available Time Slot'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableSchedules.length,
              itemBuilder: (ctx, i) {
                final schedule = availableSchedules[i];
                return ListTile(
                  title: Text('${_formatDate(schedule.date)} - ${schedule.timeRange}'),
                  subtitle: Text(
                    '${schedule.bookedStudents.length}/${schedule.maxStudents} booked',
                  ),
                  onTap: () => Navigator.pop(context, schedule),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (selected != null) {
        final selectedDateTime = DateTime(
          selected.date.year,
          selected.date.month,
          selected.date.day,
          selected.startTime.hour,
          selected.startTime.minute,
        );
        
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await _fs.bookScheduleSlot(selected.id, auth.currentUser!.uid);
        
        setState(() => _selectedSlot = selectedDateTime);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Slot booked for ${_formatDate(selected.date)} at ${selected.timeRange}'),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      print('❌ Error selecting slot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _submitRequest(String studentId) async {
    if (!_hasSelection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one service')),
      );
      return;
    }
    
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a time slot')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      int count = await _fs.getTicketCountForSlot(_selectedSlot!);
      int queueNumber = count + 1;

      String ticketId = const Uuid().v4();
      QueueTicket ticket = QueueTicket(
        id: ticketId,
        studentId: studentId,
        paymentId: '', // Will be updated with first payment ID
        queueNumber: queueNumber,
        status: 'waiting',
        timeSlot: _selectedSlot!,
        qrCode: ticketId,
        createdAt: DateTime.now(),
      );
      
      await _fs.createQueueTicket(ticket);

      List<String> paymentIds = [];
      
      // 1. Tuition - amount 0 (free)
      if (_includeTuition) {
        final payment = Payment(
          id: '',
          studentId: studentId,
          amount: 0.0,  // ✅ Tuition is free
          type: 'tuition',
          documentTypeId: null,
          documentName: 'Tuition',
          status: 'pending',
          ticketId: ticketId,
        );
        String paymentId = await _fs.createPayment(payment);
        paymentIds.add(paymentId);
      }
      
      // 2. Documents - with actual prices
      for (var docId in _selectedDocumentIds) {
        final doc = _documentTypes.firstWhere((d) => d.id == docId);
        final payment = Payment(
          id: '',
          studentId: studentId,
          amount: doc.price,
          type: 'document',
          documentTypeId: docId,
          documentName: doc.name,
          status: 'pending',
          ticketId: ticketId,
        );
        String paymentId = await _fs.createPayment(payment);
        paymentIds.add(paymentId);
      }

      Navigator.pop(context);

      print('✅ Ticket created:');
      print('  - Ticket ID: $ticketId');
      print('  - Queue #: $queueNumber');
      print('  - Payments: ${paymentIds.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket #$queueNumber created! (${paymentIds.length} payment(s))'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      print('❌ Error creating request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}