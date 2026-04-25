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
  _FakeProductRepository(this._product);

  final Product _product;

  @override
  Future<Product> getProductDetail(String id) async {
    return _product;
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
  const _FakeCartRepository();

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
  Future<Cart> addItem({required String productId, required int quantity}) async {
    return _emptyCart;
  }

  @override
  Future<Cart> updateItemQuantity({required String itemId, required int quantity}) async {
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
  double rating = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return Product(
    id: 'uuid',
    name: 'Americano',
    description: 'Espresso dengan air panas',
    price: 25000,
    category: category,
    status: ProductStatus.available,
    imageUrl: 'https://invalid.example/image.png',
    rating: rating,
    totalSold: 0,
    attributes: attributes,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('Coffee product: shows coffee attributes and toggles Ice on iced',
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
    const addCartItemUseCase = AddCartItemUseCase(_FakeCartRepository());

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
    expect(find.text('AMERICANO'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);

    expect(find.text('TEMPERATURE'), findsOneWidget);
    expect(find.text('SIZE SELECTION'), findsOneWidget);
    expect(find.text('SUGAR LEVELS'), findsOneWidget);
    expect(find.text('ICE LEVELS'), findsOneWidget);

    await tester.ensureVisible(find.text('Iced'));
    await tester.tap(find.text('Iced'));
    await tester.pumpAndSettle();

    expect(find.text('ICE LEVELS'), findsOneWidget);
  });

  testWidgets('Food product: shows portion/spicy and hides coffee attributes',
      (tester) async {
    final product = _baseProduct(
      category: ProductCategory.food,
      rating: 0,
      attributes: const ProductAttributes(
        portions: <String>['regular', 'large'],
        spicyLevels: <String>['no_spicy', 'mild'],
      ),
    );

    final useCase = GetProductDetailUseCase(_FakeProductRepository(product));
    const addCartItemUseCase = AddCartItemUseCase(_FakeCartRepository());

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
}


