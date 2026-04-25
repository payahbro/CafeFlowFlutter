import 'package:cafe/features/order/domain/repositories/order_repository.dart';

class CancelOrderUseCase {
  const CancelOrderUseCase(this._repository);

  final OrderRepository _repository;

  Future<void> call(String orderId) {
    return _repository.cancelOrder(orderId);
  }
}
