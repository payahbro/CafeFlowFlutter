import 'package:cafe/features/cart/domain/services/checkout_attribute_resolver.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefers backend-safe coffee defaults from product API options', () {
    final product = _product(
      category: ProductCategory.coffee,
      attributes: const ProductAttributes(
        temperature: <String>['hot', 'iced'],
        sizes: <String>['medium', 'small', 'large'],
        sugarLevels: <String>['normal', 'less'],
        iceLevels: <String>['normal', 'no_ice'],
      ),
    );

    expect(defaultCheckoutAttributes(product), <String, String>{
      'temperature': 'iced',
      'sizes': 'small',
      'sugar_levels': 'less',
      'ice_levels': 'no_ice',
    });
  });

  test(
    'falls back to available coffee options when preferred values are absent',
    () {
      final product = _product(
        category: ProductCategory.coffee,
        attributes: const ProductAttributes(
          temperature: <String>['hot'],
          sizes: <String>['medium'],
          sugarLevels: <String>['normal'],
          iceLevels: <String>['normal'],
        ),
      );

      expect(defaultCheckoutAttributes(product), <String, String>{
        'temperature': 'hot',
        'sizes': 'medium',
        'sugar_levels': 'normal',
      });
    },
  );

  test('prefers backend-safe food defaults from product API options', () {
    final product = _product(
      category: ProductCategory.food,
      attributes: const ProductAttributes(
        portions: <String>['large', 'regular'],
        spicyLevels: <String>['mild', 'no_spicy'],
      ),
    );

    expect(defaultCheckoutAttributes(product), <String, String>{
      'portions': 'regular',
      'spicy_levels': 'no_spicy',
    });
  });
}

Product _product({
  required ProductCategory category,
  required ProductAttributes attributes,
}) {
  final now = DateTime(2026, 6, 17);
  return Product(
    id: 'product-1',
    name: 'Product',
    description: '',
    price: 10000,
    category: category,
    status: ProductStatus.available,
    imageUrl: '',
    rating: 0,
    totalSold: 0,
    attributes: attributes,
    createdAt: now,
    updatedAt: now,
  );
}
