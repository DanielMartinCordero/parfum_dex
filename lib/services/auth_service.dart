import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Para usar debugPrint

import 'users_service.dart';

class AuthService {
  // 1. Instancia privada de FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instancia de nuestro servicio de base de datos
  final UsersService _usersService = UsersService();

  // 2. Stream para escuchar si hay usuario logueado o no
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 3. Getter para obtener el usuario actual de forma síncrona
  User? get currentUser => _auth.currentUser;

  // 4. Método para REGISTRAR con email y contraseña
  Future<String?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {

      // CREACIÓN EN FIREBASE AUTH
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        //Actualizamos el perfil básico de Auth
        await user.updateDisplayName(displayName);

        // CREACIÓN EN FIRESTORE (El documento completo del perfil)
        await _usersService.claimUsername(
          uid: user.uid,
          email: email,
          displayName: displayName,
        );
      }

      return null; // Registro completo y perfecto
    } on FirebaseAuthException catch (e) {
      // Capturamos los errores
      debugPrint('Error de Firebase Auth (Registro): ${e.code}');

      if (e.code == 'weak-password') {
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        return 'Ya existe una cuenta vinculada a este correo electrónico.';
      } else if (e.code == 'invalid-email') {
        return 'El formato del correo electrónico no es válido.';
      }
      return 'Ocurrió un error al registrarse: ${e.message}';
    } catch (e) {
      debugPrint('Excepción general en registro: $e');
      return 'Error inesperado del sistema.';
    }
  }

  // 5. Método para INICIAR SESIÓN con email y contraseña
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Éxito, sin error
    } on FirebaseAuthException catch (e) {
      debugPrint('Error de Firebase Auth (Login): ${e.code}');

      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return 'Credenciales inválidas. Verifica tu correo y contraseña.';
      } else if (e.code == 'wrong-password') {
        return 'La contraseña es incorrecta.';
      } else if (e.code == 'invalid-email') {
        return 'El formato del correo electrónico no es válido.';
      }
      return 'Ocurrió un error al iniciar sesión: ${e.message}';
    } catch (e) {
      return 'Error inesperado del sistema.';
    }
  }

  // 6. Método para CERRAR SESIÓN
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
