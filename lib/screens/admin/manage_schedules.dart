import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/schedule.dart';

class ManageSchedules extends StatefulWidget {
  const ManageSchedules({super.key});

  @override
  State<ManageSchedules> createState() => _ManageSchedulesState();
}

class _ManageSchedulesState extends State<ManageSchedules> {
  final FirestoreService _fs = FirestoreService();
  List<Schedule> _schedules = [];
  bool _isLoading = true;

  // Form controllers
  final _dayController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _maxStudents = 5;

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

  void _showAddScheduleDialog() {
    _dayController.clear();
    _selectedDate = DateTime.now();
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
                    TextField(
                      controller: _dayController,
                      decoration: const InputDecoration(
                        labelText: 'Day (e.g., Monday)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : 'Date: ${_formatDate(_selectedDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        'Start Time: ${_formatTime(_startTime!)}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (time != null) {
                          setDialogState(() {
                            _startTime = time;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        'End Time: ${_formatTime(_endTime!)}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (time != null) {
                          setDialogState(() {
                            _endTime = time;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Max Students: '),
                        Expanded(
                          child: Slider(
                            value: _maxStudents.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: _maxStudents.toString(),
                            onChanged: (value) {
                              setDialogState(() {
                                _maxStudents = value.toInt();
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _maxStudents.toString(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _createSchedule,
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createSchedule() async {
    if (_maxStudents < 1) {
      _maxStudents = 5;
    }

    if (_dayController.text.isEmpty ||
        _selectedDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_startTime!.hour > _endTime!.hour ||
        (_startTime!.hour == _endTime!.hour &&
            _startTime!.minute >= _endTime!.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final schedule = Schedule(
      id: '',
      day: _dayController.text,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule created!')),
      );
    }
  }

  // ✅ DELETE SCHEDULE - RESTORED
  Future<void> _deleteSchedule(Schedule schedule) async {
    // Prevent deletion if students have booked
    if (schedule.bookedStudents.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text(
            'This schedule has ${schedule.bookedStudents.length} student(s) booked. '
            'You cannot delete it unless you remove the bookings first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Delete schedule for ${schedule.day} ${schedule.timeRange}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _fs.deleteSchedule(schedule.id);
      _loadSchedules();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule deleted!')),
      );
    }
  }

  Future<void> _toggleScheduleAvailability(Schedule schedule) async {
    await _fs.updateScheduleAvailability(schedule.id, !schedule.isAvailable);
    _loadSchedules();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddScheduleDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No schedules created yet.'),
                      Text(
                        'Tap the + button to add a schedule.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _schedules.length,
                  itemBuilder: (ctx, i) {
                    final schedule = _schedules[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text('${schedule.day} - ${schedule.timeRange}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${_formatDate(schedule.date)}'),
                            Text(
                              'Students: ${schedule.bookedStudents.length}/${schedule.maxStudents}',
                              style: TextStyle(
                                color: schedule.isFull ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: schedule.isAvailable,
                              onChanged: (_) => _toggleScheduleAvailability(schedule),
                            ),
                            // ✅ DELETE BUTTON - RESTORED
                            if (schedule.bookedStudents.isEmpty)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteSchedule(schedule),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}