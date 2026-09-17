import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String day; // 'Monday', 'Tuesday', etc.
  final DateTime date; // Specific date
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int maxStudents; // Max students per slot
  final bool isAvailable;
  final List<String> bookedStudents; // Student UIDs who booked this slot

  Schedule({
    required this.id,
    required this.day,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.maxStudents,
    this.isAvailable = true,
    this.bookedStudents = const [],
  });

  Map<String, dynamic> toMap() => {
        'day': day,
        'date': date.toIso8601String(),
        'startTime': '${startTime.hour}:${startTime.minute}',
        'endTime': '${endTime.hour}:${endTime.minute}',
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'maxStudents': maxStudents,
        'isAvailable': isAvailable,
        'bookedStudents': bookedStudents,
      };

  factory Schedule.fromMap(String id, Map<String, dynamic> map) => Schedule(
        id: id,
        day: map['day'] ?? '',
        date: DateTime.parse(map['date']),
        startTime: TimeOfDay(
          hour: map['startHour'] ?? 9,
          minute: map['startMinute'] ?? 0,
        ),
        endTime: TimeOfDay(
          hour: map['endHour'] ?? 10,
          minute: map['endMinute'] ?? 0,
        ),
        maxStudents: map['maxStudents'] ?? 5,
        isAvailable: map['isAvailable'] ?? true,
        bookedStudents: List<String>.from(map['bookedStudents'] ?? []),
      );

  bool get isFull => bookedStudents.length >= maxStudents;

  String get timeRange => '${_formatTime(startTime)} - ${_formatTime(endTime)}';

  String _formatTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}