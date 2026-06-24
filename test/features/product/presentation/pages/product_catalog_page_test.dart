import 'package:cafe/features/cart/domain/entities/cart.dart';
import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';
import 'package:cafe/features/cart/domain/usecases/add_cart_item_usecase.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/presentation/pages/product_catalog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  @override
  Future<Product> createProduct(UpsertProductInput input) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProduct(String id) => throw UnimplementedError();

  @override
  Future<Product> getProductDetail(String id) => throw UnimplementedError();

  @override
  Future<ProductListPage> getProducts(ProductQuery query) =>
      throw UnimplementedError();

  @override
  Future<Product> restoreProduct(String id) => throw UnimplementedError();

  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) =>
      throw UnimplementedError();

  @override
  Future<Product> updateProductStatus(String id, String status) =>
      throw UnimplementedError();
}

class _FakeCartRepository implements CartRepository {
  @override
  Future<Cart> addItem({required String productId, required int quantity}) =>
      throw UnimplementedError();

  @override
  Future<void> clearMyCart() => throw UnimplementedError();

  @override
  Future<Cart> getMyCart() => throw UnimplementedError();

  @override
  Future<void> removeItem(String itemId) => throw UnimplementedError();

  @override
  Future<Cart> updateItemQuantity({
    required String itemId,
    required int quantity,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets('category filters use the correct label and spacing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final productRepository = _FakeProductRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ProductCatalogPage(
          getProductsUseCase: GetProductsUseCase(productRepository),
          getProductDetailUseCase: GetProductDetailUseCase(productRepository),
          addCartItemUseCase: AddCartItemUseCase(_FakeCartRepository()),
          mockProducts: const <Product>[],
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Snack'), findsOneWidget);
    expect(find.text('Snak'), findsNothing);

    final chips = find.byType(ChoiceChip);
    expect(chips, findsNWidgets(4));

    for (var index = 1; index < 4; index++) {
      final previousRect = tester.getRect(chips.at(index - 1));
      final currentRect = tester.getRect(chips.at(index));

      expect(currentRect.left - previousRect.right, 8);
    }
  });
}
