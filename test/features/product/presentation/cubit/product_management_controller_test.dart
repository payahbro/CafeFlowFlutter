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
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this._products);

  final List<Product> _products;
  final List<ProductQuery> queries = <ProductQuery>[];

  bool omitDeletedProductsFromList = false;

  @override
  Future<ProductListPage> getProducts(ProductQuery query) async {
    queries.add(query);
    return ProductListPage(
      data: _products
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
  Future<Product> createProduct(UpsertProductInput input) async {
    final product = _product(
      id: 'created-${_products.length + 1}',
      name: input.name ?? 'Created Product',
      status: input.status ?? ProductStatus.available,
    );
    _products.insert(0, product);
    return product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    final index = _products.indexWhere((product) => product.id == id);
    if (index == -1) return;
    final product = _products[index];
    _products[index] = _copyProduct(
      product,
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
    final index = _products.indexWhere((product) => product.id == id);
    final product = _products[index];
    final restored = _copyProduct(
      product,
      status: ProductStatus.available,
      updatedAt: DateTime(2026, 1, 4),
    );
    _products[index] = restored;
    return restored;
  }

  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Product> updateProductStatus(String id, String status) {
    throw UnimplementedError();
  }
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
    price: 24000,
    category: ProductCategory.coffee,
    status: status,
    imageUrl: 'https://invalid.example/$id.png',
    rating: 4.4,
    totalSold: 20,
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

void main() {
  test(
    'deleteProduct keeps a soft-deleted item visible when refresh omits it',
    () async {
      final repository = _FakeProductRepository(<Product>[
        _product(
          id: 'product-1',
          name: 'Latte',
          status: ProductStatus.available,
        ),
      ])..omitDeletedProductsFromList = true;
      final controller = _controller(repository);
      addTearDown(controller.dispose);

      await controller.toggleIncludeDeleted(true);
      await controller.deleteProduct('product-1');

      expect(controller.includeDeleted, isTrue);
      expect(controller.products, hasLength(1));
      expect(controller.products.single.id, 'product-1');
      expect(controller.products.single.status, ProductStatus.unavailable);
      expect(controller.products.single.isDeleted, isTrue);
    },
  );

  test(
    'deleteProduct enables includeDeleted so deleted item stays visible',
    () async {
      final repository = _FakeProductRepository(<Product>[
        _product(
          id: 'product-1',
          name: 'Latte',
          status: ProductStatus.available,
        ),
      ])..omitDeletedProductsFromList = true;
      final controller = _controller(repository);
      addTearDown(controller.dispose);

      await controller.loadProducts();
      expect(controller.includeDeleted, isFalse);

      await controller.deleteProduct('product-1');

      expect(controller.includeDeleted, isTrue);
      expect(controller.products, hasLength(1));
      expect(controller.products.single.id, 'product-1');
      expect(controller.products.single.isDeleted, isTrue);
      expect(repository.queries.last.includeDeleted, isTrue);
    },
  );

  test(
    'restoreProduct keeps restored item visible after restore succeeds',
    () async {
      final repository = _FakeProductRepository(<Product>[
        _product(
          id: 'product-1',
          name: 'Latte',
          status: ProductStatus.unavailable,
          deletedAt: DateTime(2026, 1, 3),
        ),
      ])..omitDeletedProductsFromList = true;
      final controller = _controller(repository);
      addTearDown(controller.dispose);

      await controller.toggleIncludeDeleted(true);
      await controller.restoreProduct('product-1');

      expect(controller.products, hasLength(1));
      expect(controller.products.single.id, 'product-1');
      expect(controller.products.single.status, ProductStatus.available);
      expect(controller.products.single.isDeleted, isFalse);
    },
  );

  test(
    'loadProducts does not notify for products on initial baseline',
    () async {
      final repository = _FakeProductRepository(<Product>[
        _product(
          id: 'product-1',
          name: 'Latte',
          status: ProductStatus.available,
        ),
      ]);
      final controller = _controller(repository);
      addTearDown(controller.dispose);

      await controller.loadProducts();

      expect(controller.newProductNotification, isNull);
    },
  );

  test(
    'createProduct notifies with the created product after reload',
    () async {
      final repository = _FakeProductRepository(<Product>[
        _product(
          id: 'product-1',
          name: 'Latte',
          status: ProductStatus.available,
        ),
      ]);
      final controller = _controller(repository);
      addTearDown(controller.dispose);

      await controller.loadProducts();
      final success = await controller.createProduct(
        const UpsertProductInput(
          name: 'Matcha Latte',
          price: 28000,
          imageUrl: 'https://invalid.example/matcha.png',
        ),
      );

      expect(success, isTrue);
      expect(controller.newProductNotification?.product.name, 'Matcha Latte');

      controller.clearNewProductNotification();

      expect(controller.newProductNotification, isNull);
    },
  );
}
