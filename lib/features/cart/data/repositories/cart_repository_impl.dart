import 'package:cafe/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:cafe/features/cart/domain/entities/cart.dart';
import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._remoteDataSource);

  final CartRemoteDataSource _remoteDataSource;

  @override
  Future<Cart> getMyCart() async {
    final model = await _remoteDataSource.getMyCart();
    return model.toEntity();
  }

  @override
  Future<Cart> addItem({required String productId, required int quantity}) async {
    final model = await _remoteDataSource.addItem(
      productId: productId,
      quantity: quantity,
    );
    return model.toEntity();
  }

  @override
  Future<Cart> updateItemQuantity({required String itemId, required int quantity}) async {
    final model = await _remoteDataSource.updateItemQuantity(
      itemId: itemId,
      quantity: quantity,
    );
    return model.toEntity();
  }

  @override
  Future<void> removeItem(String itemId) {
    return _remoteDataSource.removeItem(itemId);
  }

  @override
  Future<void> clearMyCart() {
    return _remoteDataSource.clearMyCart();
  }
}
