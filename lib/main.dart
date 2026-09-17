import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/queue_provider.dart';
import 'screens/login_screen.dart';
import 'services/cleanup_service.dart';  // ✅ ADD THIS IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Firebase Configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCk-xKxJ-TqtuzJji0mt7E4bFK3qjdn7p8",
        authDomain: "queue-system-67874.firebaseapp.com",
        projectId: "queue-system-67874",
        storageBucket: "queue-system-67874.firebasestorage.app",
        messagingSenderId: "488590025606",
        appId: "1:488590025606:web:c324b452c278d5344f8207",
        measurementId: "G-VJBSQVB650",
      ),
    );
    print('✅ Firebase initialized successfully!');
    print('📦 Project: queue-system-67874');
    
    // ✅ Run daily cleanup check
    final cleanupService = CleanupService();
    await cleanupService.runDailyCleanup();
    
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    runApp(ErrorApp(error: e.toString()));
    return;
  }

  runApp(const MyApp());
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to Initialize Firebase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Check your Firebase configuration in main.dart',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Reload the app
                    runApp(const MyApp());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QueueProvider()),
      ],
      child: MaterialApp(
        title: 'Queue System',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}