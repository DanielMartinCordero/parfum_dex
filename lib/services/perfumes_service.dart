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

  // Perfumes por página. 48 llena filas completas con 2, 3, 4 y 6 columnas,
  // y no pasa del máximo de 50 que permiten las reglas (smallList(50))
  static const int pageSize = 48;

  // Una página del catálogo ordenada por nombre (paginación por cursor).
  // La primera vez, startAfter es null. Para la siguiente página se pasa el
  // lastDoc que devolvió la anterior, y Firestore empieza justo detrás de él
  Future<({List<Perfume> perfumes, DocumentSnapshot<Perfume>? lastDoc})>
      getPerfumesPage({DocumentSnapshot<Perfume>? startAfter}) async {
    try {
      Query<Perfume> query = _perfumesRef.orderBy('name').limit(pageSize);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final querySnapshot = await query.get();
      // Convertimos cada DocumentSnapshot<Perfume> en un objeto Perfume limpio
      return (
        perfumes: querySnapshot.docs.map((doc) => doc.data()).toList(),
        // Guardamos el último documento: es el cursor de la página siguiente
        lastDoc: querySnapshot.docs.isEmpty ? null : querySnapshot.docs.last,
      );
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
