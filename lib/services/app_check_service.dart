import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../config/app_check_config.dart';

/// Activa Firebase App Check. Se llama una vez, justo después de
/// Firebase.initializeApp().
///
/// Desde aquí el SDK obtiene un token de App Check (dura 1 h y se renueva
/// solo) y cloud_firestore y cloud_functions lo adjuntan a cada petición
/// sin tocar nada más.
///
/// Proveedores:
/// - Android en debug: proveedor de depuración. La primera ejecución escribe
///   en el Logcat "Enter this debug secret into the allow list in the
///   Firebase Console for your project: UUID". Ese UUID se registra en
///   Firebase > App Check > app Android > Administrar tokens de depuración.
/// - Android en release: Play Integrity. Solo valida instalaciones hechas
///   desde Google Play (vale la pista de prueba interna). Un APK instalado a
///   mano NO pasará cuando App Check esté en Enforce.
/// - Web: reCAPTCHA Enterprise (invisible para el usuario).
class AppCheckService {
  AppCheckService._();

  static Future<void> init() async {
    if (kIsWeb && AppCheckConfig.recaptchaEnterpriseSiteKey.isEmpty) {
      debugPrint(
        'App Check NO activado en web: falta la clave de reCAPTCHA Enterprise '
        'en lib/config/app_check_config.dart',
      );
      return;
    }

    try {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaEnterpriseProvider(
          AppCheckConfig.recaptchaEnterpriseSiteKey,
        ),
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
    } catch (e) {
      // Si App Check falla al arrancar, la app sigue funcionando. Mientras
      // esté en modo monitorización no bloquea nada; con Enforce activado,
      // las peticiones sin token fallarán con permission-denied.
      debugPrint('Error al activar App Check: $e');
    }
  }
}
