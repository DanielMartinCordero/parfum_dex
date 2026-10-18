import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/perfume.dart';
import '../models/vault_item.dart';

class VaultService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int freeLimit = 5; //Límite del plan gratis

  // Metodo que nos devuelve la referencia a la subcolección
  // del usuario logueado en este instante.
  CollectionReference<VaultItem> get _userVaultRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('vault')
        .withConverter<VaultItem>(
          fromFirestore: VaultItem.fromFirestore,
          toFirestore: (VaultItem vaultItem, _) => vaultItem.toFirestore(),
        );
  }
  Future<int> getVaultItemsCount() async {
    try {
      // Hacemos una consulta Count
      final countQuery = await _userVaultRef.count().get();
      return countQuery.count ?? 0;
    }
    catch (e) {
      print('Error al contar los perfumes: $e');
      return 0;
    }
  }

  // Comprueba si el usuario ya tiene este perfume en la bóveda
  Future<bool> isPerfumeInVault(String perfumeId) async {
    try {
      final querySnapshot = await _userVaultRef
          .where('perfumeId', isEqualTo: perfumeId)
          .limit(1)
          .get();
          
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error al comprobar si el perfume existe: $e');
      return false; // Ante la duda o error de red, asumimos false para no bloquear la app
    }
  }
  // Usamos un Stream para escuchar los cambios en tiempo real, pues desde explore_screen
  // se harán cambios que deben ser visibles en vault_screen
  Stream<List<VaultItem>> streamUserVault() {
    // Limitamos la consulta a los 5 últimos añadidos por si acaso,
    // ordenados por la fecha de añadido (el más reciente primero)
    return _userVaultRef
        .orderBy('addedAt', descending: true)
        .limit(freeLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  Future<void> addPerfumeToVault(Perfume perfume) async{
    try{
      final newPerfume = VaultItem(
        id: '',
        perfumeId: perfume.id,
        brand: perfume.brand,
        name: perfume.name,
        imageUrl: perfume.imageUrl,
        capacityMl: perfume.nominalMl,
        remainingMl: perfume.nominalMl.toDouble(),
        purchasePrice: 0.0,
        rating: 0.0,
        addedAt: DateTime.now(), // Asignamos la fecha exacta de ahora
      );
      await _userVaultRef.add(newPerfume);
      print("Perfume añadido con éxito");
    }
    catch(e){
      print('Error al añadir el perfume a la bolsa: $e');
      rethrow;
    }

  }
}
