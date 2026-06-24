import 'dart:async';

import 'package:cafe/features/cart/domain/entities/cart.dart';
import 'package:cafe/features/cart/domain/entities/cart_item.dart';
import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';
import 'package:cafe/features/cart/domain/usecases/add_cart_item_usecase.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/presentation/pages/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this._product, {Future<Product>? detailFuture})
    : _detailFuture = detailFuture;

  final Product _product;
  final Future<Product>? _detailFuture;
  int getDetailCallCount = 0;

  @override
  Future<Product> getProductDetail(String id) async {
    getDetailCallCount += 1;
    return _detailFuture ?? _product;
  }

  @override
  Future<ProductListPage> getProducts(ProductQuery query) {
    throw UnimplementedError();
  }

  @override
  Future<Product> createProduct(UpsertProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Product> updateProductStatus(String id, String status) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProduct(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Product> restoreProduct(String id) {
    throw UnimplementedError();
  }
}

class _FakeCartRepository implements CartRepository {
  int addItemCallCount = 0;
  Map<String, String>? lastAttributes;

  static const Cart _emptyCart = Cart(
    cartId: null,
    userId: 'test-user',
    items: <CartItem>[],
    grandTotal: 0,
    updatedAt: null,
  );

  @override
  Future<Cart> getMyCart() async {
    return _emptyCart;
  }

  @override
  Future<Cart> addItem({
    required String productId,
    required int quantity,
    required Map<String, String> attributes,
  }) async {
    addItemCallCount += 1;
    lastAttributes = attributes;
    return _emptyCart;
  }

  @override
  Future<Cart> updateItemQuantity({
    required String itemId,
    required int quantity,
  }) async {
    return _emptyCart;
  }

  @override
  Future<void> removeItem(String itemId) async {}

  @override
  Future<void> clearMyCart() async {}
}

Product _baseProduct({
  required ProductCategory category,
  required ProductAttributes attributes,
  ProductStatus status = ProductStatus.available,
  double rating = 0,
  String description = 'Espresso dengan air panas',
}) {
  final now = DateTime(2026, 1, 1);
  return Product(
    id: 'uuid',
    name: 'Americano',
    description: description,
    price: 25000,
    category: category,
    status: status,
    imageUrl: 'https://invalid.example/image.png',
    rating: rating,
    totalSold: 0,
    attributes: attributes,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets(
    'Initial catalog product is refreshed with the complete product detail',
    (tester) async {
      final initialProduct = _baseProduct(
        category: ProductCategory.snack,
        attributes: const ProductAttributes(
          portions: <String>['regular', 'large'],
        ),
        description: '',
      );
      final detailedProduct = _baseProduct(
        category: ProductCategory.snack,
        attributes: const ProductAttributes(
          portions: <String>['regular', 'large'],
        ),
        description: 'Deskripsi lengkap dari backend',
      );
      final detailCompleter = Completer<Product>();
      final repository = _FakeProductRepository(
        detailedProduct,
        detailFuture: detailCompleter.future,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(
            productId: initialProduct.id,
            initialProduct: initialProduct,
            getProductDetailUseCase: GetProductDetailUseCase(repository),
            addCartItemUseCase: AddCartItemUseCase(_FakeCartRepository()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('"Deskripsi produk belum tersedia"'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(repository.getDetailCallCount, 1);

      detailCompleter.complete(detailedProduct);
      await tester.pumpAndSettle();

      expect(find.text('"Deskripsi lengkap dari backend"'), findsOneWidget);
      expect(find.text('"Deskripsi produk belum tersedia"'), findsNothing);
    },
  );

  testWidgets('Phone layout keeps image height and uses compact controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = _baseProduct(
      category: ProductCategory.food,
      attributes: const ProductAttributes(
        portions: <String>['regular', 'large'],
        spicyLevels: <String>['no_spicy', 'mild', 'medium', 'hot'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(
          productId: 'uuid',
          getProductDetailUseCase: GetProductDetailUseCase(
            _FakeProductRepository(product),
          ),
          addCartItemUseCase: AddCartItemUseCase(_FakeCartRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('product-detail-header'))).height,
      56,
    );
    expect(
      tester.getSize(find.byKey(const Key('product-detail-image'))).height,
      340,
    );

    final productName = tester.widget<Text>(find.text('Americano'));
    expect(productName.style?.fontSize, 32);
    expect(tester.widget<Text>(find.text('MAKANAN')).style?.fontSize, 12);
    expect(tester.widget<Text>(find.text('Rp 25.000')).style?.fontSize, 28);
    expect(
      tester
          .widget<Text>(find.text('"Espresso dengan air panas"'))
          .style
          ?.fontSize,
      16,
    );
    expect(tester.widget<Text>(find.text('PORTION')).style?.fontSize, 12);

    await tester.ensureVisible(find.text('Regular'));
    expect(
      tester
          .getSize(find.byKey(const Key('product-detail-pill-Regular')))
          .height,
      46,
    );

    expect(
      tester
          .getSize(find.byKey(const Key('product-detail-add-to-cart')))
          .height,
      54,
    );
  });

  testWidgets(
    'Coffee product: shows coffee attributes and toggles Ice on iced',
    (tester) async {
      final product = _baseProduct(
        category: ProductCategory.coffee,
        rating: 4.5,
        attributes: const ProductAttributes(
          temperature: <String>['hot', 'iced'],
          sizes: <String>['small', 'medium', 'large'],
          sugarLevels: <String>['normal', 'less', 'no_sugar'],
          iceLevels: <String>['normal', 'less', 'no_ice'],
        ),
      );

      final useCase = GetProductDetailUseCase(_FakeProductRepository(product));
      final cartRepository = _FakeCartRepository();
      final addCartItemUseCase = AddCartItemUseCase(cartRepository);

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(
            productId: 'uuid',
            getProductDetailUseCase: useCase,
            addCartItemUseCase: addCartItemUseCase,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('COFFEE'), findsOneWidget);
      expect(find.text('Americano'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);

      expect(find.text('TEMPERATURE'), findsOneWidget);
      expect(find.text('SIZE SELECTION'), findsOneWidget);
      expect(find.text('SUGAR LEVELS'), findsOneWidget);
      expect(find.text('ICE LEVELS'), findsOneWidget);

      await tester.ensureVisible(find.text('Iced'));
      await tester.tap(find.text('Iced'));
      await tester.pumpAndSettle();

      expect(find.text('ICE LEVELS'), findsOneWidget);
    },
  );

  testWidgets(
    'Coffee product only shows attribute groups returned by the API',
    (tester) async {
      final product = _baseProduct(
        category: ProductCategory.coffee,
        attributes: const ProductAttributes(sizes: <String>['small', 'medium']),
      );
      final cartRepository = _FakeCartRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(
            productId: 'uuid',
            getProductDetailUseCase: GetProductDetailUseCase(
              _FakeProductRepository(product),
            ),
            addCartItemUseCase: AddCartItemUseCase(cartRepository),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SIZE SELECTION'), findsOneWidget);
      expect(find.text('TEMPERATURE'), findsNothing);
      expect(find.text('SUGAR LEVELS'), findsNothing);
      expect(find.text('ICE LEVELS'), findsNothing);

      await tester.ensureVisible(find.text('Add to Cart'));
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      expect(cartRepository.lastAttributes, <String, String>{'sizes': 'small'});
    },
  );

  testWidgets('Food product: shows portion/spicy and hides coffee attributes', (
    tester,
  ) async {
    final product = _baseProduct(
      category: ProductCategory.food,
      rating: 0,
      attributes: const ProductAttributes(
        portions: <String>['regular', 'large'],
        spicyLevels: <String>['no_spicy', 'mild'],
      ),
    );

    final useCase = GetProductDetailUseCase(_FakeProductRepository(product));
    final cartRepository = _FakeCartRepository();
    final addCartItemUseCase = AddCartItemUseCase(cartRepository);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(
          productId: 'uuid',
          getProductDetailUseCase: useCase,
          addCartItemUseCase: addCartItemUseCase,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MAKANAN'), findsOneWidget);

    expect(find.text('PORTION'), findsOneWidget);
    expect(find.text('SPICY LEVELS'), findsOneWidget);

    expect(find.text('TEMPERATURE'), findsNothing);
    expect(find.text('SIZE SELECTION'), findsNothing);
    expect(find.text('SUGAR LEVELS'), findsNothing);
  });

  testWidgets(
    'Snack product with portions only hides spicy options and omits them from cart',
    (tester) async {
      final product = _baseProduct(
        category: ProductCategory.snack,
        attributes: const ProductAttributes(
          portions: <String>['regular', 'large'],
        ),
      );
      final cartRepository = _FakeCartRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(
            productId: 'uuid',
            getProductDetailUseCase: GetProductDetailUseCase(
              _FakeProductRepository(product),
            ),
            addCartItemUseCase: AddCartItemUseCase(cartRepository),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PORTION'), findsOneWidget);
      expect(find.text('SPICY LEVELS'), findsNothing);
      expect(find.text('No Spicy'), findsNothing);

      await tester.ensureVisible(find.text('Add to Cart'));
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      expect(cartRepository.lastAttributes, <String, String>{
        'portions': 'regular',
      });
    },
  );

  testWidgets('Out of stock product cannot be added to cart', (tester) async {
    final product = _baseProduct(
      category: ProductCategory.coffee,
      status: ProductStatus.outOfStock,
      attributes: const ProductAttributes(
        temperature: <String>['hot'],
        sizes: <String>['small'],
        sugarLevels: <String>['normal'],
        iceLevels: <String>['normal'],
      ),
    );

    final useCase = GetProductDetailUseCase(_FakeProductRepository(product));
    final cartRepository = _FakeCartRepository();
    final addCartItemUseCase = AddCartItemUseCase(cartRepository);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(
          productId: 'uuid',
          getProductDetailUseCase: useCase,
          addCartItemUseCase: addCartItemUseCase,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Out of stock'), findsOneWidget);

    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();

    expect(cartRepository.addItemCallCount, 0);
    expect(find.text('Americano ditambahkan ke keranjang'), findsNothing);
  });

  testWidgets('Add to cart sends the selected food options', (tester) async {
    final product = _baseProduct(
      category: ProductCategory.food,
      attributes: const ProductAttributes(
        portions: <String>['regular', 'large'],
        spicyLevels: <String>['no_spicy', 'mild', 'medium', 'hot'],
      ),
    );
    final cartRepository = _FakeCartRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(
          productId: 'uuid',
          getProductDetailUseCase: GetProductDetailUseCase(
            _FakeProductRepository(product),
          ),
          addCartItemUseCase: AddCartItemUseCase(cartRepository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Large'));
    await tester.tap(find.text('Large'));
    await tester.tap(find.text('Hot'));
    await tester.ensureVisible(find.text('Add to Cart'));
    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();

    expect(cartRepository.lastAttributes, <String, String>{
      'portions': 'large',
      'spicy_levels': 'hot',
    });
  });
}
