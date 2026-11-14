import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Set<String> _selectedDocumentIds = {};

  // ✅ Documents student already has pending — cannot rebook
  Set<String> _pendingDocumentIds = {};

  DateTime? _selectedSlot;
  List<DocumentType> _documentTypes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        _loadPendingDocuments(auth.currentUser!.uid);
      }
    });
  }

  Future<void> _loadData() async {
    final docs = await _fs.getDocumentTypes();
    setState(() {
      _documentTypes = docs.where((d) => d.active).toList();
      _loading = false;
    });
  }

  Future<void> _loadPendingDocuments(String studentId) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      
      final ticketsSnapshot = await FirebaseFirestore.instance
          .collection('queueTickets')
          .where('studentId', isEqualTo: studentId)
          .where('status', whereIn: ['waiting', 'serving'])
          .get();

      for (var doc in ticketsSnapshot.docs) {
        final data = doc.data();
        final timeSlot = DateTime.parse(data['timeSlot']);
        
        if (timeSlot.isBefore(startOfToday)) {
          await doc.reference.update({'status': 'passed'});
          print('✅ Auto-expired ticket ${doc.id} for student $studentId');
        }
      }

      final pending = await _fs.getPendingDocumentIdsForStudent(studentId);
      
      if (!mounted) return;
      setState(() {
        _pendingDocumentIds = pending;
        _selectedDocumentIds.removeAll(pending);
      });
    } catch (e) {
      print('❌ Error loading pending documents: $e');
    }
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
                      activeThumbColor: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_pendingDocumentIds.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have ${_pendingDocumentIds.length} pending document request(s). ',
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'Select Documents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: _documentTypes.isEmpty
                        ? const Center(child: Text('No document types available.'))
                        : ListView.builder(
                            itemCount: _documentTypes.length,
                            itemBuilder: (ctx, i) {
                              final doc = _documentTypes[i];
                              final isSelected = _selectedDocumentIds.contains(doc.id);
                              final isPending = _pendingDocumentIds.contains(doc.id);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: isPending ? Colors.grey.shade100 : null,
                                child: CheckboxListTile(
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(doc.name)),
                                      if (isPending)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Pending',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text('₱${doc.price.toStringAsFixed(2)}'),
                                  value: isSelected,
                                  onChanged: isPending
                                      ? null
                                      : (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedDocumentIds.add(doc.id);
                                            } else {
                                              _selectedDocumentIds.remove(doc.id);
                                            }
                                          });
                                        },
                                  secondary: Icon(
                                    isPending ? Icons.hourglass_top : (isSelected ? Icons.check_circle : Icons.circle_outlined),
                                    color: isPending ? Colors.orange : (isSelected ? Colors.blue : Colors.grey),
                                  ),
                                  checkboxShape: const CircleBorder(),
                                ),
                              );
                            },
                          ),
                  ),

                  const Divider(),
                  _buildSummary(),
                  const SizedBox(height: 12),

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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasSelection()
                          ? () => _submitRequest(auth.currentUser!.uid)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _hasSelection()
                            ? 'Book Slot ${_getTotalText()}'
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
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: const Text('No services selected', style: TextStyle(color: Colors.grey)),
      );
    }

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
          Text('${_getItemCount()} service(s) selected', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $item', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              )),
          const SizedBox(height: 8),
          if (documentTotal > 0)
            Text(
              'Document Total: ₱${documentTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          if (documentTotal == 0 && _includeTuition)
            const Text('No document fees (Tuition only)', style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  bool _hasSelection() => _includeTuition || _selectedDocumentIds.isNotEmpty;

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
    if (docTotal > 0) return '(Documents: ₱${docTotal.toStringAsFixed(2)})';
    else if (_includeTuition) return '(Tuition only - no fee)';
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

      final availableSchedules = schedules.where((s) {
        if (!s.isAvailable || s.isFull) return false;
        if (s.isPast) return false;
        
        final scheduleStart = DateTime(s.date.year, s.date.month, s.date.day, s.startTime.hour, s.startTime.minute);
        if (scheduleStart.add(const Duration(minutes: 30)).isBefore(DateTime.now())) {
          return false;
        }
        return true;
      }).toList();

      if (availableSchedules.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No available time slots. Please check back later.')),
          );
        }
        return;
      }

      Map<DateTime, List<Schedule>> schedulesByDate = {};
      for (var schedule in availableSchedules) {
        final dateOnly = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
        if (!schedulesByDate.containsKey(dateOnly)) {
          schedulesByDate[dateOnly] = [];
        }
        schedulesByDate[dateOnly]!.add(schedule);
      }

      final selected = await showDialog<Schedule>(
        context: context,
        builder: (_) => _CalendarSchedulePicker(schedulesByDate: schedulesByDate),
      );

      if (selected != null) {
        final selectedDateTime = DateTime(
          selected.date.year, selected.date.month, selected.date.day,
          selected.startTime.hour, selected.startTime.minute,
        );

        final auth = Provider.of<AuthProvider>(context, listen: false);
        await _fs.bookScheduleSlot(selected.id, auth.currentUser!.uid);

        setState(() => _selectedSlot = selectedDateTime);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Slot booked for ${_formatDate(selected.date)} at ${selected.timeRange}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _submitRequest(String studentId) async {
    if (!_hasSelection()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one service')));
      return;
    }

    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a time slot')));
      return;
    }

    final conflicting = _selectedDocumentIds.intersection(_pendingDocumentIds);
    if (conflicting.isNotEmpty) {
      final names = conflicting.map((id) => _documentTypes.firstWhere((d) => d.id == id).name).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ You already have a pending request for: $names'), backgroundColor: Colors.red),
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

      List<ServiceItem> serviceItems = [];
      if (_includeTuition) {
        serviceItems.add(ServiceItem(name: 'Tuition', type: 'tuition', amount: 0.0));
      }
      for (var docId in _selectedDocumentIds) {
        final doc = _documentTypes.firstWhere((d) => d.id == docId);
        serviceItems.add(ServiceItem(name: doc.name, type: 'document', amount: doc.price, documentTypeId: doc.id));
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser!;

      QueueTicket ticket = QueueTicket(
        id: ticketId,
        studentId: studentId,
        paymentId: '',
        queueNumber: queueNumber,
        status: 'waiting',
        timeSlot: _selectedSlot!,
        createdAt: DateTime.now(),
        serviceItems: serviceItems,
        studentNumber: user.studentNumber ?? 'N/A',
        studentName: user.fullName,
        yearLevel: user.yearLevel ?? 'N/A',
      );

      await _fs.createQueueTicket(ticket);

      List<String> paymentIds = [];

      if (_includeTuition) {
        final payment = Payment(
          id: '', studentId: studentId, amount: 0.0, type: 'tuition',
          documentTypeId: null, documentName: 'Tuition', status: 'pending', ticketId: ticketId,
        );
        paymentIds.add(await _fs.createPayment(payment));
      }

      for (var docId in _selectedDocumentIds) {
        final doc = _documentTypes.firstWhere((d) => d.id == docId);
        final payment = Payment(
          id: '', studentId: studentId, amount: doc.price, type: 'document',
          documentTypeId: docId, documentName: doc.name, status: 'pending', ticketId: ticketId,
        );
        paymentIds.add(await _fs.createPayment(payment));
      }

      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket #$queueNumber created! (${paymentIds.length} payment(s))'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ✅ FIXED: Class is now outside, at the bottom of the file
class _CalendarSchedulePicker extends StatefulWidget {
  final Map<DateTime, List<Schedule>> schedulesByDate;

  const _CalendarSchedulePicker({required this.schedulesByDate});

  @override
  State<_CalendarSchedulePicker> createState() => _CalendarSchedulePickerState();
}

class _CalendarSchedulePickerState extends State<_CalendarSchedulePicker> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final currentDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final slotsForDay = widget.schedulesByDate[currentDateOnly] ?? [];

    final sortedDates = widget.schedulesByDate.keys.toList()..sort();
    final firstDate = sortedDates.first;
    final lastDate = sortedDates.last;

    return AlertDialog(
      title: const Text('Select Time Slot'),
      contentPadding: const EdgeInsets.all(8),
      content: SizedBox(
        width: 400,
        height: 450,
        child: Column(
          children: [
            CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: firstDate,
              lastDate: lastDate,
              onDateChanged: (date) => setState(() => _selectedDate = date),
              selectableDayPredicate: (date) {
                final d = DateTime(date.year, date.month, date.day);
                return widget.schedulesByDate.containsKey(d);
              },
            ),
            const Divider(),
            Expanded(
              child: slotsForDay.isEmpty
                  ? const Center(child: Text('No slots available on this day.'))
                  : ListView.builder(
                      itemCount: slotsForDay.length,
                      itemBuilder: (ctx, i) {
                        final schedule = slotsForDay[i];
                        return Card(
                          color: Colors.blue.shade50,
                          child: ListTile(
                            leading: const Icon(Icons.access_time, color: Colors.blue),
                            title: Text(schedule.timeRange, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${schedule.bookedStudents.length}/${schedule.maxStudents} booked'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, schedule),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}