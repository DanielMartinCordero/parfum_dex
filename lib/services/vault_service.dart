import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Usamos un Stream para escuchar los cambios en tiempo real, pues desde explore_screen
  // se harán cambios que deben ser visibles en vault_screen
  Stream<List<VaultItem>> streamUserVault() {
    // Limitamos la consulta a los 5 últimos añadidos por si acaso,
    // aunque la lógica visual de la app ya bloqueará añadir más de 5.
    return _userVaultRef
        .orderBy('createdAt', descending: true)
        .limit(freeLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
