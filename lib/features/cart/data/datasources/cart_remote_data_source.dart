import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/cart/data/models/cart_models.dart';

abstract class CartRemoteDataSource {
  Future<CartModel> getMyCart();

  Future<CartModel> addItem({required String productId, required int quantity});

  Future<CartModel> updateItemQuantity({required String itemId, required int quantity});

  Future<void> removeItem(String itemId);

  Future<void> clearMyCart();
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  CartRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CartModel> getMyCart() async {
    final response = await _apiClient.get('/cart');
    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return CartModel.fromJson(data);
  }

  @override
  Future<CartModel> addItem({required String productId, required int quantity}) async {
    final response = await _apiClient.post(
      '/cart/items',
      body: <String, dynamic>{
        'product_id': productId,
        'quantity': quantity,
      },
    );
    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return CartModel.fromJson(data);
  }

  @override
  Future<CartModel> updateItemQuantity({required String itemId, required int quantity}) async {
    final response = await _apiClient.patch(
      '/cart/items/$itemId',
      body: <String, dynamic>{'quantity': quantity},
    );
    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return CartModel.fromJson(data);
  }

  @override
  Future<void> removeItem(String itemId) {
    return _apiClient.delete('/cart/items/$itemId');
  }

  @override
  Future<void> clearMyCart() {
    return _apiClient.delete('/cart/items');
  }
}
