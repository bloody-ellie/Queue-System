import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';
import '../../models/queue_ticket.dart';

class PublicDisplayScreen extends StatelessWidget {
  const PublicDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Row(
        children: [
          // --- LEFT SIDE: CASHIER STATUS ---
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ACTIVE CASHIERS', style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'cashier').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        final cashiers = snapshot.data!.docs.map((doc) => AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
                        
                        return ListView.builder(
                          itemCount: cashiers.length,
                          itemBuilder: (context, index) {
                            final cashier = cashiers[index];
                            
                            // Check if they are on break
                            if (cashier.isOnBreak) {
                              return _buildCashierCard(cashier.name, 'ON BREAK', Colors.orange);
                            }

                            // Find what they are serving
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('queueTickets').where('servingCashierId', isEqualTo: cashier.uid).snapshots(),
                              builder: (context, ticketSnap) {
                                String servingText = 'Waiting for queue...';
                                if (ticketSnap.hasData && ticketSnap.data!.docs.isNotEmpty) {
                                  final ticket = QueueTicket.fromMap(ticketSnap.data!.docs.first.id, ticketSnap.data!.docs.first.data() as Map<String, dynamic>);
                                  servingText = 'NOW SERVING: QUEUE #${ticket.queueNumber}';
                                }
                                return _buildCashierCard(cashier.name, servingText, Colors.green);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- RIGHT SIDE: UPCOMING QUEUES ---
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.blue.shade800,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('UPCOMING QUEUES', style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('queueTickets')
                          .where('status', isEqualTo: 'waiting')
                          .orderBy('timeSlot')
                          .limit(10)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final tickets = snapshot.data!.docs.map((doc) => QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

                        return ListView.builder(
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: index == 0 ? Colors.amber : Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Queue #${ticket.queueNumber}', style: TextStyle(color: index == 0 ? Colors.black : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  if (index == 0) const Text('NEXT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashierCard(String name, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(status, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}