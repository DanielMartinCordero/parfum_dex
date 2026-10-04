import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String handle;
  final String displayName;
  final bool isPublic;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.handle,
    required this.displayName,
    this.isPublic = false,
    required this.createdAt,
  });

  // Deserialización tipada para Cloud Firestore
  factory UserProfile.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('El documento de perfil de usuario no contiene datos.');
    }

    return UserProfile(
      uid: snapshot.id,
      email: data['email'] as String? ?? '',
      handle: data['handle'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      isPublic: data['isPublic'] as bool? ?? false,
      // Conversión segura de Timestamp de Firestore a DateTime nativo de Dart
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Serialización para escritura tipada en Cloud Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'handle': handle,
      'displayName': displayName,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}