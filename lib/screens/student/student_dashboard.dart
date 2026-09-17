import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../models/queue_ticket.dart';
import 'request_service_screen.dart';
import 'ticket_detail_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final studentId = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestServiceScreen()),
                  ),
                  child: const Text('Request Service (Tuition/Document)'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<QueueTicket>>(
              stream: Provider.of<QueueProvider>(context)
                  .getTicketsForStudent(studentId),
              builder: (ctx, snapshot) {
                  print('📊 Student tickets snapshot:');
                  print('  - Has data: ${snapshot.hasData}');
                  print('  - Data length: ${snapshot.data?.length ?? 0}');
                  print('  - Error: ${snapshot.error}');
                // ✅ Handle all connection states
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text('Error loading tickets: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final tickets = snapshot.data ?? [];
                
                if (tickets.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.airplane_ticket, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No tickets yet.'),
                        Text(
                          'Request a service to get started!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (ctx, i) {
                    final ticket = tickets[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${ticket.queueNumber}'),
                        ),
                        title: Text('Ticket #${ticket.queueNumber}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${ticket.status.toUpperCase()}'),
                            Text('Time: ${_formatTime(ticket.timeSlot)}'),
                          ],
                        ),
                        trailing: Icon(
                          ticket.status == 'serving' 
                              ? Icons.warning_amber
                              : ticket.status == 'served'
                                  ? Icons.check_circle
                                  : Icons.arrow_forward_ios,
                          color: _getStatusColor(ticket.status),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketDetailScreen(ticket: ticket),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
  String _formatTime(DateTime time) {
  final hour = time.hour > 12 ? time.hour - 12 : time.hour;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
}