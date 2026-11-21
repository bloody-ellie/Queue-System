class QueueTicket {
  final String id;
  final String studentId;
  final String paymentId;
  final int queueNumber;
  final String status;
  final DateTime timeSlot;      
  final DateTime? timeSlotEnd;  
  final DateTime createdAt;
  final List<ServiceItem> serviceItems;
  final String studentNumber;
  final String studentName;
  final String yearLevel;
  final String? servingCashierId;
  final String? servingCashierName;

  QueueTicket({
    required this.id,
    required this.studentId,
    required this.paymentId,
    required this.queueNumber,
    required this.status,
    required this.timeSlot,
    this.timeSlotEnd,           
    required this.createdAt,
    this.serviceItems = const [],
    this.studentNumber = '',
    this.studentName = '',
    this.yearLevel = '',
    this.servingCashierId,      
    this.servingCashierName,    
  });

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'paymentId': paymentId,
        'queueNumber': queueNumber,
        'status': status,
        'timeSlot': timeSlot.toIso8601String(),
        'timeSlotEnd': timeSlotEnd?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'serviceItems': serviceItems.map((item) => item.toMap()).toList(),
        'studentNumber': studentNumber,
        'studentName': studentName,
        'yearLevel': yearLevel,
        'servingCashierId': servingCashierId,     
        'servingCashierName': servingCashierName,
      };

  factory QueueTicket.fromMap(String id, Map<String, dynamic> map) => QueueTicket(
        id: id,
        studentId: map['studentId'] ?? '',
        paymentId: map['paymentId'] ?? '',
        queueNumber: map['queueNumber'] ?? 0,
        status: map['status'] ?? 'waiting',
        timeSlot: DateTime.parse(map['timeSlot']),
        timeSlotEnd: map['timeSlotEnd'] != null 
            ? DateTime.parse(map['timeSlotEnd']) 
            : null, 
        createdAt: DateTime.parse(map['createdAt']),
        serviceItems: (map['serviceItems'] as List?)
                ?.map((item) => ServiceItem.fromMap(item))
                .toList() ?? [],
        studentNumber: map['studentNumber'] ?? '',
        studentName: map['studentName'] ?? '',
        yearLevel: map['yearLevel'] ?? '',
        servingCashierId: map['servingCashierId'],       
        servingCashierName: map['servingCashierName'],
      );
}

// ServiceItem class remains the same
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