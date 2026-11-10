import 'dart:js_interop';

/// Variable global que lee el SDK de JavaScript de App Check al activarse.
/// Si contiene un string, lo usa como token de depuración en lugar de
/// generar uno aleatorio (que cambiaría en cada ejecución, porque Flutter
/// abre el navegador con un perfil temporal).
@JS('FIREBASE_APPCHECK_DEBUG_TOKEN')
external set _firebaseAppCheckDebugToken(JSString value);

void setAppCheckDebugToken(String token) {
  _firebaseAppCheckDebugToken = token.toJS;
}
