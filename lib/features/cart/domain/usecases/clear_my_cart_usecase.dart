import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';

class ClearMyCartUseCase {
  const ClearMyCartUseCase(this._repository);

  final CartRepository _repository;

  Future<void> call() {
    return _repository.clearMyCart();
  }
}
