class AppUser {
  final String uid;
  final String email;
  final String name; // Full name (for backward compatibility)
  final String role; // 'admin', 'cashier', 'student'
  
  // ✅ Student-specific fields
  final String? studentNumber;   // e.g., "2023-00123"
  final String? firstName;
  final String? lastName;
  final String? middleInitial;   // e.g., "D"
  final String? yearLevel;       // e.g., "1st Year", "2nd Year"

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.studentNumber,
    this.firstName,
    this.lastName,
    this.middleInitial,
    this.yearLevel,
  });

  /// Get formatted full name with middle initial
  /// Example: "Dela Cruz, Juan D."
  String get fullName {
    if (firstName == null && lastName == null) return name;
    final mi = middleInitial != null && middleInitial!.isNotEmpty 
        ? ' ${middleInitial}.' 
        : '';
    return '$lastName, $firstName$mi';
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'studentNumber': studentNumber,
        'firstName': firstName,
        'lastName': lastName,
        'middleInitial': middleInitial,
        'yearLevel': yearLevel,
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        email: map['email'] ?? '',
        name: map['name'] ?? '',
        role: map['role'] ?? 'student',
        studentNumber: map['studentNumber'],
        firstName: map['firstName'],
        lastName: map['lastName'],
        middleInitial: map['middleInitial'],
        yearLevel: map['yearLevel'],
      );
}