/// Distancia legible para el usuario.
///
/// 0,63 km → "630 m"; 3,24 km → "3,2 km". Los metros se redondean a decenas:
/// la ubicación es aproximada y "634 m" daría una falsa precisión.
String formatDistance(double km) {
  if (km < 1) {
    final meters = (km * 1000 / 10).round() * 10;
    return '$meters m';
  }
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}
