import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../utils/username_generator.dart';

import 'package:flutter/foundation.dart'; // Para debugPrint

class UsersService {
  // 1. Instancia única de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 2. Referencia TIPADA a la colección de usuarios
  late final CollectionReference<UserProfile> _usersRef;

  // 3. Constructor
  UsersService() {
    _usersRef = _db
        .collection('users')
        .withConverter<UserProfile>(
          fromFirestore: UserProfile.fromFirestore,
          toFirestore: (UserProfile profile, _) => profile.toFirestore(),
        );
  }

  // 4. Crea el perfil del usuario reservando un username único.
  //    Prueba los candidatos del generador hasta que uno esté libre.
  Future<UserProfile> claimUsername({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final base = UsernameGenerator.normalize(displayName);

    for (final handle in UsernameGenerator.candidates(base)) {
      final profile = UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        username: handle,
        createdAt: DateTime.now(), // Fecha y hora actuales
        isPublic: false, // Por defecto, el armario (vault) será privado
      );

      try {
        await _createProfileWithUsername(profile);
        debugPrint("Perfil creado con el username '$handle'.");
        return profile;
      } on FirebaseException catch (e) {
        // Si el handle ya existe, las reglas de Firestore rechazan la
        // escritura con 'permission-denied': probamos con el siguiente.
        if (e.code != 'permission-denied') rethrow;
        debugPrint("El username '$handle' está ocupado, probando otro...");
      }
    }

    throw Exception("No se pudo generar un nombre de usuario único.");
  }

  // 5. Un único intento: reserva el handle y guarda el perfil a la vez.
  //    El batch es atómico: o se escriben los dos documentos o ninguno.
  Future<void> _createProfileWithUsername(UserProfile profile) {
    final batch = _db.batch();

    batch.set(_db.collection('usernames').doc(profile.username), {
      'uid': profile.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_usersRef.doc(profile.uid), profile);

    return batch.commit();
  }

  // 6. Obtener el perfil del usuario actual
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final docSnapshot = await _usersRef.doc(user.uid).get();
      return docSnapshot.data();
    } catch (e) {
      debugPrint("Error al obtener el perfil: $e");
      return null;
    }
  }

  // 7. Actualizar el nombre (displayName)
  Future<void> updateDisplayName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuario no logueado");

    try {
      // A) Actualizamos en Auth
      await user.updateDisplayName(newName);

      // B) Actualizamos en Firestore (solo ese campo específico)
      await _usersRef.doc(user.uid)
          .update({'displayName': newName});

    } catch (e) {
      debugPrint("Error al actualizar el nombre: $e");
      rethrow;
    }
  }
}
