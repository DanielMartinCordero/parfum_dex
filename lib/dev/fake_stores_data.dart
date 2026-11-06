// Datos de prueba para FakeStoresRepository. Solo se usan mientras la
// Cloud Function no esté desplegada.
//
// No llevan coordenadas: el repositorio coloca cada tienda alrededor de la
// posición real del usuario, para que siempre aparezcan cerca estés donde
// estés.

/// Lo que define a una tienda de prueba (sin su posición).
typedef FakeStoreTemplate = ({
  String chain,
  String address,
  String? phone,
  List<List<String>>? hours,
});

const _mallHours = [
  ['10:00-22:00'], ['10:00-22:00'], ['10:00-22:00'], ['10:00-22:00'],
  ['10:00-22:00'], ['10:00-22:00'], ['11:00-21:00'],
];

const _splitHours = [
  ['09:30-14:00', '17:00-20:30'], ['09:30-14:00', '17:00-20:30'],
  ['09:30-14:00', '17:00-20:30'], ['09:30-14:00', '17:00-20:30'],
  ['09:30-14:00', '17:00-20:30'], ['10:00-14:00'], <String>[],
];

/// Mezcla tiendas con y sin teléfono y con y sin horario, para probar la
/// ficha con todas las combinaciones.
const List<FakeStoreTemplate> fakeStoreTemplates = [
  (chain: 'Druni', address: 'Calle Mayor 12', phone: '+34910000001', hours: _mallHours),
  (chain: 'Primor', address: 'Avenida de la Constitución', phone: null, hours: null),
  (chain: 'Sephora', address: 'Calle Preciados 5', phone: '+34910000003', hours: _mallHours),
  (chain: 'Clarel', address: 'Plaza de España 3', phone: null, hours: _splitHours),
  (chain: 'Perfumerías Avenida', address: 'Calle del Carmen', phone: null, hours: null),
  (chain: 'Douglas', address: 'C. C. Los Arcos, local 14', phone: '+34910000006', hours: _mallHours),
  (chain: 'Equivalenza', address: 'Calle Real 40', phone: null, hours: _splitHours),
  (chain: 'Rituals', address: 'Gran Vía 22', phone: null, hours: _mallHours),
];

/// A qué distancia del usuario (km) se colocan las tiendas en cada escenario.
/// Con `normal` hay 2 tiendas en 2 km y 6 en 10 km → resultado: 5 en 10 km.
const normalDistancesKm = [0.6, 1.4, 2.3, 3.8, 5.1, 7.9, 12.4, 18.0];

/// Con `few` ningún radio llega a 5 → resultado: 3 tiendas en 40 km.
const fewDistancesKm = [14.2, 21.7, 33.5];
