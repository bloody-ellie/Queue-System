class QueueTicket {
  final String id;
  final String studentId;
  final String paymentId;
  final int queueNumber;
  final String status; // 'waiting', 'serving', 'served', 'passed'
  final DateTime timeSlot; // reserved time slot
  final String qrCode; // unique string (e.g., ticket id)
  final DateTime createdAt;

  QueueTicket({
    required this.id,
    required this.studentId,
    required this.paymentId,
    required this.queueNumber,
    required this.status,
    required this.timeSlot,
    required this.qrCode,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'paymentId': paymentId,
        'queueNumber': queueNumber,
        'status': status,
        'timeSlot': timeSlot.toIso8601String(),
        'qrCode': qrCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QueueTicket.fromMap(String id, Map<String, dynamic> map) =>
      QueueTicket(
        id: id,
        studentId: map['studentId'] ?? '',
        paymentId: map['paymentId'] ?? '',
        queueNumber: map['queueNumber'] ?? 0,
        status: map['status'] ?? 'waiting',
        timeSlot: DateTime.parse(map['timeSlot']),
        qrCode: map['qrCode'] ?? '',
        createdAt: DateTime.parse(map['createdAt']),
      );
}