import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  ProductQuery? lastQuery;

  @override
  Future<ProductListPage> getProducts(ProductQuery query) async {
    lastQuery = query;
    return ProductListPage(
      data: <Product>[
        _product(
          id: 'product-1',
          name: 'Americano',
          category: ProductCategory.coffee,
          status: ProductStatus.available,
        ),
        _product(
          id: 'product-2',
          name: 'Iced Latte',
          category: ProductCategory.coffee,
          status: ProductStatus.outOfStock,
        ),
        _product(
          id: 'product-3',
          name: 'Hidden Tea',
          category: ProductCategory.coffee,
          status: ProductStatus.unavailable,
        ),
      ],
      nextCursor: null,
      prevCursor: null,
      limit: query.limit,
      hasNext: false,
      hasPrev: false,
    );
  }

  @override
  Future<Product> createProduct(UpsertProductInput input) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProduct(String id) => throw UnimplementedError();

  @override
  Future<Product> getProductDetail(String id) => throw UnimplementedError();

  @override
  Future<Product> restoreProduct(String id) => throw UnimplementedError();

  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) =>
      throw UnimplementedError();

  @override
  Future<Product> updateProductStatus(String id, String status) =>
      throw UnimplementedError();
}

Product _product({
  required String id,
  required String name,
  required ProductCategory category,
  required ProductStatus status,
}) {
  return Product(
    id: id,
    name: name,
    description: 'Product description',
    price: 18000,
    category: category,
    status: status,
    imageUrl: 'https://example.com/$id.png',
    rating: 4.5,
    totalSold: 10,
    attributes: const ProductAttributes(
      temperature: <String>['hot'],
      sugarLevels: <String>['normal'],
      iceLevels: <String>['normal'],
      sizes: <String>['small'],
    ),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  test(
    'loadFeatured hides unavailable products but keeps out of stock',
    () async {
      final repository = _FakeProductRepository();
      final controller = ProductHomeController(GetProductsUseCase(repository));

      await controller.loadFeatured();

      expect(repository.lastQuery?.limit, 50);
      expect(controller.products.map((product) => product.name), <String>[
        'Americano',
        'Iced Latte',
      ]);
      expect(controller.errorMessage, isNull);
    },
  );
}
