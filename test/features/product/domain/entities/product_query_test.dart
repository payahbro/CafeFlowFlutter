import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductQuery', () {
    test('clamps limit to 50 in query params', () {
      const query = ProductQuery(limit: 120);
      final params = query.toQueryParameters();

      expect(params['limit'], 50);
      expect(params['direction'], 'next');
      expect(params['sort_by'], 'name');
      expect(params['sort_dir'], 'asc');
    });

    test('serializes category and status using API enum values', () {
      const query = ProductQuery(
        category: ProductCategory.food,
        status: ProductStatus.outOfStock,
      );
      final params = query.toQueryParameters();

      expect(params['category'], 'food');
      expect(params['status'], 'out_of_stock');
    });
  });
}

