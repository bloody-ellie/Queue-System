class DailyReport {
  final String id;
  final DateTime reportDate;          // Date of the report
  final DateTime generatedAt;          // When report was generated
  
  // Statistics
  final int studentsServed;            // Total students with status "served"
  final int tuitionPayments;           // Students who paid for tuition
  final int documentPayments;          // Students who paid for documents
  final Map<String, int> documentRequests; // Document type -> count
  
  // Summary
  final int totalTransactions;
  final double totalRevenue;

  DailyReport({
    required this.id,
    required this.reportDate,
    required this.generatedAt,
    required this.studentsServed,
    required this.tuitionPayments,
    required this.documentPayments,
    required this.documentRequests,
    required this.totalTransactions,
    required this.totalRevenue,
  });

  Map<String, dynamic> toMap() => {
        'reportDate': reportDate.toIso8601String(),
        'generatedAt': generatedAt.toIso8601String(),
        'studentsServed': studentsServed,
        'tuitionPayments': tuitionPayments,
        'documentPayments': documentPayments,
        'documentRequests': documentRequests,
        'totalTransactions': totalTransactions,
        'totalRevenue': totalRevenue,
      };

  factory DailyReport.fromMap(String id, Map<String, dynamic> map) => DailyReport(
        id: id,
        reportDate: DateTime.parse(map['reportDate']),
        generatedAt: DateTime.parse(map['generatedAt']),
        studentsServed: map['studentsServed'] ?? 0,
        tuitionPayments: map['tuitionPayments'] ?? 0,
        documentPayments: map['documentPayments'] ?? 0,
        documentRequests: Map<String, int>.from(map['documentRequests'] ?? {}),
        totalTransactions: map['totalTransactions'] ?? 0,
        totalRevenue: (map['totalRevenue'] ?? 0.0).toDouble(),
      );

  // Helper to get total document requests
  int get totalDocumentRequests => 
      documentRequests.values.fold(0, (sum, count) => sum + count);
}