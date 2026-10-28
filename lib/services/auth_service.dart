import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Para usar debugPrint
import 'package:google_sign_in/google_sign_in.dart';

import 'users_service.dart';

// Los tres finales posibles del login con Google
enum GoogleSignInStatus {
  success, // Ha entrado y tiene perfil
  cancelled, // Cerró la ventana o la sustituyó por otra: no se muestra nada
  error, // Algo falló de verdad: se muestra el mensaje
}

class GoogleSignInResult {
  final GoogleSignInStatus status;
  final String? errorMessage; // Solo tiene valor cuando status es error

  const GoogleSignInResult(this.status, [this.errorMessage]);
}

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
        try {
          //Actualizamos el perfil básico de Auth
          await user.updateDisplayName(displayName);

          // CREACIÓN EN FIRESTORE (El documento completo del perfil)
          await _usersService.claimUsername(
            uid: user.uid,
            email: email,
            displayName: displayName,
          );
        } catch (e) {
          // La cuenta de Auth ya existe pero sin perfil: la borramos para no
          // dejarla "a medias" y que el email quede libre para reintentarlo.
          debugPrint('Fallo al crear el perfil, se elimina la cuenta: $e');
          await _deleteHalfCreatedUser(user);
          return 'No se pudo crear tu perfil. Inténtalo de nuevo.';
        }
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

  // 4.1 Deshace un registro que falló a mitad. user.delete() borra la cuenta
  //     de Auth y cierra la sesión. Si aun así fallase, al menos cerramos
  //     sesión para que no entre en la app sin perfil.
  Future<void> _deleteHalfCreatedUser(User user) async {
    try {
      await user.delete();
    } catch (e) {
      debugPrint('No se pudo eliminar la cuenta a medias: $e');
      await _auth.signOut();
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

  // 7. Método para entrar con GOOGLE (sirve tanto para registro como para login)
  //    onAccountChosen se llama cuando el usuario ya ha elegido cuenta: es el
  //    momento de mostrar el spinner. Mientras la ventana de Google está
  //    abierta, el botón sigue libre para poder reintentar al instante.
  Future<GoogleSignInResult> signInWithGoogle({
    VoidCallback? onAccountChosen,
  }) async {
    try {
      // Web: ventana emergente de Firebase.
      // Android: selector de cuentas nativo (google_sign_in) dentro de la app.
      final UserCredential userCredential = kIsWeb
          ? await _signInWithGooglePopup(onAccountChosen)
          : await _signInWithGoogleNative(onAccountChosen);

      final user = userCredential.user;
      if (user != null) {
        await _usersService.ensureProfile(user);
      }

      return const GoogleSignInResult(GoogleSignInStatus.success);
    } on GoogleSignInException catch (e) {
      // Errores del selector nativo de Android (antes de llegar a Firebase)
      debugPrint('Error de Google Sign-In: ${e.code}');

      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleSignInResult(GoogleSignInStatus.cancelled);
      }
      return GoogleSignInResult(
        GoogleSignInStatus.error,
        'Error al iniciar sesión con Google: ${e.description}',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Error de Firebase Auth (Google): ${e.code}');

      // popup-closed-by-user: cerró la ventana (Firebase avisa ~10 s tarde).
      // cancelled-popup-request: pulsó otra vez y Firebase cerró la ventana
      // anterior para abrir una nueva. En ambos casos no hay nada que mostrar.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return const GoogleSignInResult(GoogleSignInStatus.cancelled);
      }

      String message = 'Error al iniciar sesión con Google: ${e.message}';
      if (e.code == 'popup-blocked') {
        message = 'El navegador ha bloqueado la ventana emergente.';
      } else if (e.code == 'account-exists-with-different-credential') {
        message = 'Ya existe una cuenta con este correo usando otro método.';
      }
      return GoogleSignInResult(GoogleSignInStatus.error, message);
    } catch (e) {
      // Si Auth fue bien pero el perfil falló, cerramos sesión para no
      // dejar entrar a la app a un usuario sin perfil.
      debugPrint('Excepción en login con Google: $e');
      await _auth.signOut();
      return const GoogleSignInResult(
        GoogleSignInStatus.error,
        'No se pudo crear tu perfil. Inténtalo de nuevo.',
      );
    }
  }

  // 7.1 WEB: Firebase abre la ventana emergente de Google por su cuenta
  Future<UserCredential> _signInWithGooglePopup(
    VoidCallback? onAccountChosen,
  ) async {
    final provider = GoogleAuthProvider();
    // Obliga a elegir cuenta aunque solo haya una sesión de Google abierta
    provider.setCustomParameters({'prompt': 'select_account'});

    final userCredential = await _auth.signInWithPopup(provider);
    onAccountChosen?.call(); // Ventana cerrada con cuenta elegida
    return userCredential;
  }

  /* 7.2 ANDROID: google_sign_in muestra el selector nativo y nos da un idToken,
     que después le pasamos a Firebase para iniciar sesión con él.*/
  Future<UserCredential> _signInWithGoogleNative(
    VoidCallback? onAccountChosen,
  ) async {
    await _initGoogleSignIn();

    final account = await GoogleSignIn.instance.authenticate();
    onAccountChosen?.call(); // Cuenta elegida en el selector nativo
    final idToken = account.authentication.idToken;

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  // initialize() solo puede llamarse UNA vez en toda la app. Guardamos el
  // Future en una variable static (compartida por todos los AuthService) y
  // las siguientes llamadas reutilizan el mismo.
  static Future<void>? _googleInit;

  Future<void> _initGoogleSignIn() {
    // Sin parámetros: en Android lee el client ID web de google-services.json
    return _googleInit ??= GoogleSignIn.instance.initialize();
  }

  // 6. Método para CERRAR SESIÓN
  Future<void> signOut() async {
    // En Android también cerramos la sesión de google_sign_in; si no, la
    // próxima vez podría entrar con la misma cuenta sin dejar elegir otra.
    if (!kIsWeb) {
      try {
        await _initGoogleSignIn();
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Error al cerrar sesión de Google: $e');
      }
    }

    await _auth.signOut();
  }
}
