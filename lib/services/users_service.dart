

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class UsersService {
  // 1. Instancia única de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 2. Referencia TIPADA a la colección de usuarios
  late final CollectionReference<UserProfile> _usersRef;

  // 3. Constructor
  UsersService() {
    _usersRef = _db.collection('users').withConverter<UserProfile>(
          fromFirestore: UserProfile.fromFirestore,
          toFirestore: (UserProfile profile, _) => profile.toFirestore(),
        );
  }

  // 4. Función para crear el perfil inicial del usuario
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      final newUserProfile = UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(), // Fecha y hora actuales
        isPublic: false, // Por defecto, el armario (vault) será privado
      );

      // Guardamos en Firestore usando la referencia tipada
      await _usersRef.doc(uid).set(newUserProfile);
      
      debugPrint("Perfil de usuario creado en Firestore con éxito.");
    } catch (e) {
      debugPrint("Error creando el perfil en Firestore: $e");
      throw Exception("No se pudo crear el perfil en la base de datos.");
    }
  }

  // 5. Función para comprobar si un nombre de usuario ya está en uso
  Future<bool> isUsernameAvailable(String displayName) async {
    try {
      // Hacemos una consulta (query) a la colección de usuarios
      // Buscamos si existe ALGÚN documento donde el campo 'displayName'
      // sea exactamente igual al que el usuario quiere registrar.
      final querySnapshot = await _usersRef
          .where('displayName', isEqualTo: displayName)
          .limit(1) // Solo necesitamos encontrar 1 para saber que está pillado
          .get();

      // Si la consulta está vacía (docs.isEmpty es true), el nombre está libre
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      debugPrint("Error comprobando disponibilidad del username: $e");
      // Por seguridad, si falla la base de datos, decimos que no está disponible
      return false; 
    }
  }
}