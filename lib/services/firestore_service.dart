import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_type.dart';
import '../models/payment.dart';
import '../models/queue_ticket.dart';
import '../models/schedule.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- Documents (catalog) ----------
  Future<List<DocumentType>> getDocumentTypes() async {
    QuerySnapshot snapshot = await _firestore.collection('documentTypes').get();
    return snapshot.docs
        .map((doc) => DocumentType.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> addDocumentType(String name, double price) async {
    await _firestore.collection('documentTypes').add({
      'name': name,
      'price': price,
      'active': true,
    });
  }

  Future<void> updateDocumentType(String id, {String? name, double? price, bool? active}) async {
    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (active != null) data['active'] = active;
    await _firestore.collection('documentTypes').doc(id).update(data);
  }

  // ---------- Payments ----------
  Future<String> createPayment(Payment payment) async {
    DocumentReference ref = await _firestore.collection('payments').add(payment.toMap());
    return ref.id;
  }

  Future<void> confirmPayment(String paymentId, String cashierUid) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': 'confirmed',
      'confirmedBy': cashierUid,
      'confirmedAt': DateTime.now().toIso8601String(),
    });
  }

  // ---------- Queue Tickets ----------
  Future<String> createQueueTicket(QueueTicket ticket) async {
    DocumentReference ref = await _firestore.collection('queueTickets').add(ticket.toMap());
    return ref.id;
  }

  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    await _firestore.collection('queueTickets').doc(ticketId).update({
      'status': newStatus,
    });
  }

  Stream<QuerySnapshot> getTicketsStream(String? studentId, {String? status}) {
    
    Query query = _firestore.collection('queueTickets');
    if (studentId != null && studentId.isNotEmpty) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    return query.orderBy('createdAt', descending: true).snapshots();
    
  }

  Future<QueueTicket?> getTicket(String id) async {
    DocumentSnapshot doc = await _firestore.collection('queueTickets').doc(id).get();
    if (doc.exists) {
      return QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }
// ---------- Payments for Ticket ----------
/// Get all payments for a specific ticket
Future<List<Payment>> getPaymentsForTicket(String ticketId) async {
  try {
    final snapshot = await _firestore
        .collection('payments')
        .where('ticketId', isEqualTo: ticketId)
        .get();
    
    return snapshot.docs
        .map((doc) => Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('❌ Error getting payments for ticket: $e');
    return [];
  }
}
  // ---------- Time slot availability ----------
  Future<int> getTicketCountForSlot(DateTime slot) async {
    DateTime start = DateTime(slot.year, slot.month, slot.day, slot.hour);
    DateTime end = start.add(Duration(hours: 1));
    QuerySnapshot snapshot = await _firestore
        .collection('queueTickets')
        .where('timeSlot', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timeSlot', isLessThan: end.toIso8601String())
        .get();
    return snapshot.docs.length;
  }

   // ---------- Schedules ----------
  Future<List<Schedule>> getSchedules() async {
    final stopwatch = Stopwatch()..start();
    print('⏱️ getSchedules() started...');
    
    try {
      final snapshot = await _firestore.collection('schedules').get();
      
      stopwatch.stop();
      print('⏱️ getSchedules() found ${snapshot.docs.length} schedules in ${stopwatch.elapsedMilliseconds}ms');
      
      if (snapshot.docs.isEmpty) {
        return [];
      }
      
      final schedules = snapshot.docs
          .map((doc) => Schedule.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      schedules.sort((a, b) => a.date.compareTo(b.date));
      
      return schedules;
    } catch (e) {
      stopwatch.stop();
      print('⏱️ getSchedules() ERROR after ${stopwatch.elapsedMilliseconds}ms: $e');
      return [];
    }
  }

  Future<void> createSchedule(Schedule schedule) async {
    await _firestore.collection('schedules').add(schedule.toMap());
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _firestore.collection('schedules').doc(scheduleId).delete();
  }

  Future<void> updateScheduleAvailability(String scheduleId, bool isAvailable) async {
    await _firestore.collection('schedules').doc(scheduleId).update({
      'isAvailable': isAvailable,
    });
  }

  Future<void> bookScheduleSlot(String scheduleId, String studentId) async {
    final doc = await _firestore.collection('schedules').doc(scheduleId).get();
    if (!doc.exists) return;
    
    final data = doc.data() as Map<String, dynamic>;
    final bookedStudents = List<String>.from(data['bookedStudents'] ?? []);
    
    if (bookedStudents.contains(studentId)) return;
    
    bookedStudents.add(studentId);
    await _firestore.collection('schedules').doc(scheduleId).update({
      'bookedStudents': bookedStudents,
    });
  }

  Future<bool> isSlotAvailable(String scheduleId) async {
    final doc = await _firestore.collection('schedules').doc(scheduleId).get();
    if (!doc.exists) return false;
    
    final data = doc.data() as Map<String, dynamic>;
    final bookedCount = (data['bookedStudents'] as List?)?.length ?? 0;
    final maxStudents = data['maxStudents'] ?? 5;
    final isAvailable = data['isAvailable'] ?? true;
    
    return isAvailable && bookedCount < maxStudents;
  }
    // ---------- Appointment Management ----------
  
  /// Get all tickets for a specific date
  Future<List<QueueTicket>> getTicketsByDate(DateTime date) async {
    try {
      // Create start and end of the day
      final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('queueTickets')
          .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
          .get();
      
      return snapshot.docs
          .map((doc) => QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting tickets by date: $e');
      return [];
    }
  }

  /// Delete a single ticket by ID
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _firestore.collection('queueTickets').doc(ticketId).delete();
    } catch (e) {
      print('❌ Error deleting ticket: $e');
    }
  }

    /// Get tickets for a date range based on the scheduled time slot
  Future<List<QueueTicket>> getTicketsByTimeSlotRange(DateTime startDate, DateTime endDate) async {
    try {
      // Set start to beginning of startDate
      final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      // Set end to end of endDate
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('queueTickets')
          .where('timeSlot', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('timeSlot', isLessThanOrEqualTo: end.toIso8601String())
          .get();
      
      return snapshot.docs
          .map((doc) => QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting tickets by time slot range: $e');
      return [];
    }
  }

  /// Delete tickets by time slot range (for cleanup)
  Future<int> deleteTicketsByTimeSlotRange(DateTime startDate, DateTime endDate) async {
    try {
      final tickets = await getTicketsByTimeSlotRange(startDate, endDate);
      for (var ticket in tickets) {
        await _firestore.collection('queueTickets').doc(ticket.id).delete();
      }
      return tickets.length;
    } catch (e) {
      print('❌ Error deleting tickets by range: $e');
      return 0;
    }
  }

  /// Delete all tickets for a specific date
  Future<int> deleteTicketsByDate(DateTime date) async {
    try {
      final tickets = await getTicketsByDate(date);
      
      if (tickets.isEmpty) {
        return 0;
      }
      
      // Delete each ticket
      for (var ticket in tickets) {
        await deleteTicket(ticket.id);
      }
      
      return tickets.length;
    } catch (e) {
      print('❌ Error deleting tickets by date: $e');
      return 0;
    }
  }

  /// Get all payments for a specific date
  Future<List<Payment>> getPaymentsByDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('payments')
          .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
          .get();
      
      return snapshot.docs
          .map((doc) => Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting payments by date: $e');
      return [];
    }
  }

  /// Delete all payments for a specific date
  Future<int> deletePaymentsByDate(DateTime date) async {
    try {
      final payments = await getPaymentsByDate(date);
      
      if (payments.isEmpty) {
        return 0;
      }
      
      for (var payment in payments) {
        await _firestore.collection('payments').doc(payment.id).delete();
      }
      
      return payments.length;
    } catch (e) {
      print('❌ Error deleting payments by date: $e');
      return 0;
    }
  }

  /// Cleanup - Delete all tickets and payments for a specific date
  Future<Map<String, int>> cleanupAppointmentsByDate(DateTime date) async {
    final result = <String, int>{};
    
    try {
      final ticketsDeleted = await deleteTicketsByDate(date);
      result['tickets'] = ticketsDeleted;
      
      final paymentsDeleted = await deletePaymentsByDate(date);
      result['payments'] = paymentsDeleted;
      
      print('✅ Cleanup completed: $ticketsDeleted tickets, $paymentsDeleted payments');
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
    
    return result;
  }


/// Search tickets by student number, name, or queue number
Future<List<QueueTicket>> searchTickets(String query) async {
  try {
    // Get only active tickets (waiting or serving)
    final snapshot = await _firestore
        .collection('queueTickets')
        .where('status', whereIn: ['waiting', 'serving'])
        .get();

    final queryLower = query.toLowerCase().trim();
    if (queryLower.isEmpty) return [];

    return snapshot.docs
        .map((doc) => QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .where((ticket) =>
            ticket.studentNumber.toLowerCase().contains(queryLower) ||
            ticket.studentName.toLowerCase().contains(queryLower) ||
            ticket.queueNumber.toString() == queryLower)
        .toList();
  } catch (e) {
    print('❌ Error searching tickets: $e');
    return [];
  }
}

/// Get all active tickets (waiting or serving) for cashier
Future<List<QueueTicket>> getActiveTickets() async {
  try {
    final snapshot = await _firestore
        .collection('queueTickets')
        .where('status', whereIn: ['waiting', 'serving'])
        .get();

    return snapshot.docs
        .map((doc) => QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('❌ Error getting active tickets: $e');
    return [];
  }
}

/// Get user by UID
Future<AppUser?> getUserById(String uid) async {
  try {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  } catch (e) {
    print('❌ Error getting user: $e');
    return null;
  }
}
  
}