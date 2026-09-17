import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/queue_ticket.dart';
import '../../providers/auth_provider.dart';
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
        setState(() {
          _currentTicket = updated;
        });
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
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 5),
      ),
    );
  }

  // ✅ NEW: Format time helper
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _currentTicket;
    
    return Scaffold(
      appBar: AppBar(title: Text('Ticket #${ticket.queueNumber}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: ticket.qrCode,
              version: QrVersions.auto,
              size: 200,
            ),
            SizedBox(height: 20),
            Text('Queue Number: ${ticket.queueNumber}', style: TextStyle(fontSize: 24)),
            Text('Status: ${ticket.status.toUpperCase()}', style: TextStyle(fontSize: 18, color: _statusColor)),
            // ✅ CHANGED: Formatted time without milliseconds
            Text('Time Slot: ${_formatTime(ticket.timeSlot)}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text('Show this QR to the cashier when called.'),
          ],
        ),
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
}