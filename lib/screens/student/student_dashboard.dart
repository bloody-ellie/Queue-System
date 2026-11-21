import 'dart:async'; // ✅ Added for StreamSubscription
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

class _StudentDashboardState extends State<StudentDashboard> {
  bool _hasUnreadNotifications = false;
  StreamSubscription? _notifSubscription; // ✅ Track the listener

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel(); // ✅ Clean up listener to prevent memory leaks
    super.dispose();
  }

  void _listenToNotifications() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.currentUser!.uid;

    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((notifSnap) async {
      if (notifSnap.docs.isNotEmpty) {
        final latestNotifTime = DateTime.parse(notifSnap.docs.first['createdAt']);
        
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final lastReadStr = userDoc.data()?['lastReadNotificationTime'];
        
        DateTime? lastReadTime;
        if (lastReadStr != null) {
          lastReadTime = DateTime.parse(lastReadStr);
        }

        bool hasUnread = lastReadTime == null || latestNotifTime.isAfter(lastReadTime);
        
        if (mounted) {
          setState(() => _hasUnreadNotifications = hasUnread);
        }
      }
    });
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
            icon: Badge(
              isLabelVisible: _hasUnreadNotifications,
              backgroundColor: Colors.red,
              smallSize: 10, 
              child: const Icon(Icons.notifications),
            ),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
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
          // Student info card
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
                          // ✅ Changed to withOpacity for wider Flutter compatibility
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
      case 'waiting': return Colors.orange;
      case 'serving': return Colors.green;
      case 'served': return Colors.blue;
      case 'passed': return Colors.red;
      default: return Colors.grey;
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