import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';

Map<String, String> defaultCheckoutAttributes(Product product) {
  if (product.category == ProductCategory.coffee) {
    return _coffeeDefaults(product);
  }

  return _foodSnackDefaults(product);
}

Map<String, String> _coffeeDefaults(Product product) {
  final attributes = product.attributes;
  final temperature = _preferredOrFirst(
    attributes.temperature,
    preferred: 'iced',
    fallback: 'iced',
  );
  final selected = <String, String>{
    'temperature': temperature,
    'sizes': _preferredOrFirst(
      attributes.sizes,
      preferred: 'small',
      fallback: 'small',
    ),
    'sugar_levels': _preferredOrFirst(
      attributes.sugarLevels,
      preferred: 'less',
      fallback: 'less',
    ),
  };

  if (temperature == 'iced') {
    selected['ice_levels'] = _preferredOrFirst(
      attributes.iceLevels,
      preferred: 'no_ice',
      fallback: 'no_ice',
    );
  }

  return selected;
}

Map<String, String> _foodSnackDefaults(Product product) {
  final attributes = product.attributes;
  return <String, String>{
    'portions': _preferredOrFirst(
      attributes.portions,
      preferred: 'regular',
      fallback: 'regular',
    ),
    'spicy_levels': _preferredOrFirst(
      attributes.spicyLevels,
      preferred: 'no_spicy',
      fallback: 'no_spicy',
    ),
  };
}

String _preferredOrFirst(
  List<String> options, {
  required String preferred,
  required String fallback,
}) {
  if (options.contains(preferred)) {
    return preferred;
  }

  if (options.isNotEmpty) {
    return options.first;
  }

  return fallback;
}
