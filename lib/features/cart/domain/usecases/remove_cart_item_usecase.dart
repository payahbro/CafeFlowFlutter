import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';

class RemoveCartItemUseCase {
  const RemoveCartItemUseCase(this._repository);

  final CartRepository _repository;

  Future<void> call(String itemId) {
    return _repository.removeItem(itemId);
  }
}
