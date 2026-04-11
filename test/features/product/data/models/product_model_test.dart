import 'package:cafe/features/product/data/models/product_model.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProductModel parses API payload fields and enums', () {
    final model = ProductModel.fromJson(<String, dynamic>{
      'id': 'uuid-1',
      'name': 'Americano',
      'description': 'Desc',
      'price': 25000,
      'category': 'coffee',
      'status': 'available',
      'image_url': 'https://example.com/image.png',
      'rating': 4.5,
      'total_sold': 12,
      'attributes': {
        'temperature': ['hot', 'iced'],
        'sizes': ['small'],
      },
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:00Z',
      'deleted_at': null,
    });

    expect(model.category, ProductCategory.coffee);
    expect(model.status, ProductStatus.available);
    expect(model.attributes.temperature, ['hot', 'iced']);
    expect(model.attributes.sizes, ['small']);
    expect(model.deletedAt, isNull);
  });
}

