import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_type.dart';
import '../models/payment.dart';
import '../models/queue_ticket.dart';
import '../models/schedule.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> bulkCreateSchedules(List<Schedule> schedules) async {
    try {
      final batch = _firestore.batch();
      
      for (var schedule in schedules) {
        final docRef = _firestore.collection('schedules').doc();
        batch.set(docRef, schedule.toMap());
      }
      
      await batch.commit();
      print('✅ Successfully bulk created ${schedules.length} schedules');
    } catch (e) {
      print('❌ Error bulk creating schedules: $e');
      rethrow;
    }
  }

    /// Check if a student number already exists in the database
  Future<bool> isStudentNumberTaken(String studentNumber) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('studentNumber', isEqualTo: studentNumber.trim())
          .get();
      
      // If the snapshot has documents, the student number is taken
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking student number: $e');
      return false; 
    }
  }
  
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
              Payment.fromMap(doc.id, doc.data()))
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
    DateTime end = start.add(const Duration(hours: 1));
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
                Schedule.fromMap(doc.id, doc.data()))
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
  Future<List<QueueTicket>> getActiveTickets() async {
    try {
      final snapshot = await _firestore
          .collection('queueTickets')
          .where('status', whereIn: ['waiting', 'serving'])
          .get();

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final tickets = snapshot.docs
          .map((doc) => QueueTicket.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              ))
          .where((ticket) {
            return !ticket.timeSlot.isBefore(startOfToday) &&
                   !ticket.timeSlot.isAfter(endOfToday);
          }).toList();
          
      // ✅ THIS is the magic that sorts 9AM first, then 10AM.
      tickets.sort((a, b) {
        int timeCompare = a.timeSlot.compareTo(b.timeSlot);
        if (timeCompare != 0) return timeCompare; 
        return a.queueNumber.compareTo(b.queueNumber); 
      });
          
      return tickets;
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
          doc.id, doc.data());
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
                doc.data(),
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
                doc.data(),
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
  // ---------- User Status ----------
  Future<void> updateUserStatus(String uid, bool isActive) async {
    try {
      // 1. Update the user's active status
      await _firestore.collection('users').doc(uid).update({'isActive': isActive});

      // 2. If deactivating, clean up their active tickets
      if (!isActive) {
        // Find all waiting or serving tickets for this student
        final ticketsSnap = await _firestore
            .collection('queueTickets')
            .where('studentId', isEqualTo: uid)
            .where('status', whereIn: ['waiting', 'serving'])
            .get();

        for (var doc in ticketsSnap.docs) {
          final data = doc.data();
          final ticketId = doc.id;
          final timeSlot = DateTime.parse(data['timeSlot']);

          // A. Delete associated payments
          final payments = await getPaymentsForTicket(ticketId);
          for (var payment in payments) {
            await _firestore.collection('payments').doc(payment.id).delete();
          }

          // B. Delete the queue ticket
          await doc.reference.delete();

          // C. Free up the schedule slot
          final schedulesSnap = await _firestore.collection('schedules').get();
          for (var scheduleDoc in schedulesSnap.docs) {
            final scheduleData = scheduleDoc.data();
            final bookedStudents = List<String>.from(scheduleData['bookedStudents'] ?? []);
            
            if (bookedStudents.contains(uid)) {
              final scheduleDate = DateTime.parse(scheduleData['date']);
              if (scheduleDate.year == timeSlot.year &&
                  scheduleDate.month == timeSlot.month &&
                  scheduleDate.day == timeSlot.day &&
                  scheduleData['startHour'] == timeSlot.hour &&
                  scheduleData['startMinute'] == timeSlot.minute) {
                
                bookedStudents.remove(uid); // Remove one instance
                await scheduleDoc.reference.update({'bookedStudents': bookedStudents});
                break; 
              }
            }
          }
        }
        print('✅ Deactivated student $uid and cleaned up their active tickets.');
      }
    } catch (e) {
      print('❌ Error updating user status: $e');
    }
  }
   // ---------- Notifications ----------
  Future<void> sendNotification(String title, String message) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  // ✅ NEW: Mark notifications as read
  Future<void> markNotificationsAsRead(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastReadNotificationTime': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error marking notifications as read: $e');
    }
  }
  
    // ---------- Bulk Delete Schedules ----------
  Future<int> bulkDeleteSchedulesByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      // 1. Find all schedules in this range
      final snapshot = await _firestore
          .collection('schedules')
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .get();

      if (snapshot.docs.isEmpty) return 0;

      // 2. Delete them using a batch
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error bulk deleting schedules: $e');
      return 0;
    }
  }

  // ---------- Cancel Student Booking ----------
  Future<bool> cancelStudentTicket(QueueTicket ticket) async {
    try {
      // 1. Delete the queue ticket
      await _firestore.collection('queueTickets').doc(ticket.id).delete();
      
      // 2. Delete associated payments
      final payments = await getPaymentsForTicket(ticket.id);
      for (var payment in payments) {
        await _firestore.collection('payments').doc(payment.id).delete();
      }

      // 3. Free up the slot in the schedule
      final schedulesSnap = await _firestore.collection('schedules').get();
      for (var doc in schedulesSnap.docs) {
        final data = doc.data();
        final bookedStudents = List<String>.from(data['bookedStudents'] ?? []);
        
        if (bookedStudents.contains(ticket.studentId)) {
          // Ensure we are freeing up the CORRECT schedule by matching date/time
          final scheduleDate = DateTime.parse(data['date']);
          if (scheduleDate.year == ticket.timeSlot.year &&
              scheduleDate.month == ticket.timeSlot.month &&
              scheduleDate.day == ticket.timeSlot.day &&
              data['startHour'] == ticket.timeSlot.hour &&
              data['startMinute'] == ticket.timeSlot.minute) {
            
            bookedStudents.remove(ticket.studentId); 
            await doc.reference.update({'bookedStudents': bookedStudents});
            break; 
          }
        }
      }
      return true;
    } catch (e) {
      print('❌ Error cancelling ticket: $e');
      return false;
    }
  }
  // ---------- Ticket Locking ----------
  Future<void> startServingTicket(String ticketId, String cashierId, String cashierName) async {
    await _firestore.collection('queueTickets').doc(ticketId).update({
      'status': 'serving',
      'servingCashierId': cashierId,
      'servingCashierName': cashierName,
    });
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
              Payment.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting payments by date: $e');
      return [];
    }
  }
}
