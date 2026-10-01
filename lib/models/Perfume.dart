import 'RetailOffer.dart';
import 'TareInfo.dart';

class Perfume{
  final String id;
  final String brand;
  final String name;
  final double nominalMl;
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
}