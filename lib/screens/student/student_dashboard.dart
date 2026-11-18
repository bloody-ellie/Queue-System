import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../models/queue_ticket.dart';
import 'request_service_screen.dart';
import 'ticket_detail_screen.dart';
import 'notifications_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}
String? _lastSeenNotificationId;

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    _listenToNotifications();
    _listenToQueuePosition();
  }

  void _listenToQueuePosition() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final studentId = auth.currentUser!.uid;

    // Listen to all waiting tickets
    FirebaseFirestore.instance
        .collection('queueTickets')
        .where('status', isEqualTo: 'waiting')
        .orderBy('timeSlot')
        .snapshots()
        .listen((snapshot) {
      
      final waitingTickets = snapshot.docs.map((doc) => QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      
      // Find the student's own ticket in the waiting list
      final myTicketIndex = waitingTickets.indexWhere((t) => t.studentId == studentId && t.status == 'waiting');
      
      if (myTicketIndex != -1) {
        // If they are 5th or closer to the front (index 0 = 1st, index 4 = 5th)
        if (myTicketIndex < 5 && myTicketIndex > 0) {
          if (mounted) {
            // Show persistent snackbar or specific alert
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Your turn is approaching! You are #${myTicketIndex + 1} in line.'),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    });
  }

  void _listenToNotifications() {
    FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        
        // ✅ Only show if we haven't seen this specific notification yet
        if (doc.id != _lastSeenNotificationId) {
          _lastSeenNotificationId = doc.id;
          
          if (mounted) {
            _showNotificationPopup(data['title'], data['message']);
          }
        }
      }
    });
  }

  void _showNotificationPopup(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(message, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

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
            icon: const Stack(
              children: [
                Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: Colors.red, // Red dot for unread
                  ),
                ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
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

                final now = DateTime.now();
                final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);

                final tickets = (snapshot.data ?? []).where((t) {
                  return !t.timeSlot.isBefore(startOfToday);
                }).toList();

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
                            Text('Date: ${_formatDate(ticket.timeSlot)}'),
                            Text('Time: ${_formatTimeRange(ticket.timeSlot, ticket.timeSlotEnd)}'),
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatTimeRange(DateTime start, DateTime? end) {
    final startStr = _formatTime(start);
    if (end == null) return startStr;
    final endStr = _formatTime(end);
    return '$startStr - $endStr';
  }
}