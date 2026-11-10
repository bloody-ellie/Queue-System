class Payment {
  final String id;
  final String studentId;
  final double amount;
  final String type;
  final String? documentTypeId;
  final String? documentName;
  final String status;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final String ticketId;
  final DateTime createdAt;   // ✅ NEW

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
    DateTime? createdAt,     // ✅ optional in constructor
  }) : createdAt = createdAt ?? DateTime.now();

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
        'createdAt': createdAt.toIso8601String(),   // ✅ saved now
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
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
      );
}