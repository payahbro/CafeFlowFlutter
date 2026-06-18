import 'package:cafe/app/di/cart_module.dart';
import 'package:cafe/app/di/order_module.dart';
import 'package:cafe/app/di/payment_module.dart';
import 'package:cafe/features/auth/domain/entities/auth_session.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/presentation/pages/product_home_page.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

class _FakeProductRepository implements ProductRepository {
  @override
  Future<ProductListPage> getProducts(ProductQuery query) async {
    return ProductListPage(
      data: const <Product>[],
      nextCursor: null,
      prevCursor: null,
      limit: query.limit,
      hasNext: false,
      hasPrev: false,
    );
  }

  @override
  Future<Product> getProductDetail(String id) {
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

void main() {
  testWidgets(
    'opens the in-app restaurant map from the header location action',
    (tester) async {
      final repository = _FakeProductRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ProductHomePage(
            sessionController: SessionController(
              authRepository: _FakeAuthRepository(),
            ),
            cartModule: CartModule(),
            orderModule: OrderModule(),
            paymentModule: PaymentModule(),
            getProductsUseCase: GetProductsUseCase(repository),
            getProductDetailUseCase: GetProductDetailUseCase(repository),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Lokasi restoran'));
      await tester.pumpAndSettle();

      expect(find.text('CafeFlow Braga'), findsWidgets);
      expect(find.text('Sekitar Braga, Bandung'), findsOneWidget);
    },
  );
}
