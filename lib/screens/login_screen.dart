import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_dashboard.dart';
import 'cashier/cashier_dashboard.dart';
import 'student/student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // If already logged in, redirect
    if (authProvider.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToRole(authProvider.currentUser!.role);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('Queue System Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (v) => v!.contains('@') ? null : 'Invalid email',
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
                validator: (v) => v!.length >= 6 ? null : 'Min 6 chars',
              ),
              SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text('Sign In'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.signIn(
      _emailController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (success) {
      _navigateToRole(auth.currentUser!.role);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Check credentials.')),
      );
    }
  }

  void _navigateToRole(String role) {
    Widget screen;
    switch (role) {
      case 'admin':
        screen = AdminDashboard();
        break;
      case 'cashier':
        screen = CashierDashboard();
        break;
      case 'student':
        screen = StudentDashboard();
        break;
      default:
        screen = LoginScreen();
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => screen));
  }
}