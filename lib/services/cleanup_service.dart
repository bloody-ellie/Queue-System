import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_ticket.dart';
import '../models/payment.dart';

class CleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if it's past 5 PM (17:00)
  bool isPastOfficeHours() {
    final now = DateTime.now();
    return now.hour >= 17;
  }

  /// Check if cleanup has already been done today
  Future<bool> wasCleanupDoneToday() async {
    try {
      final doc = await _firestore.collection('system')
          .doc('cleanupLog')
          .get();
      
      if (!doc.exists) return false;
      
      final lastCleanup = doc.data()?['lastCleanup'] as String?;
      if (lastCleanup == null) return false;
      
      final lastDate = DateTime.parse(lastCleanup);
      final today = DateTime.now();
      
      return lastDate.year == today.year &&
             lastDate.month == today.month &&
             lastDate.day == today.day;
    } catch (e) {
      print('❌ Error checking cleanup status: $e');
      return false;
    }
  }

  /// Record that cleanup was done today
  Future<void> recordCleanup() async {
    try {
      await _firestore.collection('system').doc('cleanupLog').set({
        'lastCleanup': DateTime.now().toIso8601String(),
      });
      print('✅ Cleanup recorded');
    } catch (e) {
      print('❌ Error recording cleanup: $e');
    }
  }

  /// Get tickets for a specific date
  Future<List<QueueTicket>> getTicketsByDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('queueTickets')
          .where('timeSlot', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('timeSlot', isLessThanOrEqualTo: end.toIso8601String())
          .get();
      
      return snapshot.docs
          .map((doc) => QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting tickets by date: $e');
      return [];
    }
  }

  /// Get payments for a specific date
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

  /// MAIN: Run daily cleanup (no report generation)
  Future<void> runDailyCleanup() async {
    print('🔄 Running daily cleanup check...');
    
    if (!isPastOfficeHours()) {
      print('⏰ Still office hours (before 5 PM). Skipping cleanup.');
      return;
    }
    
    if (await wasCleanupDoneToday()) {
      print('✅ Cleanup already done today. Skipping.');
      return;
    }
    
    print('🔄 Starting cleanup for previous day...');
    
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      final tickets = await getTicketsByDate(yesterday);
      for (var ticket in tickets) {
        await _firestore.collection('queueTickets').doc(ticket.id).delete();
      }
      
      final payments = await getPaymentsByDate(yesterday);
      for (var payment in payments) {
        await _firestore.collection('payments').doc(payment.id).delete();
      }
      
      await recordCleanup();
      
      print('✅ Cleanup completed!');
      print('  - Deleted ${tickets.length} tickets');
      print('  - Deleted ${payments.length} payments');
    } catch (e) {
      print('❌ Cleanup failed: $e');
    }
  }
}