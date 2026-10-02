
class UserItem{
  final String id;
  final String perfumeId;
  final String brand;
  final String name;
  final String imageUrl;
  final String itemType; //Bote o decant
  final int capacityMl;
  final double? remainingMl; //Opcionales para no obligar al usuario a rellenarlos
  final double? purchasePrice;
  final double? rating;

  const UserItem({
    required this.id,
    required this.perfumeId,
    required this.brand,
    required this.name,
    required this.imageUrl,
    required this.itemType,
    required this.capacityMl,
    this.remainingMl,
    this.purchasePrice,
    this.rating = 0.0,
  });

}