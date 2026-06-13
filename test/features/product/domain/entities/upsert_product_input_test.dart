import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromProductEdit sends only changed price for partial update', () {
    final product = _product(price: 25000);

    final input = UpsertProductInput.fromProductEdit(
      original: product,
      name: product.name,
      description: product.description,
      price: 32000,
      category: product.category,
      status: product.status,
      imageUrl: product.imageUrl,
      attributes: product.attributes,
    );

    expect(input.toJson(), <String, dynamic>{'price': 32000});
  });

  test('fromProductEdit sends category when attributes changed', () {
    final product = _product();
    const changedAttributes = ProductAttributes(
      temperature: <String>['hot'],
      sugarLevels: <String>['normal'],
      iceLevels: <String>['normal'],
      sizes: <String>['small', 'medium'],
    );

    final input = UpsertProductInput.fromProductEdit(
      original: product,
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category,
      status: product.status,
      imageUrl: product.imageUrl,
      attributes: changedAttributes,
    );

    expect(input.toJson(), <String, dynamic>{
      'category': 'coffee',
      'attributes': changedAttributes.toJson(),
    });
  });
}

Product _product({int price = 25000}) {
  final now = DateTime(2026, 1, 1);
  return Product(
    id: 'product-1',
    name: 'Americano',
    description: 'Espresso',
    price: price,
    category: ProductCategory.coffee,
    status: ProductStatus.available,
    imageUrl:
        'https://kangzprbrstwuuejpmso.supabase.co/storage/v1/object/public/products/americano.png',
    rating: 4.5,
    totalSold: 10,
    attributes: const ProductAttributes(
      temperature: <String>['hot'],
      sugarLevels: <String>['normal'],
      iceLevels: <String>['normal'],
      sizes: <String>['small'],
    ),
    createdAt: now,
    updatedAt: now,
  );
}
