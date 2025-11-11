import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AlarmDialog extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onDismiss;

  const AlarmDialog({
    super.key,
    required this.alarm,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active,
              size: 50,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              alarm.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              alarm.description,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${alarm.formattedDate} a las ${alarm.formattedTime}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3FD411),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss();
                },
                child: const Text(
                  'Cerrar Alarma',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, Alarm alarm, VoidCallback onDismiss) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlarmDialog(alarm: alarm, onDismiss: onDismiss),
    );
  }
}