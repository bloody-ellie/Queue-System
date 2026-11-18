class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role;
  
  final String? studentNumber;
  final String? firstName;
  final String? lastName;
  final String? middleInitial;
  final String? yearLevel;
  final String? course;
  
  final bool isActive; 

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
    this.course,
    this.isActive = true, // Default to true when created
  });

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
        'course': course,
        'isActive': isActive,
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
        course: map['course'],
        isActive: map['isActive'] ?? true, 
      );
}