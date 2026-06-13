import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/create_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/domain/usecases/restore_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_status_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_management_controller.dart';
import 'package:cafe/features/product/presentation/pages/product_management_page.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.products);

  final List<Product> products;
  final List<ProductQuery> queries = <ProductQuery>[];
  bool omitDeletedProductsFromList = false;

  @override
  Future<ProductListPage> getProducts(ProductQuery query) async {
    queries.add(query);
    return ProductListPage(
      data: products
          .where((product) {
            if (product.isDeleted) {
              return query.includeDeleted && !omitDeletedProductsFromList;
            }
            return true;
          })
          .toList(growable: false),
      nextCursor: null,
      prevCursor: null,
      limit: query.limit,
      hasNext: false,
      hasPrev: false,
    );
  }

  @override
  Future<Product> createProduct(UpsertProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProduct(String id) async {
    final index = products.indexWhere((product) => product.id == id);
    if (index == -1) return;
    products[index] = _copyProduct(
      products[index],
      status: ProductStatus.unavailable,
      updatedAt: DateTime(2026, 1, 3),
      deletedAt: DateTime(2026, 1, 3),
    );
  }

  @override
  Future<Product> getProductDetail(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Product> restoreProduct(String id) async {
    final index = products.indexWhere((product) => product.id == id);
    final restored = _copyProduct(
      products[index],
      status: ProductStatus.available,
      updatedAt: DateTime(2026, 1, 4),
    );
    products[index] = restored;
    return restored;
  }

  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) async {
    return products.singleWhere((product) => product.id == id);
  }

  @override
  Future<Product> updateProductStatus(String id, String status) async {
    return products.singleWhere((product) => product.id == id);
  }
}

Product _copyProduct(
  Product product, {
  ProductStatus? status,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  return Product(
    id: product.id,
    name: product.name,
    description: product.description,
    price: product.price,
    category: product.category,
    status: status ?? product.status,
    imageUrl: product.imageUrl,
    rating: product.rating,
    totalSold: product.totalSold,
    attributes: product.attributes,
    createdAt: product.createdAt,
    updatedAt: updatedAt ?? product.updatedAt,
    deletedAt: deletedAt,
  );
}

ProductManagementController _controller(_FakeProductRepository repository) {
  return ProductManagementController(
    getProductsUseCase: GetProductsUseCase(repository),
    createProductUseCase: CreateProductUseCase(repository),
    updateProductUseCase: UpdateProductUseCase(repository),
    updateProductStatusUseCase: UpdateProductStatusUseCase(repository),
    deleteProductUseCase: DeleteProductUseCase(repository),
    restoreProductUseCase: RestoreProductUseCase(repository),
  );
}

Product _product({
  required String id,
  required String name,
  required ProductStatus status,
  DateTime? deletedAt,
}) {
  final now = DateTime(2026, 1, 1);
  return Product(
    id: id,
    name: name,
    description: 'Product description',
    price: 20000,
    category: ProductCategory.coffee,
    status: status,
    imageUrl: 'https://invalid.example/$id.png',
    rating: 4.2,
    totalSold: 10,
    attributes: const ProductAttributes(
      temperature: <String>['hot'],
      sizes: <String>['small'],
      sugarLevels: <String>['normal'],
      iceLevels: <String>['normal'],
    ),
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required ProductManagementController controller,
  UserRole role = UserRole.admin,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProductManagementPage(role: role, controller: controller),
    ),
  );
  await tester.pumpAndSettle();
}

ListTile _listTile(WidgetTester tester, String title) {
  final tile = find.ancestor(
    of: find.text(title),
    matching: find.byType(ListTile),
  );
  return tester.widget<ListTile>(tile);
}

void main() {
  testWidgets('admin product management loads with deleted products included', (
    tester,
  ) async {
    final repository = _FakeProductRepository(<Product>[
      _product(
        id: 'deleted-product',
        name: 'Deleted Latte',
        status: ProductStatus.unavailable,
        deletedAt: DateTime(2026, 1, 2),
      ),
    ]);

    await _pumpPage(tester, controller: _controller(repository));

    expect(repository.queries.single.includeDeleted, isTrue);
    expect(find.text('Deleted Latte'), findsOneWidget);
  });

  testWidgets('admin can manage unavailable product that is not deleted', (
    tester,
  ) async {
    final repository = _FakeProductRepository(<Product>[
      _product(
        id: 'unavailable-product',
        name: 'Unavailable Latte',
        status: ProductStatus.unavailable,
      ),
    ]);

    await _pumpPage(tester, controller: _controller(repository));

    await tester.tap(find.text('Unavailable Latte'));
    await tester.pumpAndSettle();

    expect(_listTile(tester, 'Update status').enabled, isTrue);
    expect(_listTile(tester, 'Edit produk').enabled, isTrue);
    expect(_listTile(tester, 'Soft delete produk').enabled, isTrue);
    expect(_listTile(tester, 'Restore produk').enabled, isFalse);
  });

  testWidgets('admin can only restore soft-deleted product', (tester) async {
    final repository = _FakeProductRepository(<Product>[
      _product(
        id: 'deleted-product',
        name: 'Deleted Latte',
        status: ProductStatus.unavailable,
        deletedAt: DateTime(2026, 1, 2),
      ),
    ]);

    await _pumpPage(tester, controller: _controller(repository));

    await tester.tap(find.text('Deleted Latte'));
    await tester.pumpAndSettle();

    expect(_listTile(tester, 'Update status').enabled, isFalse);
    expect(_listTile(tester, 'Edit produk').enabled, isFalse);
    expect(_listTile(tester, 'Soft delete produk').enabled, isFalse);
    expect(_listTile(tester, 'Restore produk').enabled, isTrue);
  });

  testWidgets('admin keeps product visible after soft delete', (tester) async {
    final repository = _FakeProductRepository(<Product>[
      _product(
        id: 'product-to-delete',
        name: 'Delete Me Latte',
        status: ProductStatus.available,
      ),
    ])..omitDeletedProductsFromList = true;

    await _pumpPage(tester, controller: _controller(repository));

    await tester.tap(find.text('Delete Me Latte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Soft delete produk'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Me Latte'), findsOneWidget);
    expect(find.text('soft-deleted'), findsOneWidget);

    await tester.tap(find.text('Delete Me Latte'));
    await tester.pumpAndSettle();

    expect(_listTile(tester, 'Restore produk').enabled, isTrue);
  });

  testWidgets('admin can restore product with available status and deletedAt', (
    tester,
  ) async {
    final repository = _FakeProductRepository(<Product>[
      _product(
        id: 'manually-available-deleted-product',
        name: 'Manual Latte',
        status: ProductStatus.available,
        deletedAt: DateTime(2026, 1, 2),
      ),
    ]);

    await _pumpPage(tester, controller: _controller(repository));

    expect(find.text('Manual Latte'), findsOneWidget);
    expect(find.text('soft-deleted'), findsOneWidget);

    await tester.tap(find.text('Manual Latte'));
    await tester.pumpAndSettle();

    expect(_listTile(tester, 'Restore produk').enabled, isTrue);
  });
}
