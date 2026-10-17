class RetailOffer {
  final String storeName;
  final double price;
  final String productUrl;
  final bool inStock;

  const RetailOffer({
    required this.storeName,
    required this.price,
    required this.productUrl,
    this.inStock = true,
  });

  factory RetailOffer.fromMap(Map<String, dynamic> map) {
    return RetailOffer(
      storeName: map['storeName'] as String? ?? 'Tienda desconocida',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      productUrl: map['productUrl'] as String? ?? '',
      inStock: map['inStock'] as bool? ?? true,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'price': price,
      'productUrl': productUrl,
      'inStock': inStock,
    };
  }
}
