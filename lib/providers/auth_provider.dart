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

  Future<bool> createUser(String email, String password, String name, String role) async {
    return await _authService.createUser(email, password, name, role);
  }
}