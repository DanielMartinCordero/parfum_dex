import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/perfume.dart';
import '../models/vault_item.dart';
import '../utils/validators.dart';

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
    // Si falla la red o los permisos, lanzará la excepción
    final countQuery = await _userVaultRef.count().get();
    return countQuery.count ?? 0;
  }

  // Comprueba si el usuario ya tiene este perfume en la bóveda
  Future<bool> isPerfumeInVault(String perfumeId) async {
    final querySnapshot = await _userVaultRef
        .where('perfumeId', isEqualTo: perfumeId)
        .limit(1)
        .get();
        
    return querySnapshot.docs.isNotEmpty;
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
        // Si el perfume no trae ml, quedan en null hasta que el usuario los añada
        capacityMl: perfume.nominalMl,
        remainingMl: perfume.nominalMl?.toDouble(),
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

  // Guarda los atributos que puede editar el usuario. Recibe los valores finales
  // de los campos: un precio o una valoración en null borra ese dato.
  // capacityMl solo se usa si el perfume aún no tenía capacidad: la que ya
  // venía del catálogo no se puede cambiar.
  // Devuelve true si ha guardado algo y false si no había nada que cambiar.
  Future<bool> updateVaultItem(
    VaultItem item, {
    int? capacityMl,
    double? remainingMl,
    double? purchasePrice,
    double? rating,
  }) async {
    final int? capacity = item.capacityMl ?? capacityMl;
    // Sin capacidad no tiene sentido guardar los ml restantes
    final double? remaining = capacity != null ? remainingMl : null;

    // Comprobamos en local antes de gastar una escritura en Firestore
    final String? error =
        Validators.validateCapacityMl(capacity) ??
        (capacity != null && remaining != null
            ? Validators.validateRemainingMl(remaining, capacity)
            : null) ??
        Validators.validatePurchasePrice(purchasePrice) ??
        Validators.validateRating(rating);
    if (error != null) {
      throw Exception(error);
    }
    if (capacity == item.capacityMl &&
        remaining == item.remainingMl &&
        purchasePrice == item.purchasePrice &&
        rating == item.rating) {
      print("No hay valores diferetes a los actuales");
      return false;
    }
    try {
      // update() solo toca estos campos, el resto del documento se queda igual
      await _userVaultRef.doc(item.id).update({
        'capacityMl': capacity,
        'remainingMl': remaining,
        'purchasePrice': purchasePrice,
        'rating': rating,
      });
      print("Perfume actualizado con éxito");
      return true;
    } catch (e) {
      print('Error al actualizar el perfume: $e');
      rethrow;
    }
  }

  Future<void> removeFromVault(String itemId) async {
    try {
      await _userVaultRef.doc(itemId).delete();
      print("Perfume eliminado con éxito");
    } catch (e) {
      print('Error al eliminar el perfume: $e');
      rethrow;
    }
  }
}
