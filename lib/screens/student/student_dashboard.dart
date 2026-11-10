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
    final user = auth.currentUser!;
    final studentId = user.uid;

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
          // ✅ Student info card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.badge, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Student No: ${user.studentNumber ?? "N/A"}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.school, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Year Level: ${user.yearLevel ?? "N/A"}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestServiceScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Request Service'),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
  child: StreamBuilder<List<QueueTicket>>(
    stream: Provider.of<QueueProvider>(context)
        .getTicketsForStudent(studentId),
    builder: (ctx, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      // ✅ Filter out tickets from past dates
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);

      final tickets = (snapshot.data ?? []).where((t) {
        // Hide tickets whose date is before today
        return !t.timeSlot.isBefore(startOfToday);
      }).toList();

      // Sort: today first, then future (by date)
      tickets.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));

      if (tickets.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.airplane_ticket, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No active tickets.'),
              Text(
                'Request a service to get started!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: tickets.length,
        itemBuilder: (ctx, i) {
          final ticket = tickets[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(ticket.status).withOpacity(0.2),
                child: Text(
                  '${ticket.queueNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _statusColor(ticket.status),
                  ),
                ),
              ),
              title: Text('Ticket #${ticket.queueNumber}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${ticket.status.toUpperCase()}'),
                  Text('Date: ${_formatDateTime(ticket.timeSlot)}'),
                  if (ticket.serviceItems.isNotEmpty)
                    Text(
                      'Services: ${ticket.serviceItems.map((s) => s.name).join(', ')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
Color _statusColor(String status) {
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

String _formatDateTime(DateTime date) {
  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.month}/${date.day}/${date.year} - $hour:$minute $period';
}
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}