import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  AuthProvider() {
    // Listen to auth state changes
    _authService.userStream.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    AppUser? user = await _authService.signIn(email, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

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
    return await _authService.createUser(
      email: email,
      password: password,
      name: name,
      role: role,
      studentNumber: studentNumber,
      firstName: firstName,
      lastName: lastName,
      middleInitial: middleInitial,
      yearLevel: yearLevel,
    );
  }
}
