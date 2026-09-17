class Payment {
  final String id;
  final String studentId;
  final double amount;
  final String type; // 'tuition' or 'document'
  final String? documentTypeId; // only if type == 'document'
  final String? documentName; // optional - for display
  final String status; // 'pending' or 'confirmed'
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final String ticketId;

  Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.type,
    this.documentTypeId,
    this.documentName,
    this.status = 'pending',
    this.confirmedBy,
    this.confirmedAt,
    required this.ticketId,
  });

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'amount': amount,
        'type': type,
        'documentTypeId': documentTypeId,
        'documentName': documentName,
        'status': status,
        'confirmedBy': confirmedBy,
        'confirmedAt': confirmedAt?.toIso8601String(),
        'ticketId': ticketId,
      };

  factory Payment.fromMap(String id, Map<String, dynamic> map) => Payment(
        id: id,
        studentId: map['studentId'] ?? '',
        amount: (map['amount'] ?? 0.0).toDouble(),
        type: map['type'] ?? 'tuition',
        documentTypeId: map['documentTypeId'],
        documentName: map['documentName'],
        status: map['status'] ?? 'pending',
        confirmedBy: map['confirmedBy'],
        confirmedAt: map['confirmedAt'] != null
            ? DateTime.parse(map['confirmedAt'])
            : null,
        ticketId: map['ticketId'] ?? '',
      );
}