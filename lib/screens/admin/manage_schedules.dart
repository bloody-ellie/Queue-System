import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/schedule.dart';
import 'package:intl/intl.dart';

class ManageSchedules extends StatefulWidget {
  const ManageSchedules({super.key});

  @override
  State<ManageSchedules> createState() => _ManageSchedulesState();
}

class _ManageSchedulesState extends State<ManageSchedules> {
  final FirestoreService _fs = FirestoreService();
  List<Schedule> _schedules = [];
  bool _isLoading = true;

  // Single Schedule Form State
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _maxStudents = 5;

  // Bulk Generation State
  DateTime? _bulkStartDate;
  DateTime? _bulkEndDate;
  Set<int> _selectedDays = {1, 2, 3, 4, 5}; // 1=Mon, 7=Sun
  TimeOfDay _bulkStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _bulkEndTime = const TimeOfDay(hour: 17, minute: 0);
  int _bulkMaxStudents = 10;
  bool _isBulkGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final schedules = await _fs.getSchedules();
    setState(() {
      _schedules = schedules;
      _isLoading = false;
    });
  }

  void _showBulkGenerateDialog() {
    _bulkStartDate = DateTime.now();
    _bulkEndDate = DateTime.now().add(const Duration(days: 30));
    _selectedDays = {1, 2, 3, 4, 5};
    _bulkStartTime = const TimeOfDay(hour: 8, minute: 0);
    _bulkEndTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Auto-Generate Schedules'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final d = await showDatePicker(context: context, initialDate: _bulkStartDate!, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (d != null) setDialogState(() => _bulkStartDate = d);
                            },
                            child: Text('Start: ${DateFormat('MMM d').format(_bulkStartDate!)}'),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final d = await showDatePicker(context: context, initialDate: _bulkEndDate!, firstDate: _bulkStartDate!, lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (d != null) setDialogState(() => _bulkEndDate = d);
                            },
                            child: Text('End: ${DateFormat('MMM d').format(_bulkEndDate!)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Days of the Week', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (int i = 1; i <= 7; i++)
                          FilterChip(
                            label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i - 1]),
                            selected: _selectedDays.contains(i),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) _selectedDays.add(i);
                                else _selectedDays.remove(i);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Time per Slot', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final t = await showTimePicker(context: context, initialTime: _bulkStartTime);
                              if (t != null) setDialogState(() => _bulkStartTime = t);
                            },
                            child: Text('From: ${_formatTime(_bulkStartTime)}'),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final t = await showTimePicker(context: context, initialTime: _bulkEndTime);
                              if (t != null) setDialogState(() => _bulkEndTime = t);
                            },
                            child: Text('To: ${_formatTime(_bulkEndTime)}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: _isBulkGenerating ? null : () async {
                    setDialogState(() => _isBulkGenerating = true);
                    await _generateBulkSchedules();
                    setDialogState(() => _isBulkGenerating = false);
                    if (mounted) Navigator.pop(context);
                  },
                  child: _isBulkGenerating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateBulkSchedules() async {
    if (_selectedDays.isEmpty || _bulkStartDate == null || _bulkEndDate == null) return;

    List<Schedule> newSchedules = [];
    DateTime current = _bulkStartDate!;

    while (current.isBefore(_bulkEndDate!.add(const Duration(days: 1)))) {
      if (_selectedDays.contains(current.weekday)) {
        newSchedules.add(
          Schedule(
            id: '',
            day: _getDayOfWeek(current),
            date: current,
            startTime: _bulkStartTime,
            endTime: _bulkEndTime,
            maxStudents: _bulkMaxStudents,
            isAvailable: true,
            bookedStudents: [],
          ),
        );
      }
      current = current.add(const Duration(days: 1));
    }

    if (newSchedules.isNotEmpty) {
      await _fs.bulkCreateSchedules(newSchedules);
      _loadSchedules();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Generated ${newSchedules.length} schedules!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _showAddScheduleDialog() {
    _selectedDate = null;
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 0);
    _maxStudents = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Schedule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(_selectedDate == null ? 'Select Date' : 'Date: ${_formatDate(_selectedDate!)}'),
                      subtitle: _selectedDate == null ? null : Text(_getDayOfWeek(_selectedDate!), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate == null || _selectedDate!.isBefore(today) ? today : _selectedDate!,
                          firstDate: today,
                          lastDate: today.add(const Duration(days: 30)),
                        );
                        if (date != null) setDialogState(() => _selectedDate = date);
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text('Start Time: ${_formatTime(_startTime!)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0));
                        if (time != null) setDialogState(() => _startTime = time);
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text('End Time: ${_formatTime(_endTime!)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 0));
                        if (time != null) setDialogState(() => _endTime = time);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Max Students: '),
                        Expanded(
                          child: Slider(
                            value: _maxStudents.toDouble(),
                            min: 1, max: 20, divisions: 19,
                            label: _maxStudents.toString(),
                            onChanged: (value) => setDialogState(() => _maxStudents = value.toInt()),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Text(_maxStudents.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(onPressed: _createSchedule, child: const Text('Create')),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createSchedule() async {
    if (_selectedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pickedDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      if (pickedDay.isBefore(today)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Cannot create schedules for past dates'), backgroundColor: Colors.red));
        return;
      }
    }

    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (_startTime!.hour > _endTime!.hour || (_startTime!.hour == _endTime!.hour && _startTime!.minute >= _endTime!.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
      return;
    }

    final schedule = Schedule(
      id: '',
      day: _getDayOfWeek(_selectedDate!),
      date: _selectedDate!,
      startTime: _startTime!,
      endTime: _endTime!,
      maxStudents: _maxStudents,
      isAvailable: true,
      bookedStudents: [],
    );

    await _fs.createSchedule(schedule);

    if (mounted) {
      Navigator.pop(context);
      _loadSchedules();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule created!')));
    }
  }

  Future<void> _deleteSchedule(Schedule schedule) async {
    if (schedule.bookedStudents.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text('This schedule has ${schedule.bookedStudents.length} student(s) booked.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Delete schedule for ${schedule.dayName} ${_formatDate(schedule.date)} ${schedule.timeRange}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await _fs.deleteSchedule(schedule.id);
      _loadSchedules();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule deleted!')));
    }
  }

  Future<void> _toggleScheduleAvailability(Schedule schedule) async {
    await _fs.updateScheduleAvailability(schedule.id, !schedule.isAvailable);
    _loadSchedules();
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  String _formatTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final visibleSchedules = _schedules.where((s) => !s.isPast).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedules'),
        actions: [
          // ✅ FIXED: Added the missing Bulk Generate button
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
            tooltip: 'Auto-Generate Schedules',
            onPressed: _showBulkGenerateDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Single Schedule',
            onPressed: _showAddScheduleDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : visibleSchedules.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No upcoming schedules.'),
                      Text('Tap + to add a schedule.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: visibleSchedules.length,
                  itemBuilder: (ctx, i) {
                    final schedule = visibleSchedules[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text('${schedule.dayName} - ${schedule.timeRange}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${_formatDate(schedule.date)}'),
                            Text(
                              'Students: ${schedule.bookedStudents.length}/${schedule.maxStudents}',
                              style: TextStyle(color: schedule.isFull ? Colors.red : Colors.green),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(value: schedule.isAvailable, onChanged: (_) => _toggleScheduleAvailability(schedule)),
                            if (schedule.bookedStudents.isEmpty)
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSchedule(schedule)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}