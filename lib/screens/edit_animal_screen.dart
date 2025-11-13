import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class EditAnimalScreen extends StatefulWidget {
  final String animalId;
  final Map<String, dynamic> animalData;

  const EditAnimalScreen({
    super.key,
    required this.animalId,
    required this.animalData,
  });

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _razaController = TextEditingController();
  final TextEditingController _fechaNacimientoController = TextEditingController();
  final TextEditingController _inseminacionController = TextEditingController();
  final TextEditingController _partoController = TextEditingController();
  final TextEditingController _lactanciaController = TextEditingController();

  String _tipo = "Vaca";
  XFile? _selectedImage;
  String? _currentImageUrl;
  bool _loading = false;
  bool _imageChanged = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAnimalData();
  }

  void _loadAnimalData() {
    final animal = widget.animalData;

    _nombreController.text = animal['nombre'] ?? '';
    _tipo = animal['tipo'] ?? 'Vaca';
    _razaController.text = animal['raza'] ?? '';

    _fechaNacimientoController.text = _formatTimestamp(animal['fechaNacimiento']);
    _inseminacionController.text = _formatTimestamp(animal['inseminacion']);
    _partoController.text = _formatTimestamp(animal['parto']);
    _lactanciaController.text = _formatTimestamp(animal['lactancia']);
    _currentImageUrl = animal['imagenUrl'];
  }


  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
          _imageChanged = true;
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _pickDate(TextEditingController controller, String fieldName) async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        final formattedDate = "${picked.day}/${picked.month}/${picked.year}";
        controller.text = formattedDate;

        if (fieldName == 'inseminacion') {
          _calculateEstimatedDates(picked);
        }
      }
    } catch (e) {
      _showError('Error al seleccionar fecha: $e');
    }
  }

  void _calculateEstimatedDates(DateTime inseminacionDate) {
    final partoDate = inseminacionDate.add(const Duration(days: 283));
    _partoController.text = "${partoDate.day}/${partoDate.month}/${partoDate.year}";

    final lactanciaDate = partoDate.add(const Duration(days: 60));
    _lactanciaController.text = "${lactanciaDate.day}/${lactanciaDate.month}/${lactanciaDate.year}";
  }
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year}";
    } else if (timestamp is String) {
      return timestamp;
    } else {
      return '';
    }
  }

  Future<void> _updateAnimal() async {
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
      String? imageUrl = _currentImageUrl;

      // Si se seleccionó una nueva imagen, subirla
      if (_imageChanged && _selectedImage != null) {
        try {
          imageUrl = await _uploadImage(user.uid);
          debugPrint('Nueva imagen subida correctamente: $imageUrl');
        } catch (e) {
          debugPrint('Error subiendo nueva imagen: $e');
          // Mantener la imagen anterior si falla la subida
        }
      }

      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('animales')
          .doc(widget.animalId)
          .update({
        'nombre': _nombreController.text.trim(),
        'tipo': _tipo,
        'raza': _razaController.text.trim(),
        'fechaNacimiento': _fechaNacimientoController.text,
        'inseminacion': _inseminacionController.text.isEmpty ? null : _inseminacionController.text,
        'parto': _partoController.text.isEmpty ? null : _partoController.text,
        'lactancia': _lactanciaController.text.isEmpty ? null : _lactanciaController.text,
        'imagenUrl': imageUrl,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      _showSuccess('Animal actualizado exitosamente');

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      _showError('Error al actualizar animal: $e');
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

      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        final file = File(_selectedImage!.path);
        final uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error en _uploadImage: $e');
      throw e;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _currentImageUrl = null;
      _imageChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          "Editar Animal",
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
              _buildIconTextField("Identificador del animal", Icons.badge_outlined, _nombreController, true),
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
                        DropdownMenuItem(value: "Oveja", child: Text("Oveja")),
                      ],
                      onChanged: _loading ? null : (val) => setState(() => _tipo = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildIconDateField("Fecha de nacimiento", Icons.cake_outlined, _fechaNacimientoController, true),
              const SizedBox(height: 12),

              _buildIconTextField("Raza", Icons.grass, _razaController, false),
              const SizedBox(height: 20),

              // Sección de imagen
              GestureDetector(
                onTap: _loading ? null : _pickImage,
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
                        Stack(
                          children: [
                            kIsWeb
                                ? Image.network(_selectedImage!.path, height: 150, fit: BoxFit.cover)
                                : Image.file(File(_selectedImage!.path), height: 150, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.red,
                                radius: 14,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                  onPressed: _removeImage,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (_currentImageUrl != null)
                        Stack(
                          children: [
                            Image.network(_currentImageUrl!, height: 150, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.red,
                                radius: 14,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                  onPressed: _removeImage,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const Icon(Icons.image_outlined, size: 60, color: Color(0xFF3FD411)),
                      const SizedBox(height: 8),
                      Text(
                        _selectedImage != null || _currentImageUrl != null
                            ? "Imagen actual"
                            : "Subir imagen",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _loading ? Colors.grey : Colors.black,
                        ),
                      ),
                      if (_selectedImage != null)
                        const Text(
                          "Nueva imagen seleccionada",
                          style: TextStyle(fontSize: 12, color: Color(0xFF3FD411)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                "Fechas Reproductivas (Opcionales)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                "Al ingresar la fecha de inseminacion, se calcularan automaticamente las demas fechas",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              _buildIconDateField("Inseminacion", Icons.biotech_outlined, _inseminacionController, false),
              const SizedBox(height: 12),
              _buildIconDateField("Parto estimado", Icons.pregnant_woman_outlined, _partoController, false),
              const SizedBox(height: 12),
              _buildIconDateField("Lactancia estimada", Icons.local_drink_outlined, _lactanciaController, false),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _loading ? Colors.grey : const Color(0xFF3FD411),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _loading ? null : _updateAnimal,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Actualizar Animal",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Cancelar",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildIconTextField(String label, IconData icon, TextEditingController controller, bool isRequired) {
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
            validator: isRequired ? (v) => v!.isEmpty ? "Campo obligatorio" : null : null,
          ),
        ),
      ],
    );
  }

  Widget _buildIconDateField(String label, IconData icon, TextEditingController controller, bool isRequired) {
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
            onTap: _loading ? null : () => _pickDate(controller, label.toLowerCase()),
            decoration: _inputDecoration(label).copyWith(
              suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF3FD411), size: 20),
            ),
            validator: isRequired ? (v) => v!.isEmpty ? "Campo obligatorio" : null : null,
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