import 'package:cafe/features/cart/domain/entities/cart.dart';
import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';

class UpdateCartItemQuantityUseCase {
  const UpdateCartItemQuantityUseCase(this._repository);

  final CartRepository _repository;

  Future<Cart> call({required String itemId, required int quantity}) {
    return _repository.updateItemQuantity(itemId: itemId, quantity: quantity);
  }
}
