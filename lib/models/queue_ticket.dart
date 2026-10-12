class QueueTicket {
  final String id;
  final String studentId;
  final String paymentId;
  final int queueNumber;
  final String status; // 'waiting', 'serving', 'served', 'passed'
  final DateTime timeSlot;
  final DateTime createdAt;
  final List<ServiceItem> serviceItems;

  // ✅ NEW: Student info snapshot (for fast cashier lookup)
  final String studentNumber;
  final String studentName;
  final String yearLevel;

  QueueTicket({
    required this.id,
    required this.studentId,
    required this.paymentId,
    required this.queueNumber,
    required this.status,
    required this.timeSlot,
    required this.createdAt,
    this.serviceItems = const [],
    this.studentNumber = '',
    this.studentName = '',
    this.yearLevel = '',
  });

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'paymentId': paymentId,
        'queueNumber': queueNumber,
        'status': status,
        'timeSlot': timeSlot.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'serviceItems': serviceItems.map((item) => item.toMap()).toList(),
        'studentNumber': studentNumber,
        'studentName': studentName,
        'yearLevel': yearLevel,
      };

  factory QueueTicket.fromMap(String id, Map<String, dynamic> map) => QueueTicket(
        id: id,
        studentId: map['studentId'] ?? '',
        paymentId: map['paymentId'] ?? '',
        queueNumber: map['queueNumber'] ?? 0,
        status: map['status'] ?? 'waiting',
        timeSlot: DateTime.parse(map['timeSlot']),
        createdAt: DateTime.parse(map['createdAt']),
        serviceItems: (map['serviceItems'] as List?)
                ?.map((item) => ServiceItem.fromMap(item))
                .toList() ??
            [],
        studentNumber: map['studentNumber'] ?? '',
        studentName: map['studentName'] ?? '',
        yearLevel: map['yearLevel'] ?? '',
      );
}

// ServiceItem class stays the same
class ServiceItem {
  final String name;
  final String type;
  final double amount;
  final String? documentTypeId;

  ServiceItem({
    required this.name,
    required this.type,
    required this.amount,
    this.documentTypeId,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'amount': amount,
        'documentTypeId': documentTypeId,
      };

  factory ServiceItem.fromMap(Map<String, dynamic> map) => ServiceItem(
        name: map['name'] ?? '',
        type: map['type'] ?? 'document',
        amount: (map['amount'] ?? 0.0).toDouble(),
        documentTypeId: map['documentTypeId'],
      );
}