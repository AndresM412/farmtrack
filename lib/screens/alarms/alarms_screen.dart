import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/alarm_model.dart';
import '../../services/alarm_service.dart';
import '../../widgets/alarm_dialog.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'add_alarm_screen.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  final List<Alarm> _activeAlarms = [];
  Timer? _alarmChecker;

  @override
  void initState() {
    super.initState();
    _startAlarmChecker();
  }

  @override
  void dispose() {
    _alarmChecker?.cancel();
    super.dispose();
  }

  void _startAlarmChecker() {
    _alarmChecker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    if (!mounted) return;

    for (final alarm in _activeAlarms) {
      if (AlarmService.shouldShowAlarm(alarm)) {
        _showAlarmDialog(alarm);
      }
    }

    final now = DateTime.now();
    if (now.second == 0) {
      AlarmService.cleanOldAlarms();
    }
  }

  void _showAlarmDialog(Alarm alarm) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlarmDialog.show(
        context,
        alarm,
            () {
          AlarmService.markAlarmAsShown(alarm.id);
          if (mounted) {
            setState(() {
              _activeAlarms.removeWhere((a) => a.id == alarm.id);
            });
          }
        },
      );
    });
  }

  Widget _buildAlarmSection(String title, List<Alarm> alarms) {
    if (alarms.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3FD411),
          ),
        ),
        const SizedBox(height: 12),
        ...alarms.map((alarm) => _buildAlarmCard(alarm)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAlarmCard(Alarm alarm) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF3FD411).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications,
            color: const Color(0xFF3FD411),
          ),
        ),
        title: Text(
          alarm.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alarm.description),
            const SizedBox(height: 4),
            Text(
              '${alarm.formattedDate} a las ${alarm.formattedTime}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Switch(
          value: alarm.isActive,
          onChanged: (value) {
            AlarmService.toggleAlarm(alarm.id, value);
          },
          activeColor: const Color(0xFF3FD411),
        ),
        onLongPress: () {
          _showDeleteDialog(alarm);
        },
      ),
    );
  }

  void _showDeleteDialog(Alarm alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alarma'),
        content: const Text('¿Estás seguro de que quieres eliminar esta alarma?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              AlarmService.deleteAlarm(alarm.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          "Sistema de Alarmas",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFF6F8F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        // BOTÓN ATRÁS ELIMINADO
      ),
      body: StreamBuilder<List<Alarm>>(
        stream: AlarmService.getAlarmsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Color(0xFF3FD411),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay alarmas programadas',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final alarms = snapshot.data!;
          _activeAlarms.clear();
          _activeAlarms.addAll(alarms.where((a) => a.isActive));

          final todayAlarms = alarms.where((a) => a.isToday).toList();
          final tomorrowAlarms = alarms.where((a) => a.isTomorrow).toList();
          final upcomingAlarms = alarms
              .where((a) => !a.isToday && !a.isTomorrow && a.alarmDateTime.isAfter(DateTime.now()))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAlarmSection('Hoy', todayAlarms),
                _buildAlarmSection('Mañana', tomorrowAlarms),
                _buildAlarmSection('Próximas', upcomingAlarms),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAlarmScreen()),
          );
        },
        backgroundColor: const Color(0xFF3FD411),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}