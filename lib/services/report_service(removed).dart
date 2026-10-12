import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';
import '../models/queue_ticket.dart';
import '../models/daily_report.dart';
import '../models/document_type.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a daily report for a specific date
  Future<DailyReport?> generateReport(DateTime date) async {
    try {
      print('📊 Generating report for ${_formatDate(date)}...');
      
      // Get all tickets for the date (only "served" ones)
      final tickets = await _getServedTickets(date);
      
      // Get all payments for the date
      final payments = await _getPaymentsForDate(date);
      
      // Get document types for mapping
      final documentTypes = await _getDocumentTypes();
      
      // Calculate statistics
      final studentsServed = tickets.length;
      final tuitionPayments = payments.where((p) => p.type == 'tuition').length;
      final documentPayments = payments.where((p) => p.type == 'document').length;
      
      // Count document requests by type
      final documentRequests = <String, int>{};
      for (var payment in payments.where((p) => p.type == 'document')) {
        final docId = payment.documentTypeId;
        if (docId != null) {
          final docName = documentTypes[docId] ?? 'Unknown Document';
          documentRequests[docName] = (documentRequests[docName] ?? 0) + 1;
        }
      }
      
      // Calculate total revenue
      double totalRevenue = 0.0;
      for (var payment in payments) {
        totalRevenue += payment.amount;
      }
      
      final report = DailyReport(
        id: '',
        reportDate: date,
        generatedAt: DateTime.now(),
        studentsServed: studentsServed,
        tuitionPayments: tuitionPayments,
        documentPayments: documentPayments,
        documentRequests: documentRequests,
        totalTransactions: payments.length,
        totalRevenue: totalRevenue,
      );
      
      print('📊 Report generated:');
      print('  - Students Served: $studentsServed');
      print('  - Tuition: $tuitionPayments');
      print('  - Documents: $documentPayments');
      print('  - Revenue: ₱${totalRevenue.toStringAsFixed(2)}');
      
      return report;
    } catch (e) {
      print('❌ Error generating report: $e');
      return null;
    }
  }

  /// Save report to Firestore
  Future<void> saveReport(DailyReport report) async {
    try {
      final docRef = await _firestore.collection('dailyReports').add(report.toMap());
      print('✅ Report saved with ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error saving report: $e');
    }
  }

  /// Get all reports (for admin viewing)
  Future<List<DailyReport>> getAllReports() async {
    try {
      final snapshot = await _firestore
          .collection('dailyReports')
          .orderBy('reportDate', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => DailyReport.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting reports: $e');
      return [];
    }
  }

  /// Get reports for a specific date range
  Future<List<DailyReport>> getReportsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('dailyReports')
          .where('reportDate', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('reportDate', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('reportDate', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => DailyReport.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting reports: $e');
      return [];
    }
  }

  // ---------- Private Helper Methods ----------

  Future<List<QueueTicket>> _getServedTickets(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('queueTickets')
          .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
          .where('status', isEqualTo: 'served')  // ✅ Only "served", not "passed"
          .get();
      
      return snapshot.docs
          .map((doc) => QueueTicket.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting served tickets: $e');
      return [];
    }
  }

  Future<List<Payment>> _getPaymentsForDate(DateTime date) async {
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
      print('❌ Error getting payments: $e');
      return [];
    }
  }

  Future<Map<String, String>> _getDocumentTypes() async {
    try {
      final snapshot = await _firestore.collection('documentTypes').get();
      final result = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        result[doc.id] = data['name'] ?? 'Unknown';
      }
      return result;
    } catch (e) {
      print('❌ Error getting document types: $e');
      return {};
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}