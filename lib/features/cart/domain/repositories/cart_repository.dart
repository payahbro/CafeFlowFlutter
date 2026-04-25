import 'package:cafe/features/cart/domain/entities/cart.dart';

abstract class CartRepository {
  Future<Cart> getMyCart();

  Future<Cart> addItem({required String productId, required int quantity});

  Future<Cart> updateItemQuantity({required String itemId, required int quantity});

  Future<void> removeItem(String itemId);

  Future<void> clearMyCart();
}
