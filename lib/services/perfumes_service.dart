

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/perfume.dart';

class PerfumesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late CollectionReference<Perfume> _perfumesRef;

  PerfumesService(){
    _perfumesRef = _db.collection('perfumes').withConverter<Perfume>(
      fromFirestore: Perfume.fromFirestore,
      toFirestore: (Perfume perfume, _) => perfume.toFirestore(),
    );
  }

}