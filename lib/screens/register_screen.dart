import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _acceptTerms = false;
  bool _isLoading = false;

  // Controladores
  final _farmNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _farmNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    // Validación
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos y acepta los términos."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final farmName = _farmNameController.text.trim();

    try {
      print("➡️ Iniciando createUserWithEmailAndPassword para $email");

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw Exception("UserCredential sin user");

      final userId = user.uid;

      print("✅ Usuario creado en Auth con UID: $userId");
      print("➡️ Guardando documento inicial en Firestore...");

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'email': email,
        'nombreCompleto': fullName,
        'nombreFinca': farmName,
        'animalesTotales': 0,
        'animalesGestacion': 0,
        'animalesLactancia': 0,
        'proximosPartos': 0,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      print("✅ Documento guardado en Firestore para $userId");

      // ✅ Detener loader
      if (mounted) setState(() => _isLoading = false);

      // ✅ Notificación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cuenta creada con éxito")),
        );
      }

      // ✅ Redirección al home
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });

    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code} - ${e.message}");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Error de autenticación")),
        );
      }
    } catch (e) {
      print("❌ Error general en registro: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al registrar usuario: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF3FD411);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Crear cuenta",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text("Nombre de la granja"),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _farmNameController,
                  decoration: _inputDecoration("Ej: Finca La Esperanza"),
                  validator: (value) =>
                      value!.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 15),

                const Text("Nombre completo"),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputDecoration("Ej: Juan Pérez"),
                  validator: (value) =>
                      value!.isEmpty ? "Campo requerido" : null,
                ),
                const SizedBox(height: 15),

                const Text("Correo electrónico"),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration("ejemplo@correo.com"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Campo requerido";
                    if (!value.contains('@') || !value.contains('.')) {
                      return "Correo inválido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                const Text("Contraseña"),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration("Crea una contraseña"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Campo requerido";
                    if (value.length < 6) return "Debe tener mínimo 6 caracteres";
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                const Text("Confirmar contraseña"),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration("Confirma tu contraseña"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Campo requerido";
                    if (value != _passwordController.text) {
                      return "Las contraseñas no coinciden";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Checkbox(
                      activeColor: primaryColor,
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() => _acceptTerms = value ?? false);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "Acepto los términos y condiciones",
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _registerUser,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Crear cuenta",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        const TextSpan(text: "¿Ya tienes una cuenta? "),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/login'),
                            child: Text(
                              "Iniciar sesión",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
