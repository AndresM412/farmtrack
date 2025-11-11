import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

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

  String _tipo = "Vaca";
  XFile? _selectedImage;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
      });
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      String? imageUrl;

      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('users/$userId/animales/${DateTime.now().millisecondsSinceEpoch}.jpg');

        // 🔹 Flutter Web usa bytes, móviles usan File
        if (kIsWeb) {
          await ref.putData(await _selectedImage!.readAsBytes());
        } else {
          await ref.putFile(File(_selectedImage!.path));
        }

        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('animales')
          .add({
        'nombre': _nombreController.text.trim(),
        'tipo': _tipo,
        'raza': _razaController.text.trim(),
        'fechaNacimiento': _fechaNacimientoController.text,
        'inseminacion': _inseminacionController.text,
        'parto': _partoController.text,
        'lactancia': _lactanciaController.text,
        'imagenUrl': imageUrl,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          "Nuevo Animal",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFF6F8F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIconTextField("Identificador del animal", Icons.badge_outlined, _nombreController),
              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF3FD411),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.pets, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: _inputDecoration("Especie"),
                      items: const [
                        DropdownMenuItem(value: "Vaca", child: Text("Vaca")),
                        DropdownMenuItem(value: "Cerda", child: Text("Cerda")),
                        DropdownMenuItem(value: "Cabra", child: Text("Cabra")),
                      ],
                      onChanged: (val) => setState(() => _tipo = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildIconDateField("Fecha de nacimiento", Icons.cake_outlined, _fechaNacimientoController),
              const SizedBox(height: 12),

              _buildIconTextField("Raza", Icons.grass, _razaController),
              const SizedBox(height: 20),

              // 📸 Imagen
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF3FD411).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      if (_selectedImage != null)
                        kIsWeb
                            ? Image.network(_selectedImage!.path, height: 150, fit: BoxFit.cover)
                            : Image.file(File(_selectedImage!.path), height: 150, fit: BoxFit.cover)
                      else
                        const Icon(Icons.image_outlined, size: 60, color: Color(0xFF3FD411)),
                      const SizedBox(height: 8),
                      const Text(
                        "Subir imagen",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                "Fechas estimadas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),

              _buildIconDateField("Inseminación", Icons.biotech_outlined, _inseminacionController),
              const SizedBox(height: 12),
              _buildIconDateField("Parto", Icons.pregnant_woman_outlined, _partoController),
              const SizedBox(height: 12),
              _buildIconDateField("Lactancia", Icons.local_drink_outlined, _lactanciaController),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3FD411),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _saveAnimal,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Guardar Animal",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconTextField(String label, IconData icon, TextEditingController controller) {
    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF3FD411),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: _inputDecoration(label),
            validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
          ),
        ),
      ],
    );
  }

  Widget _buildIconDateField(String label, IconData icon, TextEditingController controller) {
    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF3FD411),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            onTap: () => _pickDate(controller),
            decoration: _inputDecoration(label).copyWith(
              suffixIcon:
                  const Icon(Icons.calendar_today, color: Color(0xFF3FD411), size: 20),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
}
