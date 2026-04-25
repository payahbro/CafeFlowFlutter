import 'package:cafe/features/order/domain/entities/order.dart';
import 'package:cafe/features/order/domain/entities/order_checkout_input.dart';
import 'package:cafe/features/order/domain/repositories/order_repository.dart';

class CheckoutOrderUseCase {
  const CheckoutOrderUseCase(this._repository);

  final OrderRepository _repository;

  Future<Order> call(OrderCheckoutInput input) {
    return _repository.checkout(input);
  }
}
