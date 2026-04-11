class ProductAttributes {
  const ProductAttributes({
    this.temperature = const <String>[],
    this.sugarLevels = const <String>[],
    this.iceLevels = const <String>[],
    this.sizes = const <String>[],
    this.portions = const <String>[],
    this.spicyLevels = const <String>[],
  });

  final List<String> temperature;
  final List<String> sugarLevels;
  final List<String> iceLevels;
  final List<String> sizes;
  final List<String> portions;
  final List<String> spicyLevels;

  bool get isCoffee =>
      temperature.isNotEmpty || sugarLevels.isNotEmpty || sizes.isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (temperature.isNotEmpty) 'temperature': temperature,
      if (sugarLevels.isNotEmpty) 'sugar_levels': sugarLevels,
      if (iceLevels.isNotEmpty) 'ice_levels': iceLevels,
      if (sizes.isNotEmpty) 'sizes': sizes,
      if (portions.isNotEmpty) 'portions': portions,
      if (spicyLevels.isNotEmpty) 'spicy_levels': spicyLevels,
    };
  }
}

