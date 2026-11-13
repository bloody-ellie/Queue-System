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
        .map((doc) =>
            DocumentType.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> addDocumentType(String name, double price) async {
    await _firestore.collection('documentTypes').add({
      'name': name,
      'price': price,
      'active': true,
    });
  }

  Future<void> updateDocumentType(String id,
      {String? name, double? price, bool? active}) async {
    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (active != null) data['active'] = active;
    await _firestore.collection('documentTypes').doc(id).update(data);
  }

    // ---------- User Management ----------
  
  /// Fetch all users by role ('student' or 'cashier')
  Future<List<AppUser>> getUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      final users = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Sort alphabetically by name
      users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return users;
    } catch (e) {
      print('❌ Error getting users by role: $e');
      return [];
    }
  }

  /// Update a student's editable fields (Student ID is intentionally omitted)
  Future<bool> updateStudentInfo({
    required String uid,
    required String firstName,
    required String lastName,
    required String middleInitial,
    required String yearLevel,
  }) async {
    try {
      final newFullName = '$lastName, $firstName${middleInitial.isNotEmpty ? ' $middleInitial.' : ''}';
      
      await _firestore.collection('users').doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'middleInitial': middleInitial,
        'yearLevel': yearLevel,
        'name': newFullName,
      });
      return true;
    } catch (e) {
      print('❌ Error updating student: $e');
      return false;
    }
  }

  /// Delete a user document from Firestore
  Future<bool> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return true;
    } catch (e) {
      print('❌ Error deleting user: $e');
      return false;
    }
  }

  // ---------- Payments ----------
  Future<String> createPayment(Payment payment) async {
    DocumentReference ref =
        await _firestore.collection('payments').add(payment.toMap());
    return ref.id;
  }

  Future<void> confirmPayment(String paymentId, String cashierUid) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': 'confirmed',
      'confirmedBy': cashierUid,
      'confirmedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Payment>> getPaymentsForTicket(String ticketId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('ticketId', isEqualTo: ticketId)
          .get();
      return snapshot.docs
          .map((doc) =>
              Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting payments for ticket: $e');
      return [];
    }
  }

  // ---------- Queue Tickets ----------
  Future<String> createQueueTicket(QueueTicket ticket) async {
    DocumentReference ref =
        await _firestore.collection('queueTickets').add(ticket.toMap());
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
    DocumentSnapshot doc =
        await _firestore.collection('queueTickets').doc(id).get();
    if (doc.exists) {
      return QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
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
      print('⏱️ getSchedules() found ${snapshot.docs.length} schedules '
          'in ${stopwatch.elapsedMilliseconds}ms');

      if (snapshot.docs.isEmpty) return [];

      final schedules = snapshot.docs
          .map((doc) =>
              Schedule.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      schedules.sort((a, b) => a.date.compareTo(b.date));
      return schedules;
    } catch (e) {
      stopwatch.stop();
      print(
          '⏱️ getSchedules() ERROR after ${stopwatch.elapsedMilliseconds}ms: $e');
      return [];
    }
  }

  Future<void> createSchedule(Schedule schedule) async {
    await _firestore.collection('schedules').add(schedule.toMap());
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _firestore.collection('schedules').doc(scheduleId).delete();
  }

  Future<void> updateScheduleAvailability(
      String scheduleId, bool isAvailable) async {
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

// ---------- Cashier: Active Tickets (TODAY ONLY) ----------
  /// Returns tickets whose scheduled date is EXACTLY today.
  /// Excludes past dates (yesterday and older) AND future dates (tomorrow onwards).
  Future<List<QueueTicket>> getActiveTickets() async {
    try {
      final snapshot = await _firestore
          .collection('queueTickets')
          .where('status', whereIn: ['waiting', 'serving']).get();

      // ✅ Today's boundaries (midnight to 23:59:59)
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return snapshot.docs
          .map((doc) => QueueTicket.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              ))
          .where((ticket) {
        // Only tickets on today's date
        return !ticket.timeSlot.isBefore(startOfToday) &&
            !ticket.timeSlot.isAfter(endOfToday);
      }).toList();
    } catch (e) {
      print('❌ Error getting active tickets: $e');
      return [];
    }
  }

  /// Get document type IDs that the student already has pending
/// (waiting or serving tickets that include that document).
Future<Set<String>> getPendingDocumentIdsForStudent(String studentId) async {
  try {
    final snapshot = await _firestore
        .collection('queueTickets')
        .where('studentId', isEqualTo: studentId)
        .where('status', whereIn: ['waiting', 'serving'])
        .get();

    final docIds = <String>{};
    for (var doc in snapshot.docs) {
      final ticket = QueueTicket.fromMap(
          doc.id, doc.data() as Map<String, dynamic>);
      for (var item in ticket.serviceItems) {
        if (item.type == 'document' && item.documentTypeId != null) {
          docIds.add(item.documentTypeId!);
        }
      }
    }
    return docIds;
  } catch (e) {
    print('❌ Error getting pending documents: $e');
    return <String>{};
  }
}

// ---------- Cashier: Search (TODAY ONLY) ----------
  Future<List<QueueTicket>> searchTickets(String query) async {
    try {
      final snapshot = await _firestore
          .collection('queueTickets')
          .where('status', whereIn: ['waiting', 'serving']).get();

      final queryLower = query.toLowerCase().trim();
      if (queryLower.isEmpty) return [];

      // ✅ Today's boundaries
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return snapshot.docs
          .map((doc) => QueueTicket.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              ))
          .where((ticket) {
        // Skip if not scheduled for today
        if (ticket.timeSlot.isBefore(startOfToday) ||
            ticket.timeSlot.isAfter(endOfToday)) {
          return false;
        }

        // Query match
        return ticket.studentNumber.toLowerCase().contains(queryLower) ||
            ticket.studentName.toLowerCase().contains(queryLower) ||
            ticket.queueNumber.toString() == queryLower;
      }).toList();
    } catch (e) {
      print('❌ Error searching tickets: $e');
      return [];
    }
  }

  // ---------- Payments/Reports for Date Ranges ----------
  Future<List<QueueTicket>> getTicketsByTimeSlotRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final start =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final end =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('queueTickets')
          .where('timeSlot', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('timeSlot', isLessThanOrEqualTo: end.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => QueueTicket.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      print('❌ Error getting tickets by time slot range: $e');
      return [];
    }
  }

  Future<int> deleteTicketsByTimeSlotRange(
      DateTime startDate, DateTime endDate) async {
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
          .map((doc) =>
              Payment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting payments by date: $e');
      return [];
    }
  }
}
