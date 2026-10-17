import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/perfume.dart';

class PerfumesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late CollectionReference<Perfume> _perfumesRef;

  PerfumesService() {
    _perfumesRef = _db
        .collection('perfumes')
        .withConverter<Perfume>(
          fromFirestore: Perfume.fromFirestore,
          toFirestore: (Perfume perfume, _) => perfume.toFirestore(),
        );
  }

  Future<List<Perfume>> getPerfumes({int limit = 50}) async {
    try {
      final querySnapshot = await _perfumesRef.limit(limit).get();
      print("Perfumes obtenidos de Firestore");
      // Convertimos cada DocumentSnapshot<Perfume> en un objeto Perfume limpio
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error al obtener perfumes de Firestore: $e');
      // Relanzamos el error (rethrow) para que la pantalla pueda capturar el fallo
      // y mostrar el estado de error con el botón "Reintentar".
      rethrow;
    }
  }

  Future<Perfume?> getPerfumeById(String perfumeId) async {
    try {
      // Optimizamos la lectura: al saber el ID del documento, accedemos directamente
      // sin necesidad de hacer una query con .where(). Es más barato y rápido.
      final docSnapshot = await _perfumesRef.doc(perfumeId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      } else {
        print('No se encontró el perfume con ID: $perfumeId');
        return null;
      }
    } catch (e) {
      print('Error al obtener el perfume de Firestore: $e');
      return null;
    }
  }
}
