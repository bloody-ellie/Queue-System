import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../models/queue_ticket.dart';
import 'scan_qr_screen.dart';
import '../../services/firestore_service.dart';


class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  List<QueueTicket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    final provider = Provider.of<QueueProvider>(context, listen: false);
    provider.getAllTickets().listen((tickets) {
      setState(() => _tickets = tickets);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashier Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScanQRScreen())),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Current Queue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tickets.length,
              itemBuilder: (ctx, i) {
                final ticket = _tickets[i];
                return ListTile(
                  title: Text('Ticket #${ticket.queueNumber}'),
                  subtitle: Text('Student: ${ticket.studentId} | Status: ${ticket.status}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ticket.status == 'waiting')
                        ElevatedButton(
                          onPressed: () => _updateStatus(ticket.id, 'serving'),
                          child: Text('Start Serving'),
                        ),
                      if (ticket.status == 'serving')
                        ElevatedButton(
                          onPressed: () => _updateStatus(ticket.id, 'served'),
                          child: Text('Mark Served'),
                        ),
                      if (ticket.status == 'waiting' || ticket.status == 'serving')
                        ElevatedButton(
                          onPressed: () => _updateStatus(ticket.id, 'passed'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text('Pass'),
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

  void _updateStatus(String ticketId, String status) async {
    final provider = Provider.of<QueueProvider>(context, listen: false);
    await provider.updateTicketStatus(ticketId, status);
    // If status is 'served', also confirm payment (this is where cashier confirms)
    if (status == 'served') {
      // For simplicity, we assume the payment is linked and we confirm it
      // We need to fetch the ticket to get paymentId
      final ticket = await provider.getTicketByQR(ticketId);
      if (ticket != null) {
        // Confirm payment
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final fs = FirestoreService();
        await fs.confirmPayment(ticket.paymentId, auth.currentUser!.uid);
      }
    }
  }
}