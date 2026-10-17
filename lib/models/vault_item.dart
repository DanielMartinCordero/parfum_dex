import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class VaultItem {
  final String id;
  final String perfumeId;
  final String brand;
  final String name;
  final String imageUrl;
  final String itemType; //Bote o decant
  final int capacityMl;
  final double?
  remainingMl; //Opcionales para no obligar al usuario a rellenarlos
  final double? purchasePrice;
  final double? rating;

  const VaultItem({
    required this.id,
    required this.perfumeId,
    required this.brand,
    required this.name,
    required this.imageUrl,
    required this.itemType,
    required this.capacityMl,
    this.remainingMl,
    this.purchasePrice,
    this.rating,
  });
  double? get fillPercentage {
    if (remainingMl == null) {
      debugPrint('Error: El nivel de llenado no está definido.');
      return null;
    }
    if (capacityMl <= 0) return 0.0;
    return (remainingMl! / capacityMl).clamp(0.0, 1.0);
  }

  double? get costPerSpray {
    if (purchasePrice == null) {
      debugPrint("Error: El precio de compra no está definido.");
      return null;
    }
    if (capacityMl <= 0 || purchasePrice! <= 0) return 0.0;
    final totalSprays = capacityMl * 10;

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

    return VaultItem(
      id: snapshot.id,
      perfumeId: data['perfumeId'] as String? ?? '',
      name: data['perfumeName'] as String? ?? 'Perfume sin nombre',
      brand: data['brand'] as String? ?? 'Marca desconocida',
      imageUrl: data['imageUrl'] as String? ?? '',
      itemType: data['itemType'] as String? ?? 'bottle',
      // Parseo defensivo num -> int para prevenir errores de tipo de Firestore
      capacityMl: (data['capacityMl'] as num?)?.toInt() ?? 0,
      //Comprobación por si viene null
      remainingMl: (data['remainingMl'] as num?)?.toDouble(),
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'perfumeId': perfumeId,
      'perfumeName': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'itemType': itemType,
      'capacityMl': capacityMl,
      'remainingMl': remainingMl,
      'purchasePrice': purchasePrice,
      'rating': rating,
    };
  }
}
