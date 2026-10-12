import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/perfume.dart';
import '../models/retail_offer.dart';
import '../models/tare_info.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _fb = FirebaseFirestore.instance;

  static Future<void> insertPerfumes() async {
    final collection = _fb.collection('perfumes');

    // 2. Valores de la base de datos (dejamos el ID vacío, Firestore lo ignora al insertar)
    const versaceEros = Perfume(
      id: '',
      name: 'Versace Eros Eau de Toilette',
      brand: 'Versace',
      nominalMl: 100,
      concentration: 'EDT',
      imageUrl: 'https://th.bing.com/th/id/OIP.FGf1D5PU52gYA-bcqtnchwHaHa?w=193&h=193&c=7&r=0&o=7&dpr=2.3&pid=1.7&rm=3',
      season: ['spring', 'summer'],
      notes: {
        'top': ['mint', 'apple', 'lemon'],
        'heart': ['tonka-bean', 'geranium', 'ambroxan'],
        'base': ['vanilla', 'vetiver', 'cedar', 'oakmoss'],
      },
      prices: [],
    );

    const bleuDeChanelEdp = Perfume(
      id: '',
      name: 'Bleu de Chanel Eau de Parfum',
      brand: 'Chanel',
      nominalMl: 100,
      concentration: 'EDP',
      imageUrl: 'https://th.bing.com/th/id/OIP.ECddpOAZ9G1HigL-zAIfkwHaHa?w=179&h=180&c=7&r=0&o=7&dpr=2.3&pid=1.7&rm=3',
      season: ['spring', 'summer', 'fall'],
      notes: {
        'top': ['grapefruit', 'lemon', 'bergamot', 'mint', 'pink-pepper', 'aldehydes', 'coriander'],
        'heart': ['ginger', 'nutmeg', 'jasmine', 'melon'],
        'base': ['incense', 'amber', 'cedar', 'sandalwood', 'patchouli', 'amberwood', 'labdanum'],
      },
      prices: [
        RetailOffer(
          storeName: 'Primor',
          price: 116.95,
          productUrl: 'https://www.primor.eu/es_es/chanel-bleu-de-chanel-eau-de-parfum-141669.html',
          inStock: true,
        ),
        RetailOffer(
          storeName: 'Druni',
          price: 116.95,
          productUrl: 'https://www.druni.es/bleu-chanel-eau-parfum-vaporizador',
          inStock: true,
        ),
      ],
    );

    const diorSauvageEdt = Perfume(
      id: '',
      name: 'Dior Sauvage Eau de Toilette',
      brand: 'Dior',
      nominalMl: 100,
      concentration: 'EDT',
      imageUrl: 'https://www.my-origines.com/dw/image/v2/BJRD_PRD/on/demandware.static/-/Sites-size-master/default/dwfc8a5674/images/29318947_S5.jpg?sw=1500&sh=1500&sm=fit',
      season: ['spring', 'summer', 'fall', 'winter'],
      notes: {
        'top': ['bergamot', 'pepper'],
        'heart': ['sichuan-pepper', 'lavender', 'pink-pepper', 'vetiver', 'patchouli', 'geranium', 'elemi'],
        'base': ['ambroxan', 'cedar', 'labdanum'],
      },
      prices: [
        RetailOffer(
          storeName: 'Primor',
          price: 99.95,
          productUrl: 'https://www.primor.eu/es_es/dior-sauvage-eau-de-toilette-112332.html',
          inStock: true,
        ),
        RetailOffer(
          storeName: 'Druni',
          price: 99.95,
          productUrl: 'https://www.druni.es/sauvage-dior-eau-toilette-hombre',
          inStock: true,
        ),
      ],
    );
    const leBeauLeParfum = Perfume(
      id: '',
      name: 'Jean Paul Gaultier Le Beau Le Parfum',
      brand: 'Jean Paul Gaultier',
      nominalMl: 75,
      concentration: 'EDP',
      imageUrl: 'https://media.parfumo.com/perfume_imagery/fb/fb2bca-le-beau-le-parfum-jean-paul-gaultier_1200.jpg',
      season: ['summer', 'spring', 'fall'],
      notes: {
        'top': ['pineapple', 'iris', 'cypress', 'ginger'],
        'heart': ['coconut', 'woodsy-notes'],
        'base': ['tonka-bean', 'sandalwood', 'amber', 'ambergris'],
      },
      tareInfo: TareInfo(
        emptyBottleWeight: 242.0,
        liquidDensity: 0.85,
      ),
      prices: [
        RetailOffer(
          storeName: 'Primor',
          price: 64.95,
          productUrl: 'https://www.primor.eu/es_es/jean-paul-gaultier-le-beau-edp-112486.html',
          inStock: true,
        ),
        RetailOffer(
          storeName: 'Druni',
          price: 64.95,
          productUrl: 'https://www.druni.es/le-beau-jean-paul-gaultier-eau-parfum-hombre',
          inStock: true,
        ),
      ],
    );
    const oneMillionBlack = Perfume(
      id: '',
      name: 'One Million Black',
      brand: 'Paco Rabanne',
      nominalMl: 200,
      concentration: 'EDP',
      imageUrl: 'https://th.bing.com/th/id/OIP.Z5PAwMAPgmZdI5_hdF8_rwHaHa?w=196&h=197&c=7&r=0&o=7&dpr=2.3&pid=1.7&rm=3',
      season: ['winter', 'fall', 'spring'],
      notes: {
        'top': ['pineapple', 'cardamom', 'blood-orange'],
        'heart': ['vanilla', 'bourbon-vanilla', 'coconut', 'clary-sage'],
        'base': ['tonka-bean', 'ebony-wood', 'patchouli'],
      },
      tareInfo: TareInfo(
        emptyBottleWeight: 333.0,
        liquidDensity: 0.85,
      ),
      prices: [
        RetailOffer(
          storeName: 'Druni',
          price: 102.95,
          productUrl: 'https://www.druni.es/one-million-black-rabanne-eau-parfum-hombre',
          inStock: true,
        ),
        RetailOffer(
          storeName: 'Primor',
          price: 99.94,
          productUrl: 'https://www.primor.eu/es_es/rabanne-1-million-black-eau-de-parfum-151848.html',
          inStock: true,
        ),
      ],
    );

    // 3. Inserción usando .add() que genera el ID automático
    var docRef = await collection.add(leBeauLeParfum.toFirestore());
    docRef = await collection.add(oneMillionBlack.toFirestore());
    docRef = await collection.add(diorSauvageEdt.toFirestore());
    docRef = await collection.add(bleuDeChanelEdp.toFirestore());
    docRef = await collection.add(versaceEros.toFirestore());

    debugPrint(' Layton insertado correctamente con ID automático: ${docRef.id}');
  }
}