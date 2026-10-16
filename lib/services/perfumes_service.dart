

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/perfume.dart';

class PerfumesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late CollectionReference<Perfume> _perfumesRef;

  PerfumesService() {
    _perfumesRef = _db.collection('perfumes').withConverter<Perfume>(
      fromFirestore: Perfume.fromFirestore,
      toFirestore: (Perfume perfume, _) => perfume.toFirestore(),
    );
  }

  Future<List<Perfume>> getPerfumes({int limit = 50}) async {
    try {
      final querySnapshot = await _perfumesRef.limit(limit).get();

      // Convertimos cada DocumentSnapshot<Perfume> en un objeto Perfume limpio
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    }
    catch (e) {
      print('Error al obtener perfumes de Firestore: $e');
      // Relanzamos el error (rethrow) para que la pantalla pueda capturar el fallo
      // y mostrar el estado de error con el botón "Reintentar" que exige la rúbrica.
      rethrow;
    }
  }
}