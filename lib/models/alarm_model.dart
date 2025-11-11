import 'package:cloud_firestore/cloud_firestore.dart';

class Alarm {
  String id;
  String title;
  String description;
  DateTime alarmDateTime;
  bool isActive;
  DateTime createdAt;

  Alarm({
    required this.id,
    required this.title,
    required this.description,
    required this.alarmDateTime,
    this.isActive = true,
    required this.createdAt,
  });

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      alarmDateTime: (map['alarmDateTime'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'alarmDateTime': Timestamp.fromDate(alarmDateTime),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get formattedDate {
    return '${alarmDateTime.day}/${alarmDateTime.month}/${alarmDateTime.year}';
  }

  String get formattedTime {
    return '${alarmDateTime.hour.toString().padLeft(2, '0')}:${alarmDateTime.minute.toString().padLeft(2, '0')}';
  }

  bool get isToday {
    final now = DateTime.now();
    return alarmDateTime.year == now.year &&
        alarmDateTime.month == now.month &&
        alarmDateTime.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return alarmDateTime.year == tomorrow.year &&
        alarmDateTime.month == tomorrow.month &&
        alarmDateTime.day == tomorrow.day;
  }
}