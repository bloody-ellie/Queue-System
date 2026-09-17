class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin', 'cashier', 'student'

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        email: map['email'] ?? '',
        name: map['name'] ?? '',
        role: map['role'] ?? 'student',
      );
}