import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_ticket.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> generateReport(DateTime startDate, DateTime endDate) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        // Fetch all breaks in the date range
    final breaksSnapshot = await _firestore
        .collection('breaks')
        .where('endTime', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('endTime', isLessThanOrEqualTo: end.toIso8601String())
        .get();

    Map<String, int> cashierBreakTimes = {};
    for (var doc in breaksSnapshot.docs) {
      final data = doc.data();
      final name = data['cashierName'] ?? 'Unknown';
      final duration = data['durationSeconds'] as int? ?? 0;
      cashierBreakTimes[name] = (cashierBreakTimes[name] ?? 0) + duration;
    }

    final snapshot = await _firestore
        .collection('queueTickets')
        .where('timeSlot', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timeSlot', isLessThanOrEqualTo: end.toIso8601String())
        .get();

    final tickets = snapshot.docs
        .map((doc) => QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // Initialize counters
    int totalServed = 0;
    int totalPassed = 0;
    int totalTuitionServed = 0; 
    int totalDocumentsRequested = 0; 
    double totalRevenue = 0.0;

    Map<String, int> servedPerDay = {};
    Map<String, int> passedPerDay = {};
    Map<String, int> bookingsPerSchedule = {};
    Map<String, int> documentsRequested = {}; 

    for (var ticket in tickets) {
      final dayKey = '${ticket.timeSlot.month}/${ticket.timeSlot.day}/${ticket.timeSlot.year}';
      
      String scheduleKey = _formatTime(ticket.timeSlot);
      if (ticket.timeSlotEnd != null) {
        scheduleKey += ' - ${_formatTime(ticket.timeSlotEnd!)}';
      }

      // Count Schedule Bookings (Counts ALL tickets, regardless of status)
      bookingsPerSchedule[scheduleKey] = (bookingsPerSchedule[scheduleKey] ?? 0) + 1;

      // ✅ ONLY CALCULATE THESE IF THE STUDENT WAS ACTUALLY SERVED
      if (ticket.status == 'served') {
        totalServed++;
        servedPerDay[dayKey] = (servedPerDay[dayKey] ?? 0) + 1;

        for (var item in ticket.serviceItems) {
          if (item.type == 'tuition') {
            // ✅ THIS is the counter for students served for tuition
            totalTuitionServed++; 
          } else if (item.type == 'document') {
            totalDocumentsRequested++; 
            totalRevenue += item.amount; 
            
            final docName = item.name;
            documentsRequested[docName] = (documentsRequested[docName] ?? 0) + 1;
          }
        }
      } else if (ticket.status == 'passed') {
        totalPassed++;
        passedPerDay[dayKey] = (passedPerDay[dayKey] ?? 0) + 1;
      }
    }

    return {
      'totalTickets': tickets.length,
      'totalServed': totalServed,
      'totalPassed': totalPassed,
      'totalTuitionServed': totalTuitionServed, // ✅ Passed to UI
      'totalDocumentsRequested': totalDocumentsRequested, 
      'totalRevenue': totalRevenue,
      'servedPerDay': servedPerDay,
      'passedPerDay': passedPerDay,
      'bookingsPerSchedule': bookingsPerSchedule,
      'documentsRequested': documentsRequested,
      'cashierBreakTimes': cashierBreakTimes,
    };
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}