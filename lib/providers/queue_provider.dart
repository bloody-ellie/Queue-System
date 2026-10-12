import 'package:flutter/material.dart';
import '../models/queue_ticket.dart';
import '../services/firestore_service.dart';

class QueueProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  List<QueueTicket> _tickets = [];
  QueueTicket? _currentTicket;

  List<QueueTicket> get tickets => _tickets;

  // ✅ Fixed: Properly type the data
  Stream<List<QueueTicket>> getTicketsForStudent(String studentId) {
    return _firestore.getTicketsStream(studentId).map((snapshot) {
      return snapshot.docs.map((doc) {
        return QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Stream<List<QueueTicket>> getAllTickets() {
    return _firestore.getTicketsStream(null).map((snapshot) {
      return snapshot.docs.map((doc) {
        return QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> createTicket(QueueTicket ticket) async {
    await _firestore.createQueueTicket(ticket);
    notifyListeners();
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _firestore.updateTicketStatus(ticketId, status);
    notifyListeners();
  }

  // For cashier: get ticket by scanning QR (QR code is the ticket ID)
  //Future<QueueTicket?> getTicketByQR(String qrCode) async {
  //return await _firestore.getTicket(qrCode);
  // }

  // Search instead of QR scan
Future<List<QueueTicket>> searchTickets(String query) async {
  return await _firestore.searchTickets(query);
}
}