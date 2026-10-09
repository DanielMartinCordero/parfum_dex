import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/perfume.dart';
import '../models/retail_offer.dart';
import '../models/tare_info.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _fb = FirebaseFirestore.instance;

  static Future<void> insertLayton() async {
    final collection = _fb.collection('perfumes');

    // 1. Buscamos si ya existe comprobando marca y nombre
    final query = await collection
        .where('brand', isEqualTo: 'Parfums de Marly')
        .where('name', isEqualTo: 'Layton')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      debugPrint('ℹ El perfume ya existe en Firestore.');
      return;
    }

    // 2. Valores de la base de datos (dejamos el ID vacío, Firestore lo ignora al insertar)
    const layton = Perfume(
      id: '', 
      name: 'Layton',
      brand: 'Parfums de Marly',
      nominalMl: 125,
      concentration: 'EDP',
      imageUrl: 'https://www.libertineparfumerie.com.au/cdn/shop/files/laytonLifestyle_1800x1800.png?v=1719372302',
      season: ['fall', 'winter', 'spring'],
      notes: {
        'top': ['apple', 'bergamot', 'lavender'],
        'heart': ['jasmine', 'violet', 'geranium'],
        'base': ['vanilla', 'pepper', 'guaiac-wood', 'patchouli', 'cardamom'],
      },
      tareInfo: TareInfo(
        emptyBottleWeight: 241.0,
        liquidDensity: 0.85,
      ),
      prices: [
        RetailOffer(
          storeName: 'Notino',
          price: 210.00,
          productUrl: 'https://www.notino.es',
          inStock: true,
        ),
        RetailOffer(
          storeName: 'Druni',
          price: 225.00,
          productUrl: 'https://www.druni.es',
          inStock: true,
        ),
      ],
    );

    // 3. Inserción usando .add() que genera el ID automático
    final docRef = await collection.add(layton.toFirestore());
    debugPrint(' Layton insertado correctamente con ID automático: ${docRef.id}');
  }
}