/// Configuración del mapa base (teselas) de flutter_map.
///
/// Para desarrollo se usan los servidores de teselas de OpenStreetMap, que
/// lo permiten con poco tráfico si la app se identifica con su User-Agent.
/// ANTES DE PUBLICAR hay que cambiar a un proveedor con capa gratuita y API
/// key (p. ej. MapTiler): la política de uso de tile.openstreetmap.org no
/// admite apps en producción.
/// https://operations.osmfoundation.org/policies/tiles/
abstract final class MapConfig {
  static const tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Identifica la app ante el servidor de teselas (cabecera User-Agent).
  static const userAgentPackageName = 'com.parfumdex.parfum_dex';

  static const maxZoom = 19.0;

  static const attributionText = 'colaboradores de OpenStreetMap';
  static const attributionUrl = 'https://www.openstreetmap.org/copyright';
}
