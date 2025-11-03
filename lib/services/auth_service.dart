import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Registrar un nuevo usuario con correo y contraseña
  Future<String?> registerUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        return 'El correo ya está registrado.';
      } else if (e.code == 'invalid-email') {
        return 'El formato del correo no es válido.';
      } else {
        return 'Error desconocido: ${e.message}';
      }
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// 🔹 Iniciar sesión con correo y contraseña
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No existe una cuenta con ese correo.';
      } else if (e.code == 'wrong-password') {
        return 'Contraseña incorrecta.';
      } else if (e.code == 'invalid-email') {
        return 'Correo no válido.';
      } else {
        return 'Error desconocido: ${e.message}';
      }
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// 🔹 Cerrar sesión
  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  /// 🔹 Obtener el usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;

  /// 🔹 Escuchar cambios de sesión en tiempo real
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
