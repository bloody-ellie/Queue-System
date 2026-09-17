import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'manage_documents.dart';
import 'manage_users.dart';
import 'manage_schedules.dart';
import 'manage_appointments.dart'; 
import 'daily_report_screen.dart';  

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              context,
              'Manage Document Types',
              Icons.description,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageDocuments()),
              ),
            ),
            _buildCard(
              context,
              'Manage Users (Students/Cashiers)',
              Icons.people,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageUsers()),
              ),
            ),
            _buildCard(
  context,
  'View Daily Reports',
  Icons.receipt_long,
  () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const DailyReportScreen()),
  ),
),
            _buildCard(
              context,
              'Manage Schedules & Time Slots',
              Icons.calendar_today,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageSchedules()),
              ),
            ),
 // ✅ NEW CARD
            _buildCard(
              context,
              'Manage Appointments (Delete by Date)',
              Icons.delete_sweep,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageAppointments()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 32, color: Colors.blue.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}