import 'package:flutter/material.dart';
import '../../models/alarm_model.dart';
import '../../services/alarm_service.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({super.key});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _loading = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveAlarm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final alarmDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Sumar 25 segundos quemados para compensar el delay
      final adjustedAlarmDateTime = alarmDateTime.add(const Duration(seconds: 0));

      final alarm = Alarm(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        alarmDateTime: adjustedAlarmDateTime,
        createdAt: DateTime.now(),
      );

      await AlarmService.scheduleAlarm(alarm);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarma creada exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear alarma: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _dateController.clear();
    _timeController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          "Nueva Alarma",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFF6F8F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        // SIN BOTÓN ATRÁS - se usa la bottom navigation
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField("Titulo de la alarma", Icons.title, _titleController, true),
              const SizedBox(height: 16),

              _buildTextField("Descripcion", Icons.description, _descriptionController, true),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDateField("Fecha", Icons.calendar_today, _dateController, _selectDate),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField("Hora", Icons.access_time, _timeController, _selectTime),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _loading ? Colors.grey : const Color(0xFF3FD411),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _saveAlarm,
                child: _loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : const Text(
                  "Crear Alarma",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool isRequired) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      validator: isRequired ? (v) => v!.isEmpty ? "Campo obligatorio" : null : null,
    );
  }

  Widget _buildDateField(String label, IconData icon, TextEditingController controller, VoidCallback onTap) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: _inputDecoration(label, icon),
      validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF3FD411)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3FD411)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFF3FD411).withOpacity(0.4)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF3FD411), width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}