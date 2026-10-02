import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'RetailOffer.dart';
import 'TareInfo.dart';

class Perfume {
  final String id;
  final String brand;
  final String name;
  final int nominalMl;
  final String concentration;
  final String imageUrl;
  final List<String> season;
  final Map<String, List<String>> notes;
  final TareInfo? tareInfo;
  final List<RetailOffer> prices;

  const Perfume({
    required this.id,
    required this.brand,
    required this.name,
    required this.nominalMl,
    required this.concentration,
    required this.imageUrl,
    required this.season,
    required this.notes,
    this.tareInfo,
    this.prices = const [],
  });

  bool get canBeWeighed => tareInfo != null;

  RetailOffer? get bestOffer {
    if (prices.isEmpty) return null;

    final inStockOffers = prices.where((offer) => offer.inStock).toList();
    if (inStockOffers.isEmpty) return null;

    inStockOffers.sort((a, b) => a.price.compareTo(b.price));
    return inStockOffers.first;
  }

  factory Perfume.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,) {
    final data = snapshot.data();
    if (data == null) {
      debugPrint(
          'Error crítico: Documento de Perfume vacío (ID: ${snapshot.id})');
      throw Exception('El documento Firestore no contiene datos.');
    }

  //Revisión previa de que los datos recibidos son los esperados
  Map<String, List<String>> parsedNotes = {};

  if (data['notes'] is Map) {
  final Map<dynamic, dynamic> rawNotes = data['notes'];
  rawNotes.forEach((key, value) {
  if (key is String && value is List) {
  parsedNotes[key] = List<String>.from(value);
  }
  });
  }

  List<String> parsedSeasons = [];
  if (data['season'] is List) {
  parsedSeasons = List<String>.from(data['season']);
  }

  List<RetailOffer> parsedPrices = [];
  if (data['prices'] is List) {
  parsedPrices = (data['prices'] as List)
      .whereType<Map<String, dynamic>>()
      .map((e) => RetailOffer.fromMap(e))
      .toList();
  }
    return Perfume(
      id: snapshot.id,
      brand: data['brand'] as String? ?? 'Desconocida',
      name: data['name'] as String? ?? 'Desconocido',
      nominalMl: (data['nominalMl'] as num?)?.toInt() ?? 0,
      concentration: data['concentration'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      season: parsedSeasons,
      notes: parsedNotes,
      tareInfo: TareInfo.fromMap(data['tareInfo'] as Map<String, dynamic>?),
      prices: parsedPrices,
    );
}
  Map<String, dynamic> toFirestore() {
    return {
      'brand': brand,
      'name': name,
      'nominalMl': nominalMl,
      'concentration': concentration,
      'imageUrl': imageUrl,
      'season': season,
      'notes': notes,
      'tareInfo': tareInfo?.toMap(),
      'prices': prices.map((e) => e.toMap()).toList(),
    };
  }
}