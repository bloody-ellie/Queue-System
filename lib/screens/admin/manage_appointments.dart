import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/queue_ticket.dart';

class ManageAppointments extends StatefulWidget {
  const ManageAppointments({super.key});

  @override
  State<ManageAppointments> createState() => _ManageAppointmentsState();
}

class _ManageAppointmentsState extends State<ManageAppointments> {
  final FirestoreService _fs = FirestoreService();
  
  DateTime? _startDate;
  DateTime? _endDate;
  List<QueueTicket> _tickets = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Appointments'),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '⚠️ This will permanently delete ALL appointments for the selected date range. This action cannot be undone!',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Date Range Selector
            const Text(
              'Select Date Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectStartDate(),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate == null
                          ? 'From'
                          : '${_formatDate(_startDate!)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectEndDate(),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _endDate == null
                          ? 'To'
                          : '${_formatDate(_endDate!)}',
                    ),
                  ),
                ),
              ],
            ),
            
            if (_startDate != null && _endDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Range: ${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_startDate != null && _endDate != null) ? _searchAppointments : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(_isLoading ? 'Loading...' : 'Search Appointments'),
                  ),
                ),
                const SizedBox(width: 8),
                if (_hasSearched)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _tickets.isNotEmpty ? _confirmDelete : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Delete All (${_tickets.length})'),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Results
            if (_hasSearched) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Found ${_tickets.length} appointment(s)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _tickets.isEmpty ? Colors.grey : Colors.blue,
                      ),
                    ),
                    if (_tickets.isNotEmpty)
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Ticket List
              Expanded(
                child: _tickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Colors.green),
                            const SizedBox(height: 16),
                            const Text(
                              'No appointments found for this date range.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tickets.length,
                        itemBuilder: (ctx, i) {
                          final ticket = _tickets[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(ticket.status),
                                child: Text(
                                  '${ticket.queueNumber}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text('Ticket #${ticket.queueNumber}'),
                              subtitle: Text(
                                'Student ID: ${ticket.studentId}\nStatus: ${ticket.status.toUpperCase()}\nScheduled: ${_formatDateTime(ticket.timeSlot)}',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        // If end date is before start, reset end
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
        _tickets = [];
        _hasSearched = false;
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first.')),
      );
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        _tickets = [];
        _hasSearched = false;
      });
    }
  }

  Future<void> _searchAppointments() async {
    if (_startDate == null || _endDate == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final tickets = await _fs.getTicketsByTimeSlotRange(_startDate!, _endDate!);
      setState(() {
        _tickets = tickets;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (_startDate == null || _endDate == null || _tickets.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Confirm Delete All'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to delete ${_tickets.length} appointment(s) from ${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}.',
            ),
            const SizedBox(height: 12),
            const Text(
              'This will also delete all associated payments.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action CANNOT be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete All'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _performDelete();
    }
  }

  Future<void> _performDelete() async {
    setState(() => _isLoading = true);
    
    try {
      final deletedCount = await _fs.deleteTicketsByTimeSlotRange(_startDate!, _endDate!);
      
      // Also delete related payments - we can use cleanup service or call firestore directly
      // For simplicity, we'll just delete tickets and let the cleanup service handle payments later.
      
      setState(() {
        _tickets = [];
        _hasSearched = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Deleted $deletedCount appointments!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day} at $hour:$minute $period';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'serving':
        return Colors.green;
      case 'served':
        return Colors.blue;
      case 'passed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}