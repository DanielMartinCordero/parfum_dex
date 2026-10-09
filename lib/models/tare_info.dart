class TareInfo{
  final double emptyBottleWeight; //Peso en gramos del bote de perfume vacío
  final double liquidDensity;

  const TareInfo({
    required this.emptyBottleWeight,
    this.liquidDensity = 0.85, //Densidad estándar del líquido de los perfumes
  });

  static TareInfo? fromMap(Map<String, dynamic>? map){
    if (map == null) //Si el perfume no tiene registro de peso, devolvemos null
      return null;
    final bottleWeight = (map['emptyBottleWeight'] as num?)?.toDouble();
    // Si no hay peso de botella o es <= 0, la tara no es válida.
    if (bottleWeight == null || bottleWeight <= 0) {
      return null;
    }
    return TareInfo(
      emptyBottleWeight: bottleWeight,
      // Si la tapa no existe, puede ser 0 (frascos que se venden sin tapón)
      liquidDensity: (map['liquidDensity'] as num?)?.toDouble() ?? 0.85,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'emptyBottleWeight': emptyBottleWeight,
      'liquidDensity': liquidDensity,
    };
  }
}