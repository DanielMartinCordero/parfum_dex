import 'dart:isolate';

import 'ranking_core.dart';

// Android (y cualquier plataforma nativa): el cálculo va en un isolate.

/// Para el registro de tiempos: aquí sí se usa un isolate.
const usesIsolate = true;

/// Ordena [points] por distancia a ([lat], [lng]) en un isolate aparte, y
/// va avisando del progreso con [onProgress] desde el hilo principal.
///
/// Un isolate no comparte memoria con el hilo principal: solo se comunican
/// enviándose mensajes. El resultado vuelve con Isolate.run, y el progreso
/// llega por un ReceivePort (el "buzón" del hilo principal), cuyo SendPort
/// (la "dirección" de ese buzón) se le pasa al isolate.
Future<List<RankedPoint>> rankPoints(
  double lat,
  double lng,
  List<GeoCoord> points,
  void Function(double progress)? onProgress,
) async {
  final progressPort = ReceivePort();
  progressPort.listen((message) {
    if (message is double && onProgress != null) onProgress(message);
  });

  try {
    return await _runInIsolate(lat, lng, points, progressPort.sendPort);
  } finally {
    // Sin esto el puerto seguiría abierto y la app nunca lo liberaría.
    progressPort.close();
  }
}

/// Va en una función aparte a propósito: la función que recibe Isolate.run
/// se copia al otro isolate junto con todo lo que usa. Aquí solo usa números,
/// una lista de records y un SendPort, que se pueden enviar. Si se escribiera
/// dentro de rankPoints, podría arrastrar también onProgress (que apunta al
/// widget) y fallar con "object is unsendable".
Future<List<RankedPoint>> _runInIsolate(
  double lat,
  double lng,
  List<GeoCoord> points,
  SendPort progress,
) {
  return Isolate.run(() {
    return rankPointsSync(lat, lng, points, onProgress: progress.send);
  });
}
