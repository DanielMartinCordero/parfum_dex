/// Configuración de Firebase App Check.
///
/// App Check hace que Firestore y Cloud Functions solo acepten peticiones de
/// la app auténtica (no de un script que haya copiado la configuración de
/// Firebase, que es pública por diseño).
///
/// La clave de sitio de reCAPTCHA Enterprise NO es secreta: va dentro del
/// JavaScript de la web igual que la configuración de Firebase. Se crea en
/// Google Cloud console > Seguridad > reCAPTCHA, con los dominios
/// localhost, parfumdex.web.app, parfumdex.firebaseapp.com (y el dominio
/// propio cuando exista). Estos dominios llevan "parfumdex" porque es el ID
/// del proyecto Firebase, que no se puede cambiar.
abstract final class AppCheckConfig {
  /// Clave de sitio de reCAPTCHA Enterprise para la web.
  /// Vacía = App Check no se activa en web (se avisa en consola).
  static const recaptchaEnterpriseSiteKey = '6Ld3cxguAAAAAMh5TYOqCmWV-cW1DUmX_QU9XkAH';
}
