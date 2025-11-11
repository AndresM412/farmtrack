import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:intl/intl.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _razaController = TextEditingController();
  final TextEditingController _fechaNacimientoController = TextEditingController();
  final TextEditingController _inseminacionController = TextEditingController();
  final TextEditingController _partoController = TextEditingController();
  final TextEditingController _lactanciaController = TextEditingController();

  // State variables for dates
  DateTime? _fechaNacimiento;
  DateTime? _inseminacion;
  DateTime? _parto;
  DateTime? _lactancia;

  String _tipo = "Vaca";
  String _estadoReproductivo = "Seca";
  String _estadoSalud = "Saludable";
  XFile? _selectedImage;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _pickDate(TextEditingController controller, Function(DateTime) onDateSelected) async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        controller.text = _dateFormat.format(picked);
        onDateSelected(picked);
      }
    } catch (e) {
      _showError('Error al seleccionar fecha: $e');
    }
  }

  void _calculateEstimatedDates(DateTime inseminacionDate) {
    setState(() {
      _inseminacion = inseminacionDate;
      _parto = inseminacionDate.add(const Duration(days: 283));
      _partoController.text = _dateFormat.format(_parto!);
      _lactancia = _parto!.add(const Duration(days: 60));
      _lactanciaController.text = _dateFormat.format(_lactancia!);
    });
  }

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Por favor completa todos los campos obligatorios');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Usuario no autenticado');
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        try {
          imageUrl = await _uploadImage(user.uid);
        } catch (e) {
          debugPrint('Error subiendo imagen, pero continuando sin ella: $e');
          imageUrl = null;
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('animales')
          .add({
        'nombre': _nombreController.text.trim(),
        'tipo': _tipo,
        'raza': _razaController.text.trim(),
        'estadoReproductivo': _estadoReproductivo,
        'estadoSalud': _estadoSalud,
        'fechaNacimiento': _fechaNacimiento != null ? Timestamp.fromDate(_fechaNacimiento!) : null,
        'fechaInseminacion': _inseminacion != null ? Timestamp.fromDate(_inseminacion!) : null,
        'fechaParto': _parto != null ? Timestamp.fromDate(_parto!) : null,
        'fechaLactancia': _lactancia != null ? Timestamp.fromDate(_lactancia!) : null,
        'imagenUrl': imageUrl,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      _showSuccess('Animal guardado exitosamente${imageUrl == null ? ' (sin imagen)' : ''}');

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      _showError('Error al guardar animal: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('animal_images/$userId/${timestamp}_animal.jpg');

      final bytes = await _selectedImage!.readAsBytes();
      final uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();

    } catch (e) {
      debugPrint('Error en _uploadImage: $e');
      throw e;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
      );
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _razaController.clear();
    _fechaNacimientoController.clear();
    _inseminacionController.clear();
    _partoController.clear();
    _lactanciaController.clear();
    setState(() {
      _selectedImage = null;
      _fechaNacimiento = null;
      _inseminacion = null;
      _parto = null;
      _lactancia = null;
      _tipo = "Vaca";
      _estadoReproductivo = "Seca";
      _estadoSalud = "Saludable";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text("Nuevo Animal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: const Color(0xFFF6F8F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.clear_all), onPressed: _clearForm, tooltip: 'Limpiar formulario')],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIconTextField("Identificador del animal", Icons.badge_outlined, _nombreController, true),
              const SizedBox(height: 12),

              _buildDropdown("Especie", Icons.pets, _tipo, ["Vaca", "Cerda", "Cabra", "Oveja"], (val) => setState(() => _tipo = val!)),
              const SizedBox(height: 12),

              _buildIconDateField("Fecha de nacimiento", Icons.cake_outlined, _fechaNacimientoController, true, (date) => setState(() => _fechaNacimiento = date)),
              const SizedBox(height: 12),

              _buildIconTextField("Raza", Icons.grass, _razaController, false),
              const SizedBox(height: 12),

              _buildDropdown("Estado Reproductivo", Icons.sync_alt, _estadoReproductivo, ["Gestación", "Lactancia", "Seca"], (val) => setState(() => _estadoReproductivo = val!)),
              const SizedBox(height: 12),

              _buildDropdown("Estado de Salud", Icons.favorite_border, _estadoSalud, ["Saludable", "Enfermo"], (val) => setState(() => _estadoSalud = val!)),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _loading ? null : _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF3FD411).withOpacity(0.5)), borderRadius: BorderRadius.circular(12), color: Colors.white),
                  child: Column(
                    children: [
                      if (_selectedImage != null)
                        kIsWeb ? Image.network(_selectedImage!.path, height: 150, fit: BoxFit.cover) : Image.file(File(_selectedImage!.path), height: 150, fit: BoxFit.cover)
                      else
                        const Icon(Icons.image_outlined, size: 60, color: Color(0xFF3FD411)),
                      const SizedBox(height: 8),
                      Text(_selectedImage != null ? "Imagen seleccionada" : "Subir imagen", style: TextStyle(fontWeight: FontWeight.bold, color: _loading ? Colors.grey : Colors.black)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text("Fechas Reproductivas (Opcionales)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              const Text("Al ingresar la fecha de inseminacion, se calcularan automaticamente las demas fechas", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),

              _buildIconDateField("Inseminacion", Icons.biotech_outlined, _inseminacionController, false, (date) => _calculateEstimatedDates(date)),
              const SizedBox(height: 12),

              _buildIconDateField("Parto estimado", Icons.pregnant_woman_outlined, _partoController, false, (date) => setState(() => _parto = date)),
              const SizedBox(height: 12),

              _buildIconDateField("Lactancia estimada", Icons.local_drink_outlined, _lactanciaController, false, (date) => setState(() => _lactancia = date)),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Colors.grey)), onPressed: _loading ? null : () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _loading ? Colors.grey : const Color(0xFF3FD411), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _loading ? null : _saveAnimal,
                      child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Guardar Animal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return Row(children: [Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3FD411)), padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white, size: 22)), const SizedBox(width: 12), Expanded(child: DropdownButtonFormField<String>(value: currentValue, decoration: _inputDecoration(label), items: items.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), onChanged: _loading ? null : onChanged))]);
  }

  Widget _buildIconTextField(String label, IconData icon, TextEditingController controller, bool isRequired) {
    return Row(children: [Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3FD411)), padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white, size: 22)), const SizedBox(width: 12), Expanded(child: TextFormField(controller: controller, decoration: _inputDecoration(label), validator: isRequired ? (v) => v!.isEmpty ? "Campo obligatorio" : null : null))]);
  }

  Widget _buildIconDateField(String label, IconData icon, TextEditingController controller, bool isRequired, Function(DateTime) onDateSelected) {
    return Row(children: [Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3FD411)), padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white, size: 22)), const SizedBox(width: 12), Expanded(child: TextFormField(controller: controller, readOnly: true, onTap: _loading ? null : () => _pickDate(controller, onDateSelected), decoration: _inputDecoration(label).copyWith(suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF3FD411), size: 20)), validator: isRequired ? (v) => v!.isEmpty ? "Campo obligatorio" : null : null))]);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3FD411))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF3FD411).withOpacity(0.4))), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3FD411), width: 1.5)));
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _fechaNacimientoController.dispose();
    _inseminacionController.dispose();
    _partoController.dispose();
    _lactanciaController.dispose();
    super.dispose();
  }
}
