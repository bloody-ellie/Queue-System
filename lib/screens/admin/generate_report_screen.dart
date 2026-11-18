import 'package:flutter/material.dart';
import '../../services/report_service.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  final ReportService _reportService = ReportService();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) return;
    setState(() {
      _isLoading = true;
      _reportData = null;
    });

    try {
      final data = await _reportService.generateReport(_startDate!, _endDate!);
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DATE PICKERS ---
            const Text('Select Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
                      if (d != null) setState(() => _startDate = d);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate == null ? 'Start Date' : '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_startDate == null) return;
                      final d = await showDatePicker(context: context, initialDate: _endDate ?? _startDate!, firstDate: _startDate!, lastDate: DateTime(2030));
                      if (d != null) setState(() => _endDate = d);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate == null ? 'End Date' : '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_startDate != null && _endDate != null && !_isLoading) ? _generateReport : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Generate Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(height: 32),

            // --- RESULTS ---
            if (_reportData != null)
              Expanded(
                child: ListView(
                  children: [
                    _buildSection('Cashier Break Times (Tardiness Tracking)', [
                      if (_reportData!['cashierBreakTimes'] != null && (_reportData!['cashierBreakTimes'] as Map).isNotEmpty)
                        ...(_reportData!['cashierBreakTimes'] as Map<String, int>).entries.map((entry) {
                          final minutes = (entry.value / 60).toStringAsFixed(1);
                          return _buildRow(entry.key, '$minutes mins', Colors.red);
                        }).toList()
                      else
                        const Text('No breaks recorded in this period.', style: TextStyle(color: Colors.grey)),
                    ]),
                    _buildSection('Overview (Based on Served Transactions)', [
                      _buildRow('Total Tickets Booked', '${_reportData!['totalTickets']}'),
                      _buildRow('Total Students Served', '${_reportData!['totalServed']}', Colors.green),
                      _buildRow('Total Students Passed', '${_reportData!['totalPassed']}', Colors.red),
                      const Divider(),
                      // ✅ ADDED/UPDATED THIS LABEL
                      _buildRow('Total Students Served (Tuition)', '${_reportData!['totalTuitionServed']}', Colors.orange), 
                      _buildRow('Total Documents Requested', '${_reportData!['totalDocumentsRequested']}'),
                      _buildRow('Total Document Revenue', '₱${_reportData!['totalRevenue'].toStringAsFixed(2)}', Colors.blue),
                    ]),

                    _buildSection('Served per Day', _buildMapRows(_reportData!['servedPerDay'], Colors.green)),
                    
                    _buildSection('Passed per Day', _buildMapRows(_reportData!['passedPerDay'], Colors.red)),

                    _buildSection('Bookings per Schedule (All)', _buildMapRows(_reportData!['bookingsPerSchedule'], Colors.orange)),

                    _buildSection('Document Breakdown (Served Only)', _buildMapRows(_reportData!['documentsRequested'], Colors.purple)),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              )
            else if (!_isLoading)
              const Expanded(
                child: Center(child: Text('Select a date range and click Generate.', style: TextStyle(color: Colors.grey))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, dynamic content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            const Divider(),
            if (content is List<Widget>) ...content else content,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.black)),
        ],
      ),
    );
  }

  List<Widget> _buildMapRows(Map<String, dynamic>? map, Color color) {
    if (map == null || map.isEmpty) return [const Text('No data available for this period.', style: TextStyle(color: Colors.grey))];
    
    // Sort by highest count
    final sortedEntries = map.entries.toList()..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return sortedEntries.map((e) => _buildRow(e.key, '${e.value}', color)).toList();
  }
}