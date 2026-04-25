import 'package:cafe/features/cart/domain/entities/cart.dart';
import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';

class GetMyCartUseCase {
  const GetMyCartUseCase(this._repository);

  final CartRepository _repository;

  Future<Cart> call() {
    return _repository.getMyCart();
  }
}
