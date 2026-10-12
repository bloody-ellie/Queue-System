import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../models/queue_ticket.dart';
import '../../services/firestore_service.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<QueueTicket> _allActive = [];
  List<QueueTicket> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveTickets();
  }

  Future<void> _loadActiveTickets() async {
    setState(() => _isLoading = true);
    final tickets = await _fs.getActiveTickets();
    // Sort by queue number
    tickets.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));
    setState(() {
      _allActive = tickets;
      _filtered = tickets;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allActive;
      } else {
        _filtered = _allActive.where((t) =>
            t.studentNumber.toLowerCase().contains(q) ||
            t.studentName.toLowerCase().contains(q) ||
            t.queueNumber.toString().contains(q)).toList();
      }
    });
  }

  Future<void> _updateStatus(QueueTicket ticket, String status) async {
    final provider = Provider.of<QueueProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await provider.updateTicketStatus(ticket.id, status);

    // Confirm payments when served
    if (status == 'served') {
      final payments = await _fs.getPaymentsForTicket(ticket.id);
      for (var payment in payments) {
        await _fs.confirmPayment(payment.id, auth.currentUser!.uid);
      }
    }

    // Refresh list
    await _loadActiveTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveTickets,
          ),
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
      body: Column(
        children: [
          // ✅ Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by student number, name, or queue #',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} active ticket(s)',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No active tickets'
                                  : 'No matching tickets found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final ticket = _filtered[i];
                          return _buildTicketCard(ticket);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(QueueTicket ticket) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Queue # and status
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _statusColor(ticket.status),
                  child: Text(
                    '${ticket.queueNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Student name
                      Text(
                        ticket.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      // ✅ Student number and year level
                      Text(
                        '${ticket.studentNumber} • ${ticket.yearLevel}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(ticket.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(ticket.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Time slot
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Slot: ${_formatDateTime(ticket.timeSlot)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Services summary
            if (ticket.serviceItems.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.list_alt, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Services: ${ticket.serviceItems.map((s) => s.name).join(', ')}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ticket.status == 'waiting')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(ticket, 'serving'),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start Serving'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                if (ticket.status == 'serving') ...[
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(ticket, 'served'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Served'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(ticket, 'passed'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Pass'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'serving':
        return Colors.green;
      case 'served':
        return Colors.blue;
      case 'passed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day}/${date.year} $hour:$minute $period';
  }
}