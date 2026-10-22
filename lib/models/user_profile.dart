import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final bool isPublic;
  final DateTime createdAt;
  final String? genre;
  final int? birthYear;
  final String? scentPreference;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.isPublic = false,
    required this.createdAt,
    this.genre,
    this.birthYear,
    this.scentPreference,
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
      displayName: data['displayName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      isPublic: data['isPublic'] as bool? ?? false,
      // Conversión segura de Timestamp de Firestore a DateTime nativo de Dart
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      genre: data['genre'] as String?,
      birthYear: data['birthYear'] as int?,
      scentPreference: data['scentPreference'] as String?,
    );
  }

  // Serialización para escritura tipada en Cloud Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      if (genre != null) 'genre': genre,
      if (birthYear != null) 'birthYear': birthYear,
      if (scentPreference != null) 'scentPreference': scentPreference,
    };
  }

  // Método copyWith para crear copias con datos actualizados
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    bool? isPublic,
    DateTime? createdAt,
    String? genre,
    int? birthYear,
    String? scentPreference,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      genre: genre ?? this.genre,
      birthYear: birthYear ?? this.birthYear,
      scentPreference: scentPreference ?? this.scentPreference,
    );
  }
}
