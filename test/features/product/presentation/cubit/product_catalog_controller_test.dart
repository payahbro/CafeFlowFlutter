import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_catalog_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  final List<Product> products;
  final List<ProductQuery> queries = <ProductQuery>[];

  _FakeProductRepository(this.products);

  @override
  Future<ProductListPage> getProducts(ProductQuery query) async {
    queries.add(query);
    return ProductListPage(
      data: products,
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
  int price = 18000,
}) {
  return Product(
    id: id,
    name: name,
    description: 'Product description',
    price: price,
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
  late _FakeProductRepository repository;
  late ProductCatalogController controller;

  setUp(() {
    repository = _FakeProductRepository(<Product>[
      _product(
        id: 'product-1',
        name: 'Americano',
        category: ProductCategory.coffee,
        status: ProductStatus.available,
      ),
      _product(
        id: 'product-2',
        name: 'Chicken Rice',
        category: ProductCategory.food,
        status: ProductStatus.available,
      ),
      _product(
        id: 'product-3',
        name: 'Iced Latte',
        category: ProductCategory.coffee,
        status: ProductStatus.outOfStock,
      ),
      _product(
        id: 'product-4',
        name: 'Hidden Coffee',
        category: ProductCategory.coffee,
        status: ProductStatus.unavailable,
      ),
    ]);
    controller = ProductCatalogController(GetProductsUseCase(repository));
  });

  tearDown(() {
    controller.dispose();
  });

  test(
    'fetchInitial hides unavailable products from customer catalog',
    () async {
      await controller.fetchInitial();

      expect(controller.products.map((product) => product.name), <String>[
        'Americano',
        'Chicken Rice',
        'Iced Latte',
      ]);
      expect(repository.queries.single.limit, 50);
    },
  );

  test('updateSearch applies local search to remote products', () async {
    await controller.updateSearch('latte');

    expect(controller.products.single.name, 'Iced Latte');
  });

  test(
    'updateCategory applies local category filter to remote products',
    () async {
      await controller.updateCategory(ProductCategory.food);

      expect(controller.products.single.name, 'Chicken Rice');
    },
  );
}
