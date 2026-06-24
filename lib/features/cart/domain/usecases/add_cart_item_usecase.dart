import 'package:cafe/features/cart/domain/entities/cart.dart';
import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';

class AddCartItemUseCase {
  const AddCartItemUseCase(this._repository);

  final CartRepository _repository;

  Future<Cart> call({
    required String productId,
    required int quantity,
    required Map<String, String> attributes,
  }) {
    return _repository.addItem(
      productId: productId,
      quantity: quantity,
      attributes: attributes,
    );
  }
}
