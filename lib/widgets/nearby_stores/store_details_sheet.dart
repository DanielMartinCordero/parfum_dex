import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/map_config.dart';
import '../../models/nearby_store.dart';

/// Abre la ficha de [store] como una hoja que sube desde abajo.
Future<void> showStoreDetailsSheet(BuildContext context, NearbyStore store) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true, // la "rayita" de arriba para arrastrar y cerrar
    isScrollControlled: true, // puede pasar de media pantalla si hace falta
    builder: (sheetContext) {
      return StoreDetailsSheet(store: store);
    },
  );
}

// ---------------------------------------------------------------------------
// Utilidades de horario y distancia (privadas de este fichero)
// ---------------------------------------------------------------------------

const _dayNames = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];
const _dayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// Índice de hoy en la lista de 7 días. DateTime.weekday va de 1 (lunes) a
/// 7 (domingo) y la lista empieza en 0.
int _todayIndex() => DateTime.now().weekday - 1;

/// [] → "Cerrado"; ["09:30-14:00", "17:00-20:30"] → "09:30-14:00, 17:00-20:30".
String _formatSlots(List<String> slots) {
  if (slots.isEmpty) {
    return 'Cerrado';
  }
  return slots.join(', ');
}

/// 0,63 km → "630 m"; 3,24 km → "3,2 km".
String _formatDistance(double km) {
  if (km < 1) {
    final meters = (km * 1000 / 10).round() * 10; // redondeo a decenas
    return '$meters m';
  }
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Convierte una hora "HH:MM" en minutos desde medianoche.
int _toMinutes(String hhmm) {
  List<String>parts = hhmm.split(':');
  int minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
  return minutes;
}

/// true si la tienda está abierta ahora, false si está cerrada y null si no
/// tiene horario (no sabemos su estado y no se muestra nada).
///
/// Limitación: un tramo que cruza medianoche ("20:00-02:00") no se detecta.
bool? _isOpenNow(List<List<String>>? weeklyHours) {
  if (weeklyHours == null || weeklyHours.length != 7) {
    return null;
  }

  final now = DateTime.now();
  final minutesNow = now.hour * 60 + now.minute;
  final todaySlots = weeklyHours[_todayIndex()];

  //Usando minutos, comprobamos si el rango de minutos actual esta entre el horario abierto
  for (final slot in todaySlots) {
    final parts = slot.split('-'); // "10:00-22:00" → ["10:00", "22:00"]
    final opens = _toMinutes(parts[0]);
    final closes = _toMinutes(parts[1]);
    if (minutesNow >= opens && minutesNow < closes) {
      return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// La ficha
// ---------------------------------------------------------------------------

/// Ficha de una perfumería: cadena, distancia y estado; horario de hoy;
/// dirección; semana; y botones para llegar o llamar.
/// Lo que no exista no se muestra.
class StoreDetailsSheet extends StatelessWidget {
  final NearbyStore store;

  const StoreDetailsSheet({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    // Copias locales para que Dart las promocione a no-null tras el if.
    final address = store.address;
    final locality = store.locality;
    final phone = store.phone;
    final hours = store.weeklyHours;
    final isOpen = _isOpenNow(hours);

    final addressLines = <String>[];
    if (address != null) addressLines.add(address);
    if (locality != null) addressLines.add(locality);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: cadena · distancia · estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    store.chain,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "A ${_formatDistance(store.distanceKm)}",
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (isOpen != null) ...[
                  const SizedBox(width: 8),
                  _OpenChip(isOpen: isOpen),
                ],
              ],
            ),

            // Fila 2: horario de hoy
            if (hours != null && hours.length == 7) ...[
              const SizedBox(height: 4),
              Text(
                'Hoy · ${_formatSlots(hours[_todayIndex()])}',
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Tarjeta de dirección (pulsable: abre la ruta)
            if (addressLines.isNotEmpty) ...[
              _AddressCard(
                lines: addressLines,
                onTap: _openDirections,
              ),
              const SizedBox(height: 20),
            ],

            // Semana en pastillas
            if (hours != null && hours.length == 7) ...[
              const Text(
                'Horario',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _WeekPills(hours: hours),
              const SizedBox(height: 24),
            ],

            // Acciones
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openDirections,
                    icon: const Icon(Icons.directions),
                    label: const Text('Cómo llegar'),
                  ),
                ),
                if (phone != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _call(phone),
                      icon: const Icon(Icons.call),
                      label: const Text('Llamar'),
                    ),
                  ),
                ],
              ],
            ),

            // Atribución obligatoria: los datos vienen de OpenStreetMap.
            const SizedBox(height: 16),
            Text(
              'Datos © ${MapConfig.attributionText}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre Google Maps (app o web) con la ruta hasta la tienda. El origen no
  /// se envía: Google usa la ubicación del propio dispositivo.
  void _openDirections() {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${store.location.latitude},${store.location.longitude}',
    });
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Abre el marcador del teléfono con el número ya escrito (no llama solo).
  void _call(String phone) {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    launchUrl(uri);
  }
}

// ---------------------------------------------------------------------------
// Piezas de la ficha
// ---------------------------------------------------------------------------

/// Chip "● Abierto" (verde) o "● Cerrado" (rojo).
class _OpenChip extends StatelessWidget {
  final bool isOpen;

  const _OpenChip({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if(isOpen){
      color = Colors.green.shade700;
      label = 'Abierto';
    }
    else{
      color = Colors.red.shade700;
      label = 'Cerrado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), // fondo: el mismo color, suave
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dirección sobre fondo morado claro. Toda la tarjeta es pulsable.
class _AddressCard extends StatelessWidget {
  final List<String> lines;
  final VoidCallback onTap;

  const _AddressCard({required this.lines, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Material + InkWell: el Material pone el fondo y el InkWell la "onda"
    // al pulsar. La onda se dibuja sobre el Material más cercano, por eso el
    // color va en el Material y no en un Container de dentro.
    return Material(
      color: Colors.deepPurple.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.place, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lines.join('\n'),
                  style: const TextStyle(height: 1.3),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.deepPurple),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de 7 pastillas (L M X J V S D) y, debajo, el horario del día
/// seleccionado. Empieza seleccionado hoy.
class _WeekPills extends StatefulWidget {
  final List<List<String>> hours;

  const _WeekPills({required this.hours});

  @override
  State<_WeekPills> createState() => _WeekPillsState();
}

class _WeekPillsState extends State<_WeekPills> {
  final int _today = _todayIndex();
  late int _selected = _today;

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[];
    for (var i = 0; i < 7; i++) {
      final isSelected = i == _selected;
      final isToday = i == _today;
      final isClosed = widget.hours[i].isEmpty;

      Color textColor = Colors.deepPurple;
      if (isSelected) {
        textColor = Colors.white;
      } else if (isClosed) {
        textColor = Colors.grey.shade400;
      }

      pills.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selected = i;
            }
            );
          },
          // AnimatedContainer: como un Container, pero cuando cambia su
          // color o borde, lo anima durante `duration` en vez de saltar.
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.deepPurple : Colors.deepPurple.shade50,
              border: Border.all(
                color: isToday ? Colors.deepPurple : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              _dayInitials[i],
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: pills,
        ),
        const SizedBox(height: 10),
        Text(
          '${_dayNames[_selected]}: ${_formatSlots(widget.hours[_selected])}',
          style: TextStyle(color: Colors.grey.shade800),
        ),
      ],
    );
  }
}
