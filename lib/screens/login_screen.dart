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
  bool _obscurePassword = true;

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
      appBar: AppBar(title: const Text('Queue System Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v!.contains('@') ? null : 'Invalid email',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword, 
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (v) => v!.length >= 6 ? null : 'Min 6 chars',
              ),
              const SizedBox(height: 12),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Sign In'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Check credentials.')),
        );
      }
    }
  }

  void _navigateToRole(String role) {
    Widget screen;
    switch (role) {
      case 'admin':
        screen = const AdminDashboard();
        break;
      case 'cashier':
        screen = const CashierDashboard();
        break;
      case 'student':
        screen = const StudentDashboard();
        break;
      default:
        screen = const LoginScreen();
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => screen));
  }
}