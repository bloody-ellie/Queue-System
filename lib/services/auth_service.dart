import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email/password
  Future<AppUser?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user != null) {
        // fetch user data from Firestore
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return AppUser.fromMap(user.uid, doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  // Create user (admin only, updated for removal of qr-code)
 Future<bool> createUser({
  required String email,
  required String password,
  required String name,
  required String role,
  String? studentNumber,
  String? firstName,
  String? lastName,
  String? middleInitial,
  String? yearLevel,
}) async {
  try {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    User? user = result.user;
    
    if (user != null) {
      AppUser newUser = AppUser(
        uid: user.uid,
        email: email,
        name: name,
        role: role,
        studentNumber: studentNumber,
        firstName: firstName,
        lastName: lastName,
        middleInitial: middleInitial,
        yearLevel: yearLevel,
      );
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      return true;
    }
    return false;
  } catch (e) {
    print('Create user error: $e');
    return false;
  }
}

  // Get current user stream
  Stream<AppUser?> get userStream {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AppUser.fromMap(user.uid, doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}