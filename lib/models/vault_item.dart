import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class VaultItem {
  final String id;
  final String perfumeId;
  final String brand;
  final String name;
  final String imageUrl;
  // null si el perfume no traía los ml y el usuario aún no los ha añadido
  final int? capacityMl;
  final double?
  remainingMl; //Opcionales para no obligar al usuario a rellenarlos
  final double? purchasePrice;
  final double? rating;
  final DateTime addedAt; //Fecha de añadido al armario

  const VaultItem({
    required this.id,
    required this.perfumeId,
    required this.brand,
    required this.name,
    required this.imageUrl,
    required this.capacityMl,
    this.remainingMl,
    this.purchasePrice,
    this.rating,
    required this.addedAt, // Requerido en el constructor
  });
  double get fillPercentage {
    // Copia local: así Dart sabe que tras comprobarla ya no es null
    final int? capacity = capacityMl;
    if (capacity == null) return 0.0;
    // Si por algún error antiguo no hay remainingMl, asumimos que está lleno
    final double actualRemaining = remainingMl ?? capacity.toDouble();
    // Usamos actualRemaining en lugar de remainingMl! para evitar el fallo de nulos
    return (actualRemaining / capacity).clamp(0.0, 1.0);
  }

  double? get costPerSpray {
    if (purchasePrice == null) {
      debugPrint("No se ha definido el precio de compra");
      return null;
    }
    // Sin capacidad no sabemos cuántos sprays tiene el bote
    final int? capacity = capacityMl;
    if (capacity == null) return null;
    if (purchasePrice! <= 0) return 0.0;
    final totalSprays = capacity * 10;

    return purchasePrice! / totalSprays;
  }

  factory VaultItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('El documento VaultItem no contiene datos.');
    }

    // Parseo defensivo num -> int para prevenir errores de tipo de Firestore.
    // Un 0 (de datos antiguos) también cuenta como "sin capacidad".
    final int? capacity = (data['capacityMl'] as num?)?.toInt();

    return VaultItem(
      id: snapshot.id,
      perfumeId: data['perfumeId'] as String? ?? '',
      name: data['perfumeName'] as String? ?? 'Perfume sin nombre',
      brand: data['brand'] as String? ?? 'Marca desconocida',
      imageUrl: data['imageUrl'] as String? ?? '',
      capacityMl: capacity != null && capacity > 0 ? capacity : null,
      //Comprobación por si viene null
      remainingMl: (data['remainingMl'] as num?)?.toDouble(),
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble(),
      // Conversión segura de Timestamp de Firestore a DateTime
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'perfumeId': perfumeId,
      'perfumeName': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'capacityMl': capacityMl,
      'remainingMl': remainingMl,
      'purchasePrice': purchasePrice,
      'rating': rating,
      'addedAt': Timestamp.fromDate(addedAt), // Conversión a formato Firebase
    };
  }
}
