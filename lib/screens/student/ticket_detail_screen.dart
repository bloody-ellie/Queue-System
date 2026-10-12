import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/queue_ticket.dart';
import '../../providers/queue_provider.dart';
import 'dart:async';

class TicketDetailScreen extends StatefulWidget {
  final QueueTicket ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late QueueTicket _currentTicket;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    
    final provider = Provider.of<QueueProvider>(context, listen: false);
    _subscription = provider.getAllTickets().listen((tickets) {
      final updated = tickets.firstWhere(
        (t) => t.id == _currentTicket.id,
        orElse: () => _currentTicket,
      );
      if (updated.status != _currentTicket.status) {
        setState(() => _currentTicket = updated);
        _showStatusNotification(updated.status);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _showStatusNotification(String status) {
    String message;
    if (status == 'serving') {
      message = 'Now serving! Please proceed to the counter.';
    } else if (status == 'served') {
      message = 'Transaction complete. Thank you!';
    } else if (status == 'passed') {
      message = 'Your turn was passed. Please re-queue.';
    } else {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _currentTicket;
    
    return Scaffold(
      appBar: AppBar(title: Text('Ticket #${ticket.queueNumber}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ticket info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Text('Queue Number', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(
                    '${ticket.queueNumber}',
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Student info
            _buildInfoRow(Icons.badge, 'Student Number', ticket.studentNumber),
            _buildInfoRow(Icons.person, 'Name', ticket.studentName),
            _buildInfoRow(Icons.school, 'Year Level', ticket.yearLevel),
            _buildInfoRow(Icons.access_time, 'Time Slot', _formatTime(ticket.timeSlot)),

            const SizedBox(height: 20),
            _buildServicesSection(ticket),
            const SizedBox(height: 20),

            Text(
              'Wait for your queue number to be called by the cashier.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildServicesSection(QueueTicket ticket) {
    if (ticket.serviceItems.isEmpty) return const SizedBox.shrink();

    double total = 0.0;
    for (var item in ticket.serviceItems) {
      total += item.amount;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Your Request',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...ticket.serviceItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.type == 'tuition' ? Icons.school : Icons.description,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(item.name),
                      ],
                    ),
                    Text(
                      item.amount > 0 ? '₱${item.amount.toStringAsFixed(2)}' : 'Free',
                      style: TextStyle(
                        color: item.amount > 0 ? Colors.blue.shade700 : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                total > 0 ? '₱${total.toStringAsFixed(2)}' : 'Free',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: total > 0 ? Colors.blue.shade700 : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (_currentTicket.status) {
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

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}